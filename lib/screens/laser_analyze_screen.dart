import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'condition_analysis_result_screen.dart';
import 'face_analysis_result_screen.dart';

class LaserAnalyzeSpec {
  const LaserAnalyzeSpec({
    this.laserDuration = const Duration(milliseconds: 1650),
    this.analysisDuration = const Duration(milliseconds: 2800),
    this.laserWidth = 20.0,
  });

  final Duration laserDuration;
  final Duration analysisDuration;
  final double laserWidth;
}

class LaserAnalyzeShell extends StatefulWidget {
  const LaserAnalyzeShell({
    super.key,
    required this.imagePath,
    this.sideImagePath,
    this.isConditionFlow = false,
    this.spec = const LaserAnalyzeSpec(),
  });

  final String imagePath;
  final String? sideImagePath;
  final bool isConditionFlow;
  final LaserAnalyzeSpec spec;

  @override
  State<LaserAnalyzeShell> createState() => _LaserAnalyzeShellState();
}

class _LaserAnalyzeShellState extends State<LaserAnalyzeShell>
    with TickerProviderStateMixin {
  static const String _prefsBoxName = 'app_prefs';
  static const String _latestResultFrontImageKey = 'latest_result_front_image';
  static const String _latestResultSideImageKey = 'latest_result_side_image';
  static const String _conditionLatestResultFrontImageKey =
      'condition_latest_result_front_image';
  static const String _conditionLatestResultSideImageKey =
      'condition_latest_result_side_image';
  late final AnimationController _laserController;
  late final Animation<double> _laserProgress;
  late final AnimationController _resultController;
  late final Animation<double> _resultAnim;
  bool _showLaser = true;
  bool _didNavigate = false;
  bool _hasReversed = false;

  Future<String> _persistResultImage(
    String sourcePath, {
    required String prefix,
  }) async {
    final File source = File(sourcePath);
    if (!source.existsSync()) return sourcePath;
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory imageDir = Directory('${appDir.path}/analysis_results');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    final int dotIndex = sourcePath.lastIndexOf('.');
    final String ext = dotIndex >= 0
        ? sourcePath.substring(dotIndex).toLowerCase()
        : '.jpg';
    final String targetPath =
        '${imageDir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
    await source.copy(targetPath);
    return targetPath;
  }

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: widget.spec.laserDuration,
    );
    _laserProgress = CurvedAnimation(
      parent: _laserController,
      curve: Curves.easeInOut,
    );
    _laserController.addStatusListener((AnimationStatus status) {
      if (!_showLaser) return;
      if (status == AnimationStatus.completed) {
        if (!_hasReversed) {
          _hasReversed = true;
          _laserController.reverse();
        }
      } else if (status == AnimationStatus.dismissed) {
        if (_hasReversed) {
          _completeAnalyze();
        }
      }
    });
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _resultAnim = CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _tryStartLaser());
  }

  void _tryStartLaser() {
    if (!mounted) return;
    _laserController.forward();
  }

  Future<void> _completeAnalyze() async {
    if (!mounted || _didNavigate) return;
    final NavigatorState navigator = Navigator.of(context);
    _laserController.stop();
    setState(() {
      _showLaser = false;
    });
    await _resultController.forward();
    if (!mounted || _didNavigate) return;
    final String persistentFrontPath = await _persistResultImage(
      widget.imagePath,
      prefix: widget.isConditionFlow ? 'condition_front' : 'face_front',
    );
    final String? persistentSidePath = widget.sideImagePath != null
        ? await _persistResultImage(
            widget.sideImagePath!,
            prefix: widget.isConditionFlow ? 'condition_side' : 'face_side',
          )
        : null;
    final Box<String> prefs = Hive.box<String>(_prefsBoxName);
    final String frontKey = widget.isConditionFlow
        ? _conditionLatestResultFrontImageKey
        : _latestResultFrontImageKey;
    final String sideKey = widget.isConditionFlow
        ? _conditionLatestResultSideImageKey
        : _latestResultSideImageKey;
    await prefs.put(frontKey, persistentFrontPath);
    if (persistentSidePath != null) {
      await prefs.put(sideKey, persistentSidePath);
    } else {
      await prefs.delete(sideKey);
    }
    _didNavigate = true;
    navigator.pushAndRemoveUntil(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              if (widget.isConditionFlow) {
                return ConditionAnalysisResultScreen(
                  imagePath: persistentFrontPath,
                );
              }
              return FaceAnalysisResultScreen(
                imagePath: persistentFrontPath,
                sideImagePath: persistentSidePath,
                persistSummary: true,
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
                        curve: Curves.easeOutCubic,
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
                      curve: Curves.easeOutCubic,
                    ),
                  );
              return SlideTransition(
                position: forwardOffsetAnimation,
                child: child,
              );
            },
      ),
      (Route<dynamic> route) => route.isFirst,
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/images/keke.png',
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF042448),
                    Color(0xFF021A35),
                    Color(0xFF000D20),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1.05),
                  radius: 1.12,
                  colors: [
                    Color(0x802766AA),
                    Color(0x3323588A),
                    Color(0x00071B36),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xD9001024),
                    Color(0x00001024),
                    Color(0xD9001024),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000817),
                    Color(0x80000713),
                    Color(0xE6000610),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double frameWidth = (constraints.maxWidth * 0.84).clamp(
                  260.0,
                  370.0,
                );
                final double frameHeight = (constraints.maxHeight * 0.64).clamp(
                  390.0,
                  560.0,
                );
                return Align(
                  alignment: const Alignment(0, -0.75),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_laserProgress, _resultAnim]),
                    builder: (BuildContext context, _) {
                      final double scale = 1 - (_resultAnim.value * 0.02);
                      return Transform.scale(
                        scale: scale,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: frameWidth,
                            height: frameHeight,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(widget.imagePath),
                                  fit: BoxFit.cover,
                                ),
                                CustomPaint(
                                  painter: YomuLaserPainter(
                                    progress: _laserProgress.value,
                                    showLaser: _showLaser,
                                    laserWidth: widget.spec.laserWidth,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class YomuLaserPainter extends CustomPainter {
  const YomuLaserPainter({
    required this.progress,
    required this.showLaser,
    required this.laserWidth,
  });

  final double progress;
  final bool showLaser;
  final double laserWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (!showLaser) return;
    final double x = progress * size.width;
    final Rect rect = Rect.fromLTWH(
      x - laserWidth / 2,
      0,
      laserWidth,
      size.height,
    );
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x00FFFFFF),
          Color(0x66FFFFFF),
          Color(0xDDFFFFFF),
          Color(0x66FFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant YomuLaserPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.showLaser != showLaser ||
        oldDelegate.laserWidth != laserWidth;
  }
}
