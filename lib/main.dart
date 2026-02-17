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
  int _selectedDotIndex = 0;

  static const List<IconData> _bottomIcons = <IconData>[
    Icons.crop_free_rounded,
    Icons.bar_chart_rounded,
    Icons.check_circle_outline_rounded,
    Icons.more_horiz_rounded,
  ];

  static const List<String> _bottomLabels = <String>[
    'scan',
    'growth',
    'daily',
    'coach',
  ];

  Widget _buildMainCard(double scale) {
    final double cardRadius = 36 * scale;
    final double imageRadius = 28 * scale;
    final double cardPadding = 18 * scale;
    final double headingSize = (42 * scale).clamp(24.0, 42.0);
    final double buttonHeight = (68 * scale).clamp(48.0, 68.0);
    final double buttonRadius = 36 * scale;
    final double buttonTextSize = (30 * scale).clamp(20.0, 30.0);
    final double avatarSize = (220 * scale).clamp(120.0, 220.0);
    final double topGap = (22 * scale).clamp(10.0, 22.0);
    final double bottomGap = (20 * scale).clamp(10.0, 20.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF161B27), Color(0xFF070A11)],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(imageRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2A3343), Color(0xFF0D1119)],
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.account_circle_rounded,
                      size: avatarSize,
                      color: const Color(0xFFB7BFCC),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: topGap),
          Text(
            'Get your ratings and\nrecommendations',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: headingSize,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: bottomGap),
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(buttonRadius),
                gradient: const LinearGradient(
                  colors: [Color(0xFF5D34FF), Color(0xFFB71CF7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9141FF).withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonRadius),
                  ),
                ),
                onPressed: () {},
                child: Text(
                  'Begin scan',
                  style: TextStyle(
                    fontSize: buttonTextSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(3, (int index) {
        final bool active = index == _selectedDotIndex;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDotIndex = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 22 : 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.36),
            ),
          ),
        );
      }),
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
                        Expanded(child: _buildMainCard(scale)),
                        SizedBox(height: 24 * scale),
                        _buildDots(),
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
