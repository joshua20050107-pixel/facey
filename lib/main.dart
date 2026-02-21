import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/activity_tab_screen.dart';
import 'screens/chat_tab_screen.dart';
import 'screens/coach_settings_screen.dart';
import 'screens/growth_log_tab_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const String _prefsBoxName = 'app_prefs';
  static const String _genderKey = 'selected_gender';
  static final SpringDescription _bottomIconSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 200, ratio: 0.5);
  static final SpringDescription _bottomTargetSlideSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 260, ratio: 0.78);
  int _selectedBottomIndex = 0;
  bool _settingsNotificationEnabled = false;
  YomuGender _selectedGender = YomuGender.male;
  late final List<AnimationController> _bottomIconScaleControllers;
  late final List<Timer?> _bottomIconClampTimers;
  late final AnimationController _bottomTargetSlideController;
  late final AnimationController _bottomCapsuleScaleController;
  Timer? _bottomCapsuleClampTimer;

  @override
  void initState() {
    super.initState();
    _bottomIconScaleControllers = List<AnimationController>.generate(
      _bottomIcons.length,
      (_) => AnimationController.unbounded(vsync: this, value: 1.0),
    );
    _bottomIconClampTimers = List<Timer?>.filled(_bottomIcons.length, null);
    _bottomTargetSlideController = AnimationController.unbounded(
      vsync: this,
      value: _selectedBottomIndex.toDouble(),
    );
    _bottomCapsuleScaleController = AnimationController.unbounded(
      vsync: this,
      value: 1.0,
    );
    _loadSavedGender();
  }

  @override
  void dispose() {
    for (final Timer? timer in _bottomIconClampTimers) {
      timer?.cancel();
    }
    _bottomCapsuleClampTimer?.cancel();
    for (final AnimationController controller in _bottomIconScaleControllers) {
      controller.dispose();
    }
    _bottomTargetSlideController.dispose();
    _bottomCapsuleScaleController.dispose();
    super.dispose();
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
    '成長ログ',
    'daily',
    'coach',
  ];

  static const MethodChannel _hapticChannel = MethodChannel('facey/haptics');

  void _triggerBottomNavHaptic() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    unawaited(
      _hapticChannel.invokeMethod<void>('softImpact').catchError((Object _) {}),
    );
  }

  void _playBottomIconSpring(int index) {
    final AnimationController controller = _bottomIconScaleControllers[index];
    _bottomIconClampTimers[index]?.cancel();
    controller.stop();
    controller.value = 0.88;
    controller.animateWith(
      SpringSimulation(_bottomIconSpring, controller.value, 1.0, 8.2),
    );
    _bottomIconClampTimers[index] = Timer(
      const Duration(milliseconds: 300),
      () {
        if (!mounted) return;
        controller.stop();
        controller.value = 1.0;
      },
    );
  }

  void _playBottomCapsuleSpring() {
    _bottomCapsuleClampTimer?.cancel();
    _bottomCapsuleScaleController.stop();
    _bottomCapsuleScaleController.value = 0.9;
    _bottomCapsuleScaleController.animateWith(
      SpringSimulation(
        _bottomIconSpring,
        _bottomCapsuleScaleController.value,
        1.0,
        7.8,
      ),
    );
    _bottomCapsuleClampTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _bottomCapsuleScaleController.stop();
      _bottomCapsuleScaleController.value = 1.0;
    });
  }

  void _slideBottomTargetTo(int index) {
    _bottomTargetSlideController.stop();
    _bottomTargetSlideController.animateWith(
      SpringSimulation(
        _bottomTargetSlideSpring,
        _bottomTargetSlideController.value,
        index.toDouble(),
        0.0,
      ),
    );
  }

  Widget _buildBottomItem(int index) {
    final bool active = _selectedBottomIndex == index;
    final double iconSize = active ? 29.4 : 28;
    final AnimationController iconScaleController =
        _bottomIconScaleControllers[index];
    return Expanded(
      child: InkWell(
        onTap: () {
          _triggerBottomNavHaptic();
          _playBottomIconSpring(index);
          _playBottomCapsuleSpring();
          _slideBottomTargetTo(index);
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
              AnimatedBuilder(
                animation: iconScaleController,
                builder: (BuildContext context, Widget? child) {
                  return Transform.scale(
                    scale: iconScaleController.value.clamp(0.88, 1.12),
                    child: child,
                  );
                },
                child: Icon(
                  _bottomIcons[index],
                  size: iconSize,
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isScanTab = _selectedBottomIndex == 0;
    final bool isSecondTab = _selectedBottomIndex == 1;
    final bool isThirdTab = _selectedBottomIndex == 2;
    final bool isChatTab = _selectedBottomIndex == 3;
    final bool isCoachTab = _selectedBottomIndex == 4;
    final Widget tabBody = isScanTab
        ? SafeArea(child: ScanTabScreen(selectedGender: _selectedGender))
        : isSecondTab
        ? const SafeArea(child: ActivityTabScreen())
        : isThirdTab
        ? const SafeArea(child: GrowthLogTabScreen())
        : isChatTab
        ? const SafeArea(child: ChatTabScreen())
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
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
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
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final int itemCount = _bottomLabels.length;
                  final double itemWidth = constraints.maxWidth / itemCount;
                  return Stack(
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge(<Listenable>[
                          _bottomTargetSlideController,
                          _bottomCapsuleScaleController,
                        ]),
                        builder: (BuildContext context, Widget? child) {
                          final double target = _bottomTargetSlideController
                              .value
                              .clamp(0.0, (itemCount - 1).toDouble());
                          return Positioned(
                            left: target * itemWidth,
                            top: 0,
                            bottom: 0,
                            width: itemWidth,
                            child: Transform.scale(
                              scale: _bottomCapsuleScaleController.value.clamp(
                                0.9,
                                1.08,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    color: const Color(0xFF3A4D6E),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Row(
                        children: List<Widget>.generate(
                          _bottomLabels.length,
                          _buildBottomItem,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF10151D), Color(0xFF222C3B), Color(0xFF364B68)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: tabBody,
      ),
    );
  }
}
