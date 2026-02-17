import 'package:flutter/material.dart';

import 'screens/activity_tab_screen.dart';
import 'screens/coach_settings_screen.dart';
import 'screens/scan_tab_screen.dart';

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
  bool _settingsNotificationEnabled = false;

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

  Widget _buildBottomItem(int index) {
    final bool active = _selectedBottomIndex == index;
    final double iconSize = active ? 29.4 : 28;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: active
              ? const Color(0xFF1F3150)
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
                  size: iconSize,
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
    final bool isSecondTab = _selectedBottomIndex == 1;
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
          ? const SafeArea(child: ScanTabScreen())
          : isSecondTab
          ? const SafeArea(child: ActivityTabScreen())
          : isCoachTab
          ? SafeArea(
              child: CoachSettingsScreen(
                notificationEnabled: _settingsNotificationEnabled,
                onNotificationChanged: (bool value) {
                  setState(() {
                    _settingsNotificationEnabled = value;
                  });
                },
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
