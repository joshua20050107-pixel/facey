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
  bool _settingsNotificationEnabled = false;
  static const double _topIconSize = 39;
  static const double _topHeaderHeight = 52;
  static const double _pageHorizontalPadding = 24;
  static const double _pageTopPadding = 12;

  static const List<IconData> _bottomIcons = <IconData>[
    Icons.crop_free_rounded,
    Icons.event_available,
    Icons.bar_chart_rounded,
    Icons.chat_bubble_outline_rounded,
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

  Widget _buildTopHeader({
    required String title,
    required TextStyle titleStyle,
  }) {
    return SizedBox(
      height: _topHeaderHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(right: _topIconSize + 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: (_topHeaderHeight - _topIconSize) / 2,
            child: GestureDetector(
              onTap: () {},
              child: Image.asset(
                'assets/images/keke.png',
                width: _topIconSize,
                height: _topIconSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachSettingsScreen() {
    final Color separatorColor = Colors.white.withValues(alpha: 0.1);
    final Color mutedTextColor = Colors.white.withValues(alpha: 0.92);

    Widget settingsRow({
      required IconData icon,
      required String label,
      Widget? trailing,
      bool highlighted = false,
      Color textColor = Colors.white,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0xFF2A3358).withValues(alpha: 0.75)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: mutedTextColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _pageHorizontalPadding,
        _pageTopPadding,
        _pageHorizontalPadding,
        8,
      ),
      child: Column(
        children: [
          _buildTopHeader(
            title: '設定',
            titleStyle: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                settingsRow(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notification',
                  highlighted: true,
                  trailing: Switch(
                    value: _settingsNotificationEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _settingsNotificationEnabled = value;
                      });
                    },
                  ),
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(icon: Icons.dark_mode_outlined, label: 'Dark Mode'),
                Divider(height: 1, color: separatorColor),
                settingsRow(icon: Icons.star_border_rounded, label: 'Rate App'),
                Divider(height: 1, color: separatorColor),
                settingsRow(icon: Icons.share_outlined, label: 'Share App'),
                Divider(height: 1, color: separatorColor),
                settingsRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Privacy Policy',
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(
                  icon: Icons.description_outlined,
                  label: 'Terms and Conditions',
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(
                  icon: Icons.text_snippet_outlined,
                  label: 'Cookies Policy',
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(icon: Icons.mail_outline_rounded, label: 'Contact'),
                Divider(height: 1, color: separatorColor),
                settingsRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Feedback',
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(icon: Icons.logout_rounded, label: 'Logout'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isScanTab = _selectedBottomIndex == 0;
    final bool isCoachTab = _selectedBottomIndex == 4;

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
      body: isScanTab
          ? SafeArea(
              child: LayoutBuilder(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: _pageHorizontalPadding,
                      vertical: _pageTopPadding,
                    ),
                    child: Column(
                      children: [
                        _buildTopHeader(
                          title: 'ビジュアル評価',
                          titleStyle: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        Transform.translate(
                          offset: const Offset(3, -4),
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'あなたの魅力と改善点を分析',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFB9C0CF),
                              ),
                            ),
                          ),
                        ),

                        Expanded(child: _buildSlidingPages(scale)),
                        const SizedBox(height: 8),
                        _buildPageIndicator(),
                        const SizedBox(height: 23),
                      ],
                    ),
                  );
                },
              ),
            )
          : isCoachTab
          ? SafeArea(child: _buildCoachSettingsScreen())
          : const SizedBox.expand(),
    );
  }
}
