import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'condition_analysis_result_screen.dart';
import '../routes/no_swipe_back_material_page_route.dart';
import 'scan_next_screen.dart';
import '../widgets/top_header.dart';
import '../widgets/yomu_gender_two_choice.dart';

class ActivityTabScreen extends StatefulWidget {
  const ActivityTabScreen({
    super.key,
    this.title = 'Condition',
    this.subtitle = '現在のあなたの状態を観測します',
    required this.selectedGender,
  });

  final String title;
  final String subtitle;
  final YomuGender selectedGender;

  @override
  State<ActivityTabScreen> createState() => _ActivityTabScreenState();
}

class _ActivityTabScreenState extends State<ActivityTabScreen> {
  static const String _prefsBoxName = 'app_prefs';
  static const String _conditionLatestResultFrontImageKey =
      'condition_latest_result_front_image';
  final PageController _pageController = PageController(viewportFraction: 0.93);
  int _currentPageIndex = 0;
  String? _latestConditionFrontImagePath;

  @override
  void initState() {
    super.initState();
    _loadLatestConditionResult();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadLatestConditionResult() {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    final String? frontPath = box.get(_conditionLatestResultFrontImageKey);
    if (!mounted) return;
    setState(() {
      _latestConditionFrontImagePath =
          frontPath != null &&
              frontPath.isNotEmpty &&
              File(frontPath).existsSync()
          ? frontPath
          : null;
    });
  }

  Route<void> _buildResultScreenRoute({required String imagePath}) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 420),
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return ConditionAnalysisResultScreen(imagePath: imagePath);
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

  Widget _buildActionButton(
    String label,
    double scale, {
    required VoidCallback? onTap,
  }) {
    final double buttonHeight = (76 * scale).clamp(60.0, 80.0);
    final double buttonRadius = (46 * scale).clamp(36.0, 50.0);
    final bool isScanLabel = label == 'スキャンする';
    final double textSize = isScanLabel
        ? (21 * scale).clamp(17.0, 23.0)
        : (25 * scale).clamp(21.0, 27.0);
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
              color: const Color(0xFF8C35FF).withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: textSize,
              fontFamily: isScanLabel ? 'Hiragino Kaku Gothic ProN' : null,
              fontWeight: isScanLabel ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String imagePath,
    required String title,
    required String buttonLabel,
    required double imageWidth,
    required double scale,
    required VoidCallback? onButtonTap,
    bool useHomeTitleStyle = false,
    bool applyDarkOverlay = false,
  }) {
    return Stack(
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(imagePath, fit: BoxFit.cover),
                if (applyDarkOverlay)
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
                              alignment: Alignment.bottomCenter,
                            ),
                          ),
                          const Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              height: 18,
                              width: double.infinity,
                              child: ColoredBox(color: Colors.black),
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
        Positioned(
          left: useHomeTitleStyle ? imageWidth * 0.002 : 24,
          right: useHomeTitleStyle ? imageWidth * 0.002 : 24,
          bottom: useHomeTitleStyle ? imageWidth * 0.34 : 120,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: useHomeTitleStyle
                ? const TextStyle(
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
                  )
                : const TextStyle(
                    color: Color(0xF2FFFFFF),
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Hiragino Kaku Gothic ProN',
                  ),
          ),
        ),
        Positioned(
          left: imageWidth * 0.055,
          right: imageWidth * 0.055,
          bottom: imageWidth * 0.055,
          child: _buildActionButton(buttonLabel, scale, onTap: onButtonTap),
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
        final double imageWidth = (428 * scale).clamp(268.0, 446.0);
        final double cardHeight = (imageWidth / (1045 / 1629)) * 0.94;
        final double pageGap = (1.4 * scale).clamp(1.0, 2.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              TopHeader(
                title: widget.title,
                titleStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Transform.translate(
                offset: const Offset(3, -4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.subtitle,
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
                      child: PageView(
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
                            child: Center(
                              child: SizedBox(
                                width: imageWidth,
                                height: cardHeight,
                                child: _buildCard(
                                  imagePath:
                                      widget.selectedGender == YomuGender.female
                                      ? 'assets/images/plaos.png'
                                      : 'assets/images/pamiko.png',
                                  title: '現在のあなたの\nコンディションを分析',
                                  buttonLabel: 'スキャンする',
                                  imageWidth: imageWidth,
                                  scale: scale,
                                  useHomeTitleStyle: true,
                                  onButtonTap: () async {
                                    await Navigator.of(context).push(
                                      NoSwipeBackMaterialPageRoute<void>(
                                        builder: (_) => ScanNextScreen(
                                          selectedGender: widget.selectedGender,
                                          goToSideProfileStepOnContinue: false,
                                          isConditionFlow: true,
                                        ),
                                      ),
                                    );
                                    _loadLatestConditionResult();
                                  },
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: pageGap),
                            child: Center(
                              child: SizedBox(
                                width: imageWidth,
                                height: cardHeight,
                                child: _latestConditionFrontImagePath == null
                                    ? const Center(
                                        child: Text(
                                          '分析結果が表示されます',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFAEB7C8),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : _buildCard(
                                        imagePath:
                                            _latestConditionFrontImagePath!,
                                        title: '分析結果',
                                        buttonLabel: '結果を見る',
                                        imageWidth: imageWidth,
                                        scale: scale,
                                        applyDarkOverlay: true,
                                        onButtonTap: () {
                                          final String? path =
                                              _latestConditionFrontImagePath;
                                          if (path == null || path.isEmpty) {
                                            return;
                                          }
                                          Navigator.of(context).push(
                                            _buildResultScreenRoute(
                                              imagePath: path,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
