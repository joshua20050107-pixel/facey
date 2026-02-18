import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/activity_tab_screen.dart';
import 'screens/coach_settings_screen.dart';
import 'screens/scan_tab_screen.dart';
import 'widgets/yomu_gender_two_choice.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>('app_prefs');
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
  static const String _prefsBoxName = 'app_prefs';
  static const String _genderKey = 'selected_gender';
  int _selectedBottomIndex = 0;
  bool _settingsNotificationEnabled = false;
  YomuGender _selectedGender = YomuGender.male;

  @override
  void initState() {
    super.initState();
    _loadSavedGender();
  }

  void _loadSavedGender() {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    final String? saved = box.get(_genderKey);
    if (saved == null) return;
    final YomuGender gender = saved == YomuGender.female.name
        ? YomuGender.female
        : YomuGender.male;
    _selectedGender = gender;
  }

  Future<void> _saveGender(YomuGender value) async {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    await box.put(_genderKey, value.name);
  }

  static const List<IconData> _bottomIcons = <IconData>[
    Icons.crop_free_rounded,
    Icons.person_rounded,
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
          color: active ? const Color(0xFF3A4D6E) : Colors.transparent,
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
                      : Colors.white.withValues(alpha: 0.62),
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
    final Widget tabBody = isScanTab
        ? SafeArea(child: ScanTabScreen(selectedGender: _selectedGender))
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
              selectedGender: _selectedGender,
              onGenderChanged: (YomuGender value) {
                setState(() {
                  _selectedGender = value;
                });
                _saveGender(value);
              },
            ),
          )
        : const SizedBox.expand();

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: const Color(0xFF6E7F99).withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.34),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1D2737).withValues(alpha: 0.9),
                  const Color(0xFF141C2A).withValues(alpha: 0.94),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0C10), Color(0xFF1A2230), Color(0xFF2E3F5B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: tabBody,
      ),
    );
  }
}
