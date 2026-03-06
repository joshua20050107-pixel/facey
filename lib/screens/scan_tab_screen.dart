import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../routes/scan_flow_material_page_route.dart';
import '../services/facey_api_service.dart';
import '../services/scan_flow_haptics.dart';
import 'face_analysis_result_screen.dart';
import 'scan_next_screen.dart';
import '../widgets/top_header.dart';
import '../widgets/yomu_gender_two_choice.dart';

class ScanTabScreen extends StatefulWidget {
  const ScanTabScreen({
    super.key,
    required this.selectedGender,
    this.resetPageSignal = 0,
  });

  final YomuGender selectedGender;
  final int resetPageSignal;

  @override
  State<ScanTabScreen> createState() => _ScanTabScreenState();
}

class _ScanTabScreenState extends State<ScanTabScreen> {
  static const String _prefsBoxName = 'app_prefs';
  static const String _latestResultFrontImageKey = 'latest_result_front_image';
  static const String _latestResultSideImageKey = 'latest_result_side_image';
  static const String _resultFrontImageHistoryKey =
      'result_front_image_history';
  static const String _resultFrontImageHistoryMetaKey =
      'result_front_image_history_meta';
  static const String _pendingFaceAnalysisUntilMsKey =
      'pending_face_analysis_until_ms';
  static const String _pendingFaceAnalysisStartedAtMsKey =
      'pending_face_analysis_started_at_ms';
  static const String _homeScanTargetPageKey = 'home_scan_target_page';
  static const String _homeScanTargetAppliedAckKey =
      'home_scan_target_applied_ack';
  static const int _pendingFaceAnalysisVisualDurationMs = 18000;
  final PageController _pageController = PageController(viewportFraction: 0.93);
  int _currentPageIndex = 0;
  String? _latestResultFrontImagePath;
  String? _latestResultSideImagePath;
  bool _isPendingFaceAnalysis = false;
  double _pendingFaceAnalysisProgress = 0;
  Timer? _analysisProgressTimer;
  StreamSubscription<BoxEvent>? _prefsSubscription;

  @override
  void initState() {
    super.initState();
    _loadLatestResult();
    unawaited(_prepareApi());
    _prefsSubscription = Hive.box<String>(_prefsBoxName).watch().listen((
      BoxEvent event,
    ) {
      final Object? key = event.key;
      if (key == null) {
        _loadLatestResult();
        return;
      }
      if (key == _latestResultFrontImageKey ||
          key == _latestResultSideImageKey ||
          key == _pendingFaceAnalysisUntilMsKey) {
        _loadLatestResult();
        return;
      }
      if (key == _homeScanTargetPageKey) {
        final Box<String> box = Hive.box<String>(_prefsBoxName);
        final String raw = box.get(_homeScanTargetPageKey) ?? '';
        if (raw.isEmpty) return;
        final List<String> parts = raw.split(':');
        final int? target = int.tryParse(parts.first);
        if (target == null) return;
        final String ackToken = parts.length > 1 ? parts[1] : '';
        if (_pageController.hasClients) {
          _pageController.jumpToPage(target);
        }
        if (mounted) {
          setState(() {
            _currentPageIndex = target;
          });
        }
        if (ackToken.isNotEmpty) {
          unawaited(box.put(_homeScanTargetAppliedAckKey, ackToken));
        }
        unawaited(box.delete(_homeScanTargetPageKey));
      }
    });
  }

  @override
  void didUpdateWidget(covariant ScanTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetPageSignal != widget.resetPageSignal) {
      _resetToFirstPage();
    }
  }

  @override
  void dispose() {
    _prefsSubscription?.cancel();
    _analysisProgressTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _loadLatestResult() {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    _analysisProgressTimer?.cancel();
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final String pendingStatus = (box.get(_pendingFaceAnalysisUntilMsKey) ?? '')
        .trim();
    final bool isPending = pendingStatus == 'running';
    if (isPending) {
      final int startedAtMs =
          int.tryParse(box.get(_pendingFaceAnalysisStartedAtMsKey) ?? '') ??
          nowMs;
      _pendingFaceAnalysisProgress = _progressFromElapsedMs(
        nowMs - startedAtMs,
      );
      _analysisProgressTimer = Timer.periodic(
        const Duration(milliseconds: 90),
        (_) {
          if (!mounted) return;
          final Box<String> prefs = Hive.box<String>(_prefsBoxName);
          final String status =
              (prefs.get(_pendingFaceAnalysisUntilMsKey) ?? '').trim();
          if (status != 'running') {
            _analysisProgressTimer?.cancel();
            _loadLatestResult();
            return;
          }
          final int now = DateTime.now().millisecondsSinceEpoch;
          final int started =
              int.tryParse(
                prefs.get(_pendingFaceAnalysisStartedAtMsKey) ?? '',
              ) ??
              now;
          setState(() {
            _pendingFaceAnalysisProgress = _progressFromElapsedMs(
              now - started,
            );
          });
        },
      );
    } else if (pendingStatus.isNotEmpty) {
      unawaited(box.delete(_pendingFaceAnalysisUntilMsKey));
      unawaited(box.delete(_pendingFaceAnalysisStartedAtMsKey));
      _pendingFaceAnalysisProgress = 0;
    }
    final String? rawFrontPath = box.get(_latestResultFrontImageKey);
    final String? latestFrontPath =
        rawFrontPath != null &&
            rawFrontPath.isNotEmpty &&
            File(rawFrontPath).existsSync()
        ? rawFrontPath
        : _resolveFallbackFrontImagePath(box);
    if (latestFrontPath != null &&
        latestFrontPath.isNotEmpty &&
        latestFrontPath != rawFrontPath) {
      unawaited(box.put(_latestResultFrontImageKey, latestFrontPath));
    }
    final String? rawSidePath = box.get(_latestResultSideImageKey);
    final String? latestSidePath =
        rawSidePath != null &&
            rawSidePath.isNotEmpty &&
            File(rawSidePath).existsSync()
        ? rawSidePath
        : null;
    if (rawSidePath != null &&
        rawSidePath.isNotEmpty &&
        latestSidePath == null) {
      unawaited(box.delete(_latestResultSideImageKey));
    }
    if (!mounted) return;
    setState(() {
      _latestResultFrontImagePath = latestFrontPath;
      _latestResultSideImagePath = latestSidePath;
      _isPendingFaceAnalysis = isPending;
      if (!isPending) {
        _pendingFaceAnalysisProgress = 0;
      }
    });
  }

  Future<void> _prepareApi() async {
    try {
      await FaceyApiService.warmupForStartup();
    } catch (_) {
      // Warmup is best-effort and stays in the background.
    }
  }

  double _progressFromElapsedMs(int elapsedMs) {
    final double raw = elapsedMs / _pendingFaceAnalysisVisualDurationMs;
    return raw.clamp(0.0, 0.95);
  }

  void _resetToFirstPage() {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    if (!mounted) return;
    setState(() {
      _currentPageIndex = 0;
    });
  }

  String? _resolveFallbackFrontImagePath(Box<String> box) {
    final String metaRaw = box.get(_resultFrontImageHistoryMetaKey) ?? '[]';
    try {
      final List<dynamic> decoded = jsonDecode(metaRaw) as List<dynamic>;
      for (final dynamic item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final String path = (item['path'] ?? '').toString();
        if (path.isEmpty) continue;
        if (File(path).existsSync()) return path;
      }
    } catch (_) {
      // Fallback to simple history.
    }

    final String historyRaw = box.get(_resultFrontImageHistoryKey) ?? '';
    for (final String path in historyRaw.split('\n')) {
      if (path.isEmpty) continue;
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  Route<void> _buildStartScanRoute() {
    return ScanFlowMaterialPageRoute<void>(
      builder: (_) => ScanNextScreen(selectedGender: widget.selectedGender),
    );
  }

  Route<void> _buildResultScreenRoute({
    required String imagePath,
    String? sideImagePath,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 420),
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return FaceAnalysisResultScreen(
              imagePath: imagePath,
              sideImagePath: sideImagePath,
            );
          },
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            if (animation.status == AnimationStatus.reverse) {
              final Animation<Offset> reverseOffsetAnimation =
                  Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(0, 1),
                  ).animate(
                    CurvedAnimation(
                      parent: ReverseAnimation(animation),
                      curve: Curves.easeInOutCubic,
                    ),
                  );
              return SlideTransition(
                position: reverseOffsetAnimation,
                child: child,
              );
            }

            final Animation<Offset> forwardOffsetAnimation =
                Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  ),
                );
            return SlideTransition(
              position: forwardOffsetAnimation,
              child: child,
            );
          },
    );
  }

  String _todayDateText() {
    final DateTime now = DateTime.now();
    return '${now.month}月${now.day}日';
  }

  Widget _buildStartAnalysisButton(double scale) {
    final double buttonHeight = (76 * scale).clamp(60.0, 80.0);
    final double buttonRadius = (46 * scale).clamp(36.0, 50.0);
    final double textSize = (21 * scale).clamp(17.0, 23.0);

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(buttonRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6D28D9).withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextButton(
          onPressed: () async {
            ScanFlowHaptics.primary();
            await Navigator.of(context).push(_buildStartScanRoute());
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.25),
            splashFactory: InkRipple.splashFactory,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
          ),
          child: Text(
            'スキャンする',
            style: TextStyle(
              fontSize: textSize,
              fontFamily: 'Hiragino Kaku Gothic ProN',
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenLatestResultButton(
    double scale, {
    required bool enabled,
    required String label,
  }) {
    final double buttonHeight = (76 * scale).clamp(60.0, 80.0);
    final double buttonRadius = (46 * scale).clamp(36.0, 50.0);
    final double textSize = (21 * scale).clamp(17.0, 23.0);
    final String? path = _latestResultFrontImagePath;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(buttonRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6D28D9).withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextButton(
          onPressed: enabled
              ? () {
                  ScanFlowHaptics.primary();
                  Navigator.of(context).push(
                    _buildResultScreenRoute(
                      imagePath: path!,
                      sideImagePath: _latestResultSideImagePath,
                    ),
                  );
                }
              : null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
            overlayColor: Colors.white.withValues(alpha: 0.25),
            splashFactory: InkRipple.splashFactory,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: textSize,
              fontFamily: 'Hiragino Kaku Gothic ProN',
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlidingPages(double scale) {
    final double imageWidth = (428 * scale).clamp(268.0, 446.0);

    final String imagePath = widget.selectedGender == YomuGender.female
        ? 'assets/images/kklaso.png'
        : 'assets/images/pamiko.png';
    final double firstPageImageHeight = (imageWidth / (1045 / 1629)) * 0.94;
    final String? latestFrontPath = _latestResultFrontImagePath;
    final String? thumbnailPath =
        latestFrontPath != null &&
            latestFrontPath.isNotEmpty &&
            File(latestFrontPath).existsSync()
        ? latestFrontPath
        : null;
    final bool hasLatestResult =
        thumbnailPath != null && thumbnailPath.isNotEmpty;
    final bool resultButtonEnabled = hasLatestResult && !_isPendingFaceAnalysis;
    final String resultButtonLabel = hasLatestResult ? '結果を見る' : '結果がありません';
    final double pageGap = (1.4 * scale).clamp(1.0, 2.0);
    return PageView(
      controller: _pageController,
      padEnds: true,
      clipBehavior: Clip.none,
      physics: const _FastSnapPagePhysics(),
      onPageChanged: (int index) {
        setState(() {
          _currentPageIndex = index;
        });
      },
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pageGap),
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: imageWidth,
              height: firstPageImageHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(37),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.12),
                          blurRadius: 2.2,
                          spreadRadius: -0.45,
                          offset: const Offset(0, -1),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.07),
                          blurRadius: 1.2,
                          spreadRadius: -0.7,
                          offset: const Offset(0, -2),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.26),
                          blurRadius: 2.8,
                          spreadRadius: -0.08,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(37),
                      child: SizedBox(
                        width: imageWidth,
                        height: firstPageImageHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(imagePath, fit: BoxFit.cover),
                            IgnorePointer(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: 0.28,
                                  widthFactor: 1,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Transform.translate(
                                        offset: const Offset(0, -17),
                                        child: Image.asset(
                                          'assets/images/ppak.png',
                                          fit: BoxFit.cover,
                                          alignment: Alignment.bottomCenter,
                                        ),
                                      ),
                                      const Align(
                                        alignment: Alignment.bottomCenter,
                                        child: SizedBox(
                                          height: 18,
                                          width: double.infinity,
                                          child: ColoredBox(
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: imageWidth * 0.002,
                    right: imageWidth * 0.002,
                    bottom: imageWidth * 0.34,
                    child: const Text(
                      'あなたの魅力を\n分析して変化を追跡',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xF2FFFFFF),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Hiragino Kaku Gothic ProN',
                        letterSpacing: 0.0,
                        shadows: <Shadow>[
                          Shadow(
                            color: Color(0xAA000000),
                            blurRadius: 14,
                            offset: Offset(0, 3),
                          ),
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: imageWidth * 0.055,
                    right: imageWidth * 0.055,
                    bottom: imageWidth * 0.055,
                    child: _buildStartAnalysisButton(scale),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pageGap),
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: imageWidth,
              child: hasLatestResult
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(37),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.12),
                                blurRadius: 2.2,
                                spreadRadius: -0.45,
                                offset: const Offset(0, -1),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.07),
                                blurRadius: 1.2,
                                spreadRadius: -0.7,
                                offset: const Offset(0, -2),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.26),
                                blurRadius: 2.8,
                                spreadRadius: -0.08,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(37),
                            child: SizedBox(
                              width: imageWidth,
                              height: firstPageImageHeight,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(thumbnailPath),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    filterQuality: FilterQuality.high,
                                  ),
                                  ColoredBox(
                                    color: _isPendingFaceAnalysis
                                        ? const Color(0xA6000000)
                                        : const Color(0x66000000),
                                  ),
                                  IgnorePointer(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: FractionallySizedBox(
                                        heightFactor: 0.28,
                                        widthFactor: 1,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Transform.translate(
                                              offset: const Offset(0, -17),
                                              child: Image.asset(
                                                'assets/images/ppak.png',
                                                fit: BoxFit.cover,
                                                alignment:
                                                    Alignment.bottomCenter,
                                              ),
                                            ),
                                            const Align(
                                              alignment: Alignment.bottomCenter,
                                              child: SizedBox(
                                                height: 17,
                                                width: double.infinity,
                                                child: ColoredBox(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: imageWidth * 0.055,
                          right: imageWidth * 0.055,
                          bottom: imageWidth * 0.055,
                          child: _buildOpenLatestResultButton(
                            scale,
                            enabled: resultButtonEnabled,
                            label: resultButtonLabel,
                          ),
                        ),
                        if (!_isPendingFaceAnalysis)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: imageWidth * 0.34,
                            child: Text(
                              _todayDateText(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xEBFFFFFF),
                                fontSize: 37,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Hiragino Kaku Gothic ProN',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        if (_isPendingFaceAnalysis)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Center(
                                child: SizedBox(
                                  width: 112,
                                  height: 112,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 96,
                                        height: 96,
                                        child: CircularProgressIndicator(
                                          value: _pendingFaceAnalysisProgress,
                                          strokeWidth: 6,
                                          strokeCap: StrokeCap.round,
                                          color: Colors.white,
                                          backgroundColor: Color(0x3DFFFFFF),
                                        ),
                                      ),
                                      Text(
                                        '${(_pendingFaceAnalysisProgress * 100).round()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          height: 1.0,
                                          fontWeight: FontWeight.w900,
                                          fontFamily:
                                              'Hiragino Kaku Gothic ProN',
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : SizedBox(
                      height: firstPageImageHeight,
                      child: const Center(
                        child: Text(
                          '分析結果が表示されます',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFAEB7C8),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(2, (int index) {
        final bool isActive = _currentPageIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isActive ? 22 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double widthScale = (constraints.maxWidth / 430).clamp(0.82, 1.0);
        final double heightScale = (constraints.maxHeight / 860).clamp(
          0.74,
          1.0,
        );
        final double scale = widthScale < heightScale
            ? widthScale
            : heightScale;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              const TopHeader(
                title: 'Home',
                titleStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Transform.translate(
                offset: const Offset(3, -4),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'あなたの魅力と伸ばし方を分析',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB9C0CF),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -4),
                  child: OverflowBox(
                    alignment: Alignment.center,
                    minWidth: 0,
                    maxWidth: constraints.maxWidth,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: _buildSlidingPages(scale),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Transform.translate(
                offset: const Offset(0, -4),
                child: _buildPageIndicator(),
              ),
              const SizedBox(height: 23),
            ],
          ),
        );
      },
    );
  }
}

class _FastSnapPagePhysics extends PageScrollPhysics {
  const _FastSnapPagePhysics({super.parent});

  @override
  _FastSnapPagePhysics applyTo(ScrollPhysics? ancestor) {
    return _FastSnapPagePhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingDistance => 6.0;

  @override
  double get dragStartDistanceMotionThreshold => 1.0;

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 0.7, stiffness: 380.0, damping: 34.0);
}
