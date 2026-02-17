import 'package:flutter/material.dart';

void main() {
  runApp(const FaceyApp());
}

class FaceyApp extends StatelessWidget {
  const FaceyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF060911),
        fontFamily: 'SF Pro Display',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedBottomIndex = 0;
  int _currentPageIndex = 0;

  static const List<IconData> _bottomIcons = <IconData>[
    Icons.crop_free_rounded,
    Icons.event_available,
    Icons.bar_chart_rounded,
    Icons.mode_comment_rounded,
    Icons.more_horiz_rounded,
  ];

  static const List<String> _bottomLabels = <String>[
    'scan',
    'activity',
    'growth',
    'daily',
    'coach',
  ];

  Widget _buildSlidingPages(double scale) {
    final double imageWidth = (420 * scale).clamp(260.0, 440.0);
    return PageView(
      onPageChanged: (int index) {
        setState(() {
          _currentPageIndex = index;
        });
      },
      children: [
        Center(
          child: SizedBox(
            width: imageWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/いもり.png',
                  width: imageWidth,
                  fit: BoxFit.contain,
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
        const SizedBox.expand(),
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
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
          ),
          child: Text(
            '分析を始める',
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

  Widget _buildBottomItem(int index) {
    final bool active = _selectedBottomIndex == index;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: active
              ? const Color(0xFF15233A).withValues(alpha: 0.72)
              : Colors.transparent,
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedBottomIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _bottomIcons[index],
                  size: 28,
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isScanTab = _selectedBottomIndex == 0;

    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: const Color(0xFF2B3A56).withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF101A2B).withValues(alpha: 0.92),
                  const Color(0xFF080F1C).withValues(alpha: 0.96),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: List<Widget>.generate(
                  _bottomLabels.length,
                  _buildBottomItem,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: isScanTab
            ? LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double widthScale = (constraints.maxWidth / 430).clamp(
                    0.82,
                    1.0,
                  );
                  final double heightScale = (constraints.maxHeight / 860)
                      .clamp(0.74, 1.0);
                  final double scale = widthScale < heightScale
                      ? widthScale
                      : heightScale;

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24 * scale,
                      vertical: 20 * scale,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Facial Analysis',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: (42 * scale).clamp(30.0, 42.0),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.settings_rounded,
                                size: 40 * scale,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20 * scale),
                        Expanded(child: _buildSlidingPages(scale)),
                        SizedBox(height: 14 * scale),
                        _buildPageIndicator(),
                        SizedBox(height: 12 * scale),
                      ],
                    ),
                  );
                },
              )
            : const SizedBox.expand(),
      ),
    );
  }
}
