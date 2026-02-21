import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../routes/no_swipe_back_material_page_route.dart';
import 'face_analysis_result_screen.dart';
import 'scan_next_screen.dart';
import '../widgets/top_header.dart';
import '../widgets/yomu_gender_two_choice.dart';

class ScanTabScreen extends StatefulWidget {
  const ScanTabScreen({super.key, required this.selectedGender});

  final YomuGender selectedGender;

  @override
  State<ScanTabScreen> createState() => _ScanTabScreenState();
}

class _ScanTabScreenState extends State<ScanTabScreen> {
  static const String _prefsBoxName = 'app_prefs';
  static const String _latestResultFrontImageKey = 'latest_result_front_image';
  static const String _latestResultSideImageKey = 'latest_result_side_image';
  final PageController _pageController = PageController(viewportFraction: 0.93);
  int _currentPageIndex = 0;
  String? _latestResultFrontImagePath;
  String? _latestResultSideImagePath;

  @override
  void initState() {
    super.initState();
    _loadLatestResult();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadLatestResult() {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    if (!mounted) return;
    setState(() {
      _latestResultFrontImagePath = box.get(_latestResultFrontImageKey);
      _latestResultSideImagePath = box.get(_latestResultSideImageKey);
    });
  }

  Route<void> _buildResultScreenRoute({
    required String imagePath,
    String? sideImagePath,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (BuildContext context, _, __) {
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
    final double buttonHeight = (58 * scale).clamp(44.0, 62.0);
    final double buttonRadius = (38 * scale).clamp(28.0, 40.0);
    final double textSize = (22 * scale).clamp(18.0, 24.0);

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
            colors: [Color(0xFF5B22FF), Color(0xFFB61DFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8C35FF).withValues(alpha: 0.5),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextButton(
          onPressed: () async {
            await Navigator.of(context).push(
              NoSwipeBackMaterialPageRoute<void>(
                builder: (_) =>
                    ScanNextScreen(selectedGender: widget.selectedGender),
              ),
            );
            _loadLatestResult();
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
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenLatestResultButton(double scale) {
    final double buttonHeight = (58 * scale).clamp(44.0, 62.0);
    final double buttonRadius = (38 * scale).clamp(28.0, 40.0);
    final double textSize = (22 * scale).clamp(18.0, 24.0);
    final String? path = _latestResultFrontImagePath;
    final bool enabled =
        path != null && path.isNotEmpty && File(path).existsSync();

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(buttonRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: enabled
                ? const [Color(0xFF5B22FF), Color(0xFFB61DFF)]
                : const [Color(0xFF444A57), Color(0xFF383D47)],
          ),
          boxShadow: [
            BoxShadow(
              color: (enabled ? const Color(0xFF8C35FF) : Colors.black)
                  .withValues(alpha: enabled ? 0.5 : 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextButton(
          onPressed: enabled
              ? () {
                  Navigator.of(context).push(
                    _buildResultScreenRoute(
                      imagePath: path,
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
            enabled ? '結果を見る' : '結果がありません',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlidingPages(double scale) {
    final double imageWidth = (430 * scale).clamp(268.0, 448.0);

    final String imagePath = widget.selectedGender == YomuGender.female
        ? 'assets/images/plaos.png'
        : 'assets/images/pamiko.png';
    final double firstPageImageHeight = (imageWidth / (1045 / 1629)) * 0.95;
    final String? latestFrontPath = _latestResultFrontImagePath;
    final String? thumbnailPath =
        latestFrontPath != null &&
            latestFrontPath.isNotEmpty &&
            File(latestFrontPath).existsSync()
        ? latestFrontPath
        : null;
    final bool hasLatestResult =
        thumbnailPath != null && thumbnailPath.isNotEmpty;
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
        if (index == 1) {
          _loadLatestResult();
        }
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
                    left: imageWidth * 0.06,
                    right: imageWidth * 0.06,
                    bottom: imageWidth * 0.28,
                    child: const Text(
                      'あなたの顔を分析して\n変化を追跡',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xF2FFFFFF),
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Hiragino Kaku Gothic ProN',
                        letterSpacing: 0.0,
                        shadows: <Shadow>[
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: imageWidth * 0.16,
                    right: imageWidth * 0.16,
                    bottom: imageWidth * 0.09,
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
                                  const ColoredBox(color: Color(0x66000000)),
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
                          left: imageWidth * 0.16,
                          right: imageWidth * 0.16,
                          bottom: imageWidth * 0.09,
                          child: _buildOpenLatestResultButton(scale),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: imageWidth * 0.36,
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
                  fontSize: 25,
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
                  offset: const Offset(0, 4),
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
                offset: const Offset(0, 8),
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
