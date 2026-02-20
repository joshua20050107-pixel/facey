import 'package:flutter/material.dart';

import '../widgets/top_header.dart';

class ActivityTabScreen extends StatefulWidget {
  const ActivityTabScreen({
    super.key,
    this.title = '今日のコンディション',
    this.subtitle = '今日のあなたの状態を観測します',
  });

  final String title;
  final String subtitle;

  @override
  State<ActivityTabScreen> createState() => _ActivityTabScreenState();
}

class _ActivityTabScreenState extends State<ActivityTabScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.93);
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildDisabledActionButton(String label, double scale) {
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
              color: const Color(0xFF8C35FF).withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextButton(
          onPressed: null,
          style: TextButton.styleFrom(
            disabledForegroundColor: Colors.white.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
          ),
          child: Text(
            label,
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

  Widget _buildCard({
    required String imagePath,
    required String title,
    required String buttonLabel,
    required double imageWidth,
    required double scale,
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
          left: 24,
          right: 24,
          bottom: 120,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontSize: 29,
              fontWeight: FontWeight.w900,
              fontFamily: 'Hiragino Kaku Gothic ProN',
            ),
          ),
        ),
        Positioned(
          left: imageWidth * 0.16,
          right: imageWidth * 0.16,
          bottom: imageWidth * 0.09,
          child: _buildDisabledActionButton(buttonLabel, scale),
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
        final double imageWidth = (430 * scale).clamp(268.0, 448.0);
        final double cardHeight = (imageWidth / (1045 / 1629)) * 0.95;
        final double pageGap = (1.4 * scale).clamp(1.0, 2.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              TopHeader(
                title: widget.title,
                titleStyle: TextStyle(
                  fontSize: 25,
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
                  offset: const Offset(0, 4),
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
                                  imagePath: 'assets/images/oaks.png',
                                  title: 'あなたの状態を分析',
                                  buttonLabel: 'コンディションを見る',
                                  imageWidth: imageWidth,
                                  scale: scale,
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
                                child: _buildCard(
                                  imagePath: 'assets/images/plaos.png',
                                  title: '今日の改善ポイント',
                                  buttonLabel: '提案を見る',
                                  imageWidth: imageWidth,
                                  scale: scale,
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
