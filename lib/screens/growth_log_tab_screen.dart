import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:facey/screens/face_analysis_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GrowthLogTabScreen extends StatefulWidget {
  const GrowthLogTabScreen({super.key});

  @override
  State<GrowthLogTabScreen> createState() => _GrowthLogTabScreenState();
}

class _GrowthLogTabScreenState extends State<GrowthLogTabScreen> {
  static const String _prefsBoxName = 'app_prefs';
  static const String _latestResultFrontImageKey = 'latest_result_front_image';
  static const String _resultOverallSumKey = 'result_overall_sum';
  static const String _resultPotentialSumKey = 'result_potential_sum';
  static const String _resultCountKey = 'result_count';
  static const String _resultFrontImageHistoryKey =
      'result_front_image_history';
  static const String _resultFrontImageHistoryMetaKey =
      'result_front_image_history_meta';
  static const String _resultMonthlyScoresKey = 'result_monthly_scores';
  static const String _growthHabitsKey = 'growth_habits_v1';

  int? _overallScore;
  int? _potentialScore;
  String? _latestFrontImagePath;
  List<_FrontImageEntry> _frontImageHistory = <_FrontImageEntry>[];
  Map<String, _MonthlyScore> _monthlyScores = <String, _MonthlyScore>{};
  List<_HabitItem> _habits = <_HabitItem>[];
  String? _editingHabitId;
  final Set<String> _removingHabitIds = <String>{};
  final Object _habitTapRegionGroup = Object();
  final RegExp _dateKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  Timer? _habitLongPressTimer;

  @override
  void initState() {
    super.initState();
    _loadLatestScores();
  }

  Future<void> _loadLatestScores() async {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    final int overallSum =
        int.tryParse(box.get(_resultOverallSumKey) ?? '') ?? 0;
    final int potentialSum =
        int.tryParse(box.get(_resultPotentialSumKey) ?? '') ?? 0;
    final int count = int.tryParse(box.get(_resultCountKey) ?? '') ?? 0;
    final int? overallParsed = count > 0 ? (overallSum / count).round() : null;
    final int? potentialParsed = count > 0
        ? (potentialSum / count).round()
        : null;
    final String? latestFrontPath = box.get(_latestResultFrontImageKey);
    final bool hasLatestImage =
        latestFrontPath != null &&
        latestFrontPath.isNotEmpty &&
        File(latestFrontPath).existsSync();
    final String metaRaw = box.get(_resultFrontImageHistoryMetaKey) ?? '[]';
    List<_FrontImageEntry> history = <_FrontImageEntry>[];
    try {
      final List<dynamic> metaList = jsonDecode(metaRaw) as List<dynamic>;
      history = metaList
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> item) {
            final String path = (item['path'] ?? '').toString();
            final String sidePath = (item['sidePath'] ?? '').toString();
            final String addedAtRaw = (item['addedAt'] ?? '').toString();
            final DateTime? addedAt = DateTime.tryParse(addedAtRaw);
            if (path.isEmpty || !File(path).existsSync()) return null;
            return _FrontImageEntry(
              path: path,
              sidePath: sidePath.isNotEmpty && File(sidePath).existsSync()
                  ? sidePath
                  : null,
              addedAt: addedAt ?? DateTime.now(),
            );
          })
          .whereType<_FrontImageEntry>()
          .toList();
    } catch (_) {
      history = <_FrontImageEntry>[];
    }
    if (history.isEmpty) {
      final String historyRaw = box.get(_resultFrontImageHistoryKey) ?? '';
      history = historyRaw
          .split('\n')
          .where((String p) => p.isNotEmpty && File(p).existsSync())
          .map(
            (String p) =>
                _FrontImageEntry(path: p, addedAt: File(p).lastModifiedSync()),
          )
          .toList();
    }
    final String monthlyRaw = box.get(_resultMonthlyScoresKey) ?? '{}';
    Map<String, _MonthlyScore> monthlyScores = <String, _MonthlyScore>{};
    try {
      final Map<String, dynamic> monthlyMap = Map<String, dynamic>.from(
        jsonDecode(monthlyRaw) as Map<String, dynamic>,
      );
      monthlyScores = monthlyMap.map((String key, dynamic value) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          value as Map? ?? <String, dynamic>{},
        );
        final int overallSum =
            (data['overallSum'] is num ? data['overallSum'] as num : 0).toInt();
        final int potentialSum =
            (data['potentialSum'] is num ? data['potentialSum'] as num : 0)
                .toInt();
        final int count = (data['count'] is num ? data['count'] as num : 0)
            .toInt();
        return MapEntry<String, _MonthlyScore>(
          key,
          _MonthlyScore(
            overallAvg: count > 0 ? (overallSum / count).round() : 0,
            potentialAvg: count > 0 ? (potentialSum / count).round() : 0,
            hasData: count > 0,
          ),
        );
      });
    } catch (_) {
      monthlyScores = <String, _MonthlyScore>{};
    }
    final String habitsRaw = box.get(_growthHabitsKey) ?? '[]';
    List<_HabitItem> habits = <_HabitItem>[];
    try {
      final List<dynamic> decoded = jsonDecode(habitsRaw) as List<dynamic>;
      habits = decoded
          .whereType<Map<String, dynamic>>()
          .map(_HabitItem.fromJson)
          .toList();
    } catch (_) {
      habits = <_HabitItem>[];
    }
    habits = habits.map(_normalizeHabit).toList();
    final String normalizedHabitsRaw = jsonEncode(
      habits.map((e) => e.toJson()).toList(),
    );

    if (!mounted) return;
    setState(() {
      _overallScore = overallParsed?.clamp(0, 100);
      _potentialScore = potentialParsed?.clamp(0, 100);
      _latestFrontImagePath = hasLatestImage ? latestFrontPath : null;
      _frontImageHistory = history;
      _monthlyScores = monthlyScores;
      _habits = habits;
    });
    if (normalizedHabitsRaw != habitsRaw) {
      await box.put(_growthHabitsKey, normalizedHabitsRaw);
    }
  }

  bool _isValidDateKey(String key) {
    if (!_dateKeyPattern.hasMatch(key)) return false;
    return DateTime.tryParse(key) != null;
  }

  List<String> _normalizedDateKeys(Iterable<String> rawKeys) {
    final Set<String> unique = <String>{};
    for (final String key in rawKeys) {
      if (_isValidDateKey(key)) unique.add(key);
    }
    final List<String> sorted = unique.toList()..sort();
    return sorted;
  }

  String _latestDateKey(Iterable<String> dateKeys) {
    final List<String> sorted = _normalizedDateKeys(dateKeys);
    if (sorted.isEmpty) return '';
    return sorted.last;
  }

  String _truncateToMaxChars(String raw, int maxChars) {
    return String.fromCharCodes(raw.runes.take(maxChars));
  }

  _HabitItem _normalizeHabit(_HabitItem item) {
    final String todayKey = _todayKey();
    final String normalizedTitle = _truncateToMaxChars(item.title, 25);
    final String normalizedGoal = _truncateToMaxChars(item.goal, 25);
    final List<String> seedDates = <String>[
      ...item.achievedDates,
      if (item.lastAchievedDate.isNotEmpty) item.lastAchievedDate,
    ];
    final List<String> dates = _normalizedDateKeys(seedDates);
    final String correctedLastDate = _latestDateKey(dates);
    final bool doneToday = dates.contains(todayKey);
    return item.copyWith(
      title: normalizedTitle,
      goal: normalizedGoal,
      achievedDays: dates.length,
      lastAchievedDate: correctedLastDate,
      achievedDates: dates,
      isDone: doneToday,
    );
  }

  Future<void> _persistHabits() async {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    final List<Map<String, dynamic>> payload = _habits
        .map((e) => e.toJson())
        .toList();
    await box.put(_growthHabitsKey, jsonEncode(payload));
  }

  Future<void> _showAddHabitSheet() async {
    final TextEditingController controller = TextEditingController();
    final TextEditingController goalController = TextEditingController();
    bool isGoalStep = false;
    bool showTitleError = false;
    final _HabitItem? created = await showDialog<_HabitItem>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        _HabitItem? buildHabitFromInput() {
          final String title = _truncateToMaxChars(controller.text.trim(), 25);
          if (title.isEmpty) return null;
          final String goal = _truncateToMaxChars(
            goalController.text.trim(),
            25,
          );
          return _HabitItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            goal: goal,
            achievedDays: 0,
            lastAchievedDate: '',
            achievedDates: const <String>[],
            emoji: '',
            isDone: false,
          );
        }

        return MediaQuery.removeViewInsets(
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          context: context,
          child: SafeArea(
            child: StatefulBuilder(
              builder:
                  (
                    BuildContext context,
                    void Function(void Function()) setDialogState,
                  ) {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 206, 14, 0),
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF121B2A),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 320),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isGoalStep
                                          ? '目標を入力してください'
                                          : '継続したい習慣を追加してください',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFF3F6FB),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (!isGoalStep)
                                      TextField(
                                        controller: controller,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) {
                                          final String title =
                                              _truncateToMaxChars(
                                                controller.text.trim(),
                                                25,
                                              );
                                          if (title.isEmpty) {
                                            setDialogState(() {
                                              showTitleError = true;
                                            });
                                            return;
                                          }
                                          setDialogState(() {
                                            showTitleError = false;
                                            isGoalStep = true;
                                          });
                                        },
                                        minLines: 1,
                                        maxLines: 2,
                                        maxLength: 25,
                                        maxLengthEnforcement:
                                            MaxLengthEnforcement.enforced,
                                        inputFormatters: <TextInputFormatter>[
                                          LengthLimitingTextInputFormatter(25),
                                        ],
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '例: 水を2L飲む',
                                          helperText: showTitleError
                                              ? '習慣を入力してください'
                                              : '25文字まで',
                                          helperStyle: TextStyle(
                                            color: showTitleError
                                                ? const Color(0xFFFF8D8D)
                                                : Colors.white.withValues(
                                                    alpha: 0.58,
                                                  ),
                                            fontSize: 12,
                                          ),
                                          counterStyle: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.62,
                                            ),
                                            fontSize: 12,
                                          ),
                                          hintStyle: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.45,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFF1A2435),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      )
                                    else
                                      TextField(
                                        controller: goalController,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) {
                                          final _HabitItem? habit =
                                              buildHabitFromInput();
                                          if (habit == null) return;
                                          Navigator.of(context).pop(habit);
                                        },
                                        minLines: 1,
                                        maxLines: 2,
                                        maxLength: 25,
                                        maxLengthEnforcement:
                                            MaxLengthEnforcement.enforced,
                                        inputFormatters: <TextInputFormatter>[
                                          LengthLimitingTextInputFormatter(25),
                                        ],
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '例: 肌を綺麗にする',
                                          helperText: '25文字まで',
                                          helperStyle: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.58,
                                            ),
                                            fontSize: 12,
                                          ),
                                          counterStyle: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.62,
                                            ),
                                            fontSize: 12,
                                          ),
                                          hintStyle: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.45,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFF1A2435),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF80C5FF,
                                          ),
                                          foregroundColor: const Color(
                                            0xFF0D1420,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          if (!isGoalStep) {
                                            final String title =
                                                _truncateToMaxChars(
                                                  controller.text.trim(),
                                                  25,
                                                );
                                            if (title.isEmpty) {
                                              setDialogState(() {
                                                showTitleError = true;
                                              });
                                              return;
                                            }
                                            setDialogState(() {
                                              showTitleError = false;
                                              isGoalStep = true;
                                            });
                                            return;
                                          }
                                          final _HabitItem? habit =
                                              buildHabitFromInput();
                                          if (habit == null) return;
                                          Navigator.of(context).pop(habit);
                                        },
                                        child: Text(
                                          isGoalStep ? '追加する' : '次へ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
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
                      ),
                    );
                  },
            ),
          ),
        );
      },
    );
    if (created == null) return;
    setState(() {
      _habits = <_HabitItem>[created, ..._habits];
    });
    await _persistHabits();
  }

  Future<void> _toggleHabit(String id) async {
    final String todayKey = _todayKey();
    setState(() {
      _habits = _habits.map((_HabitItem item) {
        if (item.id != id) return item;
        final List<String> dates = _normalizedDateKeys(item.achievedDates);
        final bool hasToday = dates.contains(todayKey);
        if (hasToday) {
          dates.remove(todayKey);
        } else {
          dates.add(todayKey);
          dates.sort();
        }
        return item.copyWith(
          isDone: !hasToday,
          achievedDays: dates.length,
          lastAchievedDate: _latestDateKey(dates),
          achievedDates: dates,
        );
      }).toList();
    });
    await _persistHabits();
  }

  Future<void> _deleteHabit(String id) async {
    if (_removingHabitIds.contains(id)) return;
    setState(() {
      _removingHabitIds.add(id);
    });
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() {
      _habits.removeWhere((_HabitItem item) => item.id == id);
      if (_editingHabitId == id) {
        _editingHabitId = null;
      }
      _removingHabitIds.remove(id);
    });
    await _persistHabits();
  }

  void _closeHabitActions() {
    if (_editingHabitId == null) return;
    setState(() {
      _editingHabitId = null;
    });
  }

  void _startHabitLongPressTimer(String habitId) {
    _habitLongPressTimer?.cancel();
    _habitLongPressTimer = Timer(const Duration(milliseconds: 320), () {
      if (!mounted || _editingHabitId == habitId) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _editingHabitId = habitId;
      });
    });
  }

  void _cancelHabitLongPressTimer() {
    _habitLongPressTimer?.cancel();
    _habitLongPressTimer = null;
  }

  @override
  void dispose() {
    _cancelHabitLongPressTimer();
    super.dispose();
  }

  void _onHabitReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      if (newIndex < 0 || newIndex >= _habits.length) return;
      final _HabitItem moved = _habits.removeAt(oldIndex);
      _habits.insert(newIndex, moved);
    });
    _persistHabits();
  }

  String _todayKey() {
    final DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _openHabitPage(_HabitItem habit) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _HabitPlaceholderScreen(habit: habit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasScores = _overallScore != null && _potentialScore != null;
    final bool canOpenProgress = hasScores && _frontImageHistory.isNotEmpty;
    final int overallScore = _overallScore ?? 0;
    final int potentialScore = _potentialScore ?? 0;
    final int potentialDelta = potentialScore - overallScore;
    final String overallText = hasScores ? '$overallScore' : '-';
    final String potentialText = hasScores ? '$potentialScore' : '-';
    final String? potentialDeltaText = !hasScores
        ? null
        : potentialDelta > 0
        ? '↗ +$potentialDelta'
        : potentialDelta < 0
        ? '↘ $potentialDelta'
        : null;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: SizedBox(
                  height: 52,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Growth',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(7, -4),
                child: const Text(
                  'あなたの変化を振り返りましょう',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB9C0CF),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProgressSummaryCard(
                        overallText: overallText,
                        potentialText: potentialText,
                        potentialDeltaText: potentialDeltaText,
                        hasScores: hasScores,
                        overallScore: overallScore,
                        potentialScore: potentialScore,
                        imagePath: _latestFrontImagePath,
                        onChevronTap: canOpenProgress
                            ? () {
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => _GrowthProgressPicsScreen(
                                      overallText: overallText,
                                      potentialText: potentialText,
                                      potentialDeltaText: potentialDeltaText,
                                      hasScores: hasScores,
                                      overallScore: overallScore,
                                      potentialScore: potentialScore,
                                      imagePath: _latestFrontImagePath,
                                      imagePaths: _frontImageHistory,
                                      monthlyScores: _monthlyScores,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        showChevron: true,
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          '習慣リスト',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE9EEF7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_habits.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1A2332,
                            ).withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            '+ボタンで新しい習慣を追加',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        )
                      else
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          buildDefaultDragHandles: false,
                          itemCount: _habits.length,
                          onReorderStart: (int index) {
                            _cancelHabitLongPressTimer();
                            HapticFeedback.mediumImpact();
                            if (index < 0 || index >= _habits.length) return;
                            setState(() {
                              _editingHabitId = _habits[index].id;
                            });
                          },
                          onReorder: _onHabitReorder,
                          proxyDecorator:
                              (
                                Widget child,
                                int index,
                                Animation<double> animation,
                              ) => child,
                          itemBuilder: (BuildContext context, int index) {
                            final _HabitItem habit = _habits[index];
                            final bool isRemoving = _removingHabitIds.contains(
                              habit.id,
                            );
                            final bool isEditing = _editingHabitId == habit.id;
                            final Widget habitRow = TapRegion(
                              groupId: _habitTapRegionGroup,
                              onTapOutside: (_) => _closeHabitActions(),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOutCubic,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    gradient: habit.isDone
                                        ? const LinearGradient(
                                            colors: <Color>[
                                              Color(0xFF203651),
                                              Color(0xFF2C4A6A),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          )
                                        : null,
                                    color: habit.isDone
                                        ? null
                                        : const Color(0xFF111A28),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: habit.isDone
                                          ? Colors.white.withValues(alpha: 0.27)
                                          : Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        if (_editingHabitId != null) {
                                          _closeHabitActions();
                                          return;
                                        }
                                        _openHabitPage(habit);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 160,
                                        ),
                                        curve: Curves.easeOut,
                                        decoration: BoxDecoration(
                                          gradient: habit.isDone
                                              ? const LinearGradient(
                                                  colors: <Color>[
                                                    Color(0xFF203651),
                                                    Color(0xFF2C4A6A),
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                )
                                              : null,
                                          color: habit.isDone
                                              ? null
                                              : const Color(0xFF111A28),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    habit.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: habit.isDone
                                                          ? const Color(
                                                              0xFFE7F0FF,
                                                            )
                                                          : const Color(
                                                              0xFFF0F5FF,
                                                            ),
                                                      decoration:
                                                          TextDecoration.none,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Transform.translate(
                                              offset: const Offset(-10, 0),
                                              child: SizedBox(
                                                width: 108,
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    Positioned(
                                                      left: 40,
                                                      top: 4,
                                                      child: IgnorePointer(
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .local_fire_department_rounded,
                                                              size: 13,
                                                              color: Color(
                                                                0xFFFFA439,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${habit.achievedDays}',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.86,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      left: 0,
                                                      top: 15,
                                                      child: GestureDetector(
                                                        onTap: () =>
                                                            _toggleHabit(
                                                              habit.id,
                                                            ),
                                                        child: AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    150,
                                                              ),
                                                          width: 34,
                                                          height: 34,
                                                          decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: habit.isDone
                                                                ? const Color(
                                                                    0xFF80C5FF,
                                                                  )
                                                                : Colors.white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.25,
                                                                      ),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .white
                                                                  .withValues(
                                                                    alpha: 0.6,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: habit.isDone
                                                              ? const Icon(
                                                                  Icons
                                                                      .check_rounded,
                                                                  size: 20,
                                                                  color: Color(
                                                                    0xFF0C1522,
                                                                  ),
                                                                )
                                                              : null,
                                                        ),
                                                      ),
                                                    ),
                                                    if (isEditing)
                                                      Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                right: 8,
                                                              ),
                                                          child: GestureDetector(
                                                            behavior:
                                                                HitTestBehavior
                                                                    .opaque,
                                                            onTap: () =>
                                                                _deleteHabit(
                                                                  habit.id,
                                                                ),
                                                            child: Container(
                                                              width: 30,
                                                              height: 30,
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    const Color(
                                                                      0xFFE03A3A,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      15,
                                                                    ),
                                                              ),
                                                              child: const Icon(
                                                                Icons
                                                                    .delete_rounded,
                                                                size: 19,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                            final Widget animatedRow = ClipRect(
                              key: ValueKey<String>(
                                'habit-reorder-${habit.id}',
                              ),
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeInOut,
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  height: isRemoving ? 0 : 94,
                                  child: IgnorePointer(
                                    ignoring: isRemoving,
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      opacity: isRemoving ? 0 : 1,
                                      child: habitRow,
                                    ),
                                  ),
                                ),
                              ),
                            );
                            final Widget dragStartListener = isEditing
                                ? ReorderableDragStartListener(
                                    index: index,
                                    child: animatedRow,
                                  )
                                : ReorderableDelayedDragStartListener(
                                    index: index,
                                    child: animatedRow,
                                  );
                            final Widget rowForState = Listener(
                              onPointerDown: (_) {
                                if (!isEditing) {
                                  _startHabitLongPressTimer(habit.id);
                                }
                              },
                              onPointerUp: (_) => _cancelHabitLongPressTimer(),
                              onPointerCancel: (_) =>
                                  _cancelHabitLongPressTimer(),
                              child: dragStartListener,
                            );
                            return KeyedSubtree(
                              key: ValueKey<String>(
                                'habit-reorder-${habit.id}',
                              ),
                              child: rowForState,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _FloatingAddButton(
          onPressed: () {
            if (_editingHabitId != null) {
              _closeHabitActions();
              return;
            }
            _showAddHabitSheet();
          },
        ),
      ],
    );
  }
}

class _GrowthProgressPicsScreen extends StatefulWidget {
  const _GrowthProgressPicsScreen({
    required this.overallText,
    required this.potentialText,
    required this.potentialDeltaText,
    required this.hasScores,
    required this.overallScore,
    required this.potentialScore,
    required this.imagePath,
    required this.imagePaths,
    required this.monthlyScores,
  });

  final String overallText;
  final String potentialText;
  final String? potentialDeltaText;
  final bool hasScores;
  final int overallScore;
  final int potentialScore;
  final String? imagePath;
  final List<_FrontImageEntry> imagePaths;
  final Map<String, _MonthlyScore> monthlyScores;

  @override
  State<_GrowthProgressPicsScreen> createState() =>
      _GrowthProgressPicsScreenState();
}

class _HabitPlaceholderScreen extends StatefulWidget {
  const _HabitPlaceholderScreen({required this.habit});

  final _HabitItem habit;

  @override
  State<_HabitPlaceholderScreen> createState() =>
      _HabitPlaceholderScreenState();
}

class _HabitPlaceholderScreenState extends State<_HabitPlaceholderScreen> {
  late DateTime _visibleMonth;

  int _daysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  DateTime? _parseDateKey(String raw) {
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Set<DateTime> _achievementDates() {
    return widget.habit.achievedDates
        .map(_parseDateKey)
        .whereType<DateTime>()
        .map((DateTime d) => DateTime(d.year, d.month, d.day))
        .toSet();
  }

  Set<int> _activeDays(DateTime month) {
    final Set<DateTime> dates = _achievementDates();
    final Set<int> active = <int>{};
    for (final DateTime date in dates) {
      if (date.year == month.year && date.month == month.month) {
        active.add(date.day);
      }
    }
    return active;
  }

  int _monthlyCount(DateTime month) {
    return _activeDays(month).length;
  }

  int _streakDays(DateTime today) {
    final Set<DateTime> dates = _achievementDates();
    final DateTime todayDate = DateTime(today.year, today.month, today.day);
    final DateTime yesterdayDate = todayDate.subtract(const Duration(days: 1));
    DateTime? start;
    if (dates.contains(todayDate)) {
      start = todayDate;
    } else if (dates.contains(yesterdayDate)) {
      start = yesterdayDate;
    }
    if (start == null) return 0;
    int streak = 0;
    DateTime cursor = start;
    while (dates.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _monthLabel(DateTime month) {
    return '${month.year}年${month.month}月';
  }

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime currentMonth = DateTime.now();
    final int daysInMonth = _daysInMonth(_visibleMonth);
    final Set<int> activeDays = _activeDays(_visibleMonth);
    final int monthlyValue = _monthlyCount(currentMonth);
    final int allTimeValue = widget.habit.achievedDays;
    final int streakValue = _streakDays(DateTime.now());
    return Scaffold(
      backgroundColor: const Color(0xFF042448),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF042448),
              Color(0xFF021A35),
              Color(0xFF000D20),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _HabitInfoCard(
                        label: '習慣タイトル',
                        value: widget.habit.title,
                      ),
                      const SizedBox(height: 10),
                      _HabitInfoCard(
                        label: '目標',
                        value: widget.habit.goal.isEmpty
                            ? '-'
                            : widget.habit.goal,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: _HabitStatCard(
                              icon: Icons.all_inclusive_rounded,
                              label: '累計',
                              value: '$allTimeValue',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _HabitStatCard(
                              icon: Icons.calendar_month_outlined,
                              label: '今月',
                              value: '$monthlyValue',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _HabitStatCard(
                              icon: Icons.local_fire_department_rounded,
                              label: '連続',
                              value: '$streakValue',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              const Color(0xFF243551).withValues(alpha: 0.7),
                              const Color(0xFF2D4162).withValues(alpha: 0.62),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: _goToPreviousMonth,
                                    icon: const Icon(
                                      Icons.chevron_left_rounded,
                                      color: Color(0xFFE5EEFC),
                                    ),
                                  ),
                                  Text(
                                    _monthLabel(_visibleMonth),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFF0F5FF),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _goToNextMonth,
                                    icon: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFFE5EEFC),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              itemCount: daysInMonth,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 8,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 0.72,
                                  ),
                              itemBuilder: (BuildContext context, int index) {
                                final int day = index + 1;
                                final bool isActive = activeDays.contains(day);
                                return Column(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isActive
                                            ? const Color(0xFF80C5FF)
                                            : const Color(
                                                0xFFE8F0FF,
                                              ).withValues(alpha: 0.84),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$day',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(
                                          0xFFEAF1FF,
                                        ).withValues(alpha: 0.82),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HabitStatCard extends StatelessWidget {
  const _HabitStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            const Color(0xFF243551).withValues(alpha: 0.7),
            const Color(0xFF2D4162).withValues(alpha: 0.62),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 31, color: Colors.white.withValues(alpha: 0.88)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 43,
                    height: 0.85,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF5F7FF),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitInfoCard extends StatelessWidget {
  const _HabitInfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF20314B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF3F7FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthProgressPicsScreenState extends State<_GrowthProgressPicsScreen> {
  late final List<DateTime> _months;
  late int _selectedMonthIndex;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    final List<DateTime> monthCandidates = <DateTime>[
      DateTime(now.year, now.month),
      ...widget.imagePaths.map(
        (_FrontImageEntry e) => DateTime(e.addedAt.year, e.addedAt.month),
      ),
      ...widget.monthlyScores.keys.map(_parseMonthKey).whereType<DateTime>(),
    ];
    DateTime newest = monthCandidates.first;
    DateTime oldest = monthCandidates.first;
    for (final DateTime month in monthCandidates.skip(1)) {
      if (_compareMonth(month, newest) > 0) newest = month;
      if (_compareMonth(month, oldest) < 0) oldest = month;
    }

    // Add one month after latest so "next month" navigation is available.
    final DateTime upperBound = DateTime(newest.year, newest.month + 1);

    _months = <DateTime>[];
    DateTime cursor = DateTime(upperBound.year, upperBound.month);
    while (_compareMonth(cursor, oldest) >= 0) {
      _months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month - 1);
    }

    final int newestDataIndex = _months.indexWhere(
      (DateTime m) => m.year == newest.year && m.month == newest.month,
    );
    _selectedMonthIndex = newestDataIndex >= 0 ? newestDataIndex : 0;
  }

  List<_FrontImageEntry> _entriesForSelectedMonth() {
    final DateTime target = _months[_selectedMonthIndex];
    final List<_FrontImageEntry> entries = widget.imagePaths.where((
      _FrontImageEntry entry,
    ) {
      return entry.addedAt.year == target.year &&
          entry.addedAt.month == target.month;
    }).toList();
    entries.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return entries;
  }

  String _monthKey(DateTime month) {
    return '${month.year}-${month.month.toString().padLeft(2, '0')}';
  }

  _MonthlyScore? _scoreForMonth(int index) {
    final DateTime month = _months[index];
    final _MonthlyScore? score = widget.monthlyScores[_monthKey(month)];
    if (score == null || !score.hasData) return null;
    return score;
  }

  void _selectMonth(int nextIndex) {
    setState(() {
      _selectedMonthIndex = nextIndex;
    });
  }

  DateTime? _parseMonthKey(String key) {
    final RegExpMatch? m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(key);
    if (m == null) return null;
    final int? year = int.tryParse(m.group(1)!);
    final int? month = int.tryParse(m.group(2)!);
    if (year == null || month == null || month < 1 || month > 12) {
      return null;
    }
    return DateTime(year, month);
  }

  int _compareMonth(DateTime a, DateTime b) {
    if (a.year != b.year) return a.year.compareTo(b.year);
    return a.month.compareTo(b.month);
  }

  FaceAnalysisResult _resultForScore(_MonthlyScore score) {
    return FaceAnalysisResult(
      overall: score.overallAvg.clamp(0, 100),
      metrics: <FaceMetricScore>[
        FaceMetricScore(
          label: 'ポテンシャル',
          value: score.potentialAvg.clamp(0, 100),
        ),
        const FaceMetricScore(label: '性的魅力', value: 82),
        const FaceMetricScore(label: '印象', value: 73),
        const FaceMetricScore(label: '清潔感', value: 61),
        const FaceMetricScore(label: '骨格', value: 54),
        const FaceMetricScore(label: '肌', value: 34),
      ],
    );
  }

  void _goToPreviousMonth() {
    if (_selectedMonthIndex >= _months.length - 1) {
      final DateTime last = _months.last;
      _months.add(DateTime(last.year, last.month - 1));
    }
    _selectMonth(_selectedMonthIndex + 1);
  }

  void _goToNextMonth() {
    if (_selectedMonthIndex <= 0) {
      final DateTime first = _months.first;
      _months.insert(0, DateTime(first.year, first.month + 1));
      _selectMonth(0);
      return;
    }
    _selectMonth(_selectedMonthIndex - 1);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime selectedMonth = _months[_selectedMonthIndex];
    final List<_FrontImageEntry> monthEntries = _entriesForSelectedMonth();
    final _MonthlyScore displayedScore =
        _scoreForMonth(_selectedMonthIndex) ??
        _MonthlyScore(overallAvg: 0, potentialAvg: 0, hasData: false);
    final bool hasScores = displayedScore.hasData;
    final int overallScore = displayedScore.overallAvg;
    final int potentialScore = displayedScore.potentialAvg;
    final int potentialDelta = potentialScore - overallScore;
    final String overallText = hasScores ? '$overallScore' : '-';
    final String potentialText = hasScores ? '$potentialScore' : '-';
    final String? potentialDeltaText = !hasScores
        ? null
        : potentialDelta > 0
        ? '↗ +$potentialDelta'
        : potentialDelta < 0
        ? '↘ $potentialDelta'
        : null;
    final String? selectedMonthLatestImagePath = monthEntries.isNotEmpty
        ? monthEntries.first.path
        : null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF042448), Color(0xFF021A35), Color(0xFF000D20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Transform.translate(
                        offset: const Offset(-8, 0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 40,
                                  height: 40,
                                ),
                                icon: const Icon(
                                  Icons.chevron_left_rounded,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Expanded(
                              child: Text(
                                '変化の記録',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFF3F6FB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: Transform.translate(
                          offset: const Offset(0, -3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _goToPreviousMonth,
                                icon: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${selectedMonth.year}年${selectedMonth.month}月',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE9EEF7),
                                ),
                              ),
                              IconButton(
                                onPressed: _goToNextMonth,
                                icon: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Transform.translate(
                        offset: const Offset(0, -3),
                        child: _ProgressSummaryCard(
                          overallText: overallText,
                          potentialText: potentialText,
                          potentialDeltaText: potentialDeltaText,
                          hasScores: hasScores,
                          overallScore: overallScore,
                          potentialScore: potentialScore,
                          imagePath: selectedMonthLatestImagePath,
                          onChevronTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => _GrowthBlankScreen(
                                  monthlyScores: widget.monthlyScores,
                                ),
                              ),
                            );
                          },
                          showChevron: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.only(bottom: 140),
                        itemCount: monthEntries.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 0,
                              mainAxisSpacing: 0,
                              childAspectRatio: 0.9,
                            ),
                        itemBuilder: (BuildContext context, int index) {
                          final _FrontImageEntry entry = monthEntries[index];
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              final _MonthlyScore openScore =
                                  _scoreForMonth(_selectedMonthIndex) ??
                                  _MonthlyScore(
                                    overallAvg: widget.overallScore,
                                    potentialAvg: widget.potentialScore,
                                    hasData: widget.hasScores,
                                  );
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => FaceAnalysisResultScreen(
                                    imagePath: entry.path,
                                    sideImagePath: entry.sidePath,
                                    result: _resultForScore(openScore),
                                    persistSummary: false,
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(File(entry.path), fit: BoxFit.cover),
                                Positioned(
                                  right: 9,
                                  bottom: 8,
                                  child: Text(
                                    _dateText(entry.addedAt),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.45,
                                          ),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const _FloatingAddButton(bottom: 112),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrowthBlankScreen extends StatefulWidget {
  const _GrowthBlankScreen({required this.monthlyScores});

  final Map<String, _MonthlyScore> monthlyScores;

  @override
  State<_GrowthBlankScreen> createState() => _GrowthBlankScreenState();
}

class _GrowthBlankScreenState extends State<_GrowthBlankScreen> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  void _changeYear(int delta) {
    setState(() {
      _year += delta;
    });
  }

  _MonthlyScore? _scoreForMonth(int year, int month) {
    final String key = '$year-${month.toString().padLeft(2, '0')}';
    final _MonthlyScore? score = widget.monthlyScores[key];
    if (score == null || !score.hasData) return null;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF042448), Color(0xFF021A35), Color(0xFF000D20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'あなたの推移',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFF3F6FB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _changeYear(-1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$_year年',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF3F6FB),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _changeYear(1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                        icon: const Icon(
                          Icons.chevron_right_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final double crossSpacing = 8;
                      final double mainSpacing = 8;
                      final double gridHeight = constraints.maxHeight * 0.9;
                      final double tileHeight =
                          (gridHeight - (mainSpacing * 5)) / 6;
                      final double tileWidth =
                          (constraints.maxWidth - crossSpacing) / 2;
                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          height: gridHeight,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 12,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: crossSpacing,
                                  mainAxisSpacing: mainSpacing,
                                  childAspectRatio: tileWidth / tileHeight,
                                ),
                            itemBuilder: (BuildContext context, int index) {
                              final int month = index + 1;
                              final _MonthlyScore? monthScore = _scoreForMonth(
                                _year,
                                month,
                              );
                              final bool hasData = monthScore != null;
                              final int? overall = monthScore?.overallAvg;
                              final int? potential = monthScore?.potentialAvg;
                              final int? delta =
                                  (overall != null && potential != null)
                                  ? (potential - overall)
                                  : null;
                              final String overallText =
                                  overall?.toString() ?? '-';
                              final String potentialText =
                                  potential?.toString() ?? '-';
                              final String? deltaText =
                                  delta == null || delta == 0
                                  ? null
                                  : (delta > 0 ? '+$delta' : '$delta');
                              final double overallProgress =
                                  ((overall ?? 0) / 100).clamp(0.0, 1.0);
                              final double potentialWidthFactor =
                                  ((potential ?? 0) - (overall ?? 0)).clamp(
                                    0,
                                    100,
                                  ) /
                                  100;

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1E2A3E,
                                  ).withValues(alpha: 0.56),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.16),
                                  ),
                                  boxShadow: null,
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  8,
                                  10,
                                  8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$month月',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFB9C0CF),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (!hasData)
                                      const Expanded(
                                        child: Center(
                                          child: Text(
                                            '-',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF8190A9),
                                            ),
                                          ),
                                        ),
                                      )
                                    else ...[
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            overallText,
                                            style: const TextStyle(
                                              fontSize: 30,
                                              height: 1,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFFF3F6FB),
                                            ),
                                          ),
                                          const Spacer(),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                potentialText,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  height: 1,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFFD6DDF0),
                                                ),
                                              ),
                                              if (deltaText != null)
                                                Text(
                                                  deltaText,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF9C73FF),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: SizedBox(
                                          height: 4,
                                          child: LayoutBuilder(
                                            builder:
                                                (
                                                  BuildContext context,
                                                  BoxConstraints constraints,
                                                ) {
                                                  final double total =
                                                      constraints.maxWidth;
                                                  final double overallWidth =
                                                      total * overallProgress;
                                                  final double potentialWidth =
                                                      total *
                                                      potentialWidthFactor;
                                                  return Stack(
                                                    children: [
                                                      Container(
                                                        color:
                                                            const Color(
                                                              0xFFD5DAE2,
                                                            ).withValues(
                                                              alpha: 0.45,
                                                            ),
                                                      ),
                                                      Container(
                                                        width: overallWidth,
                                                        decoration:
                                                            const BoxDecoration(
                                                              gradient: LinearGradient(
                                                                colors: <Color>[
                                                                  Color(
                                                                    0xFF7CC5EA,
                                                                  ),
                                                                  Color(
                                                                    0xFF2C59E2,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                      ),
                                                      if (potentialWidth > 0)
                                                        Positioned(
                                                          left: overallWidth,
                                                          child: Container(
                                                            width:
                                                                potentialWidth,
                                                            height: 4,
                                                            decoration: const BoxDecoration(
                                                              gradient: LinearGradient(
                                                                colors: <Color>[
                                                                  Color(
                                                                    0xFF8A4DFF,
                                                                  ),
                                                                  Color(
                                                                    0xFF5A16F4,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingAddButton extends StatelessWidget {
  const _FloatingAddButton({this.bottom = 50, this.onPressed});

  final double bottom;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 44,
      bottom: bottom,
      child: SizedBox(
        width: 66,
        height: 66,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEDEDED),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed ?? () {},
            icon: const Icon(Icons.add_rounded, size: 34, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

String _dateText(DateTime date) {
  final String y = date.year.toString().padLeft(4, '0');
  final String m = date.month.toString().padLeft(2, '0');
  final String d = date.day.toString().padLeft(2, '0');
  return '$y/$m/$d';
}

class _FrontImageEntry {
  const _FrontImageEntry({
    required this.path,
    required this.addedAt,
    this.sidePath,
  });

  final String path;
  final String? sidePath;
  final DateTime addedAt;
}

class _MonthlyScore {
  const _MonthlyScore({
    required this.overallAvg,
    required this.potentialAvg,
    required this.hasData,
  });

  final int overallAvg;
  final int potentialAvg;
  final bool hasData;
}

class _HabitItem {
  const _HabitItem({
    required this.id,
    required this.title,
    this.goal = '',
    this.achievedDays = 0,
    this.lastAchievedDate = '',
    this.achievedDates = const <String>[],
    required this.emoji,
    required this.isDone,
  });

  final String id;
  final String title;
  final String goal;
  final int achievedDays;
  final String lastAchievedDate;
  final List<String> achievedDates;
  final String emoji;
  final bool isDone;

  _HabitItem copyWith({
    String? id,
    String? title,
    String? goal,
    int? achievedDays,
    String? lastAchievedDate,
    List<String>? achievedDates,
    String? emoji,
    bool? isDone,
  }) {
    return _HabitItem(
      id: id ?? this.id,
      title: title ?? this.title,
      goal: goal ?? this.goal,
      achievedDays: achievedDays ?? this.achievedDays,
      lastAchievedDate: lastAchievedDate ?? this.lastAchievedDate,
      achievedDates: achievedDates ?? this.achievedDates,
      emoji: emoji ?? this.emoji,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'goal': goal,
    'achievedDays': achievedDays,
    'lastAchievedDate': lastAchievedDate,
    'achievedDates': achievedDates,
    'emoji': emoji,
    'isDone': isDone,
  };

  static _HabitItem fromJson(Map<String, dynamic> json) {
    final List<String> parsedDates =
        (json['achievedDates'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic e) => e.toString())
            .where((String e) => e.isNotEmpty)
            .toList();
    return _HabitItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      goal: (json['goal'] ?? '').toString(),
      achievedDays:
          (json['achievedDays'] is num ? json['achievedDays'] as num : 0)
              .toInt(),
      lastAchievedDate: (json['lastAchievedDate'] ?? '').toString(),
      achievedDates: parsedDates,
      emoji: (json['emoji'] ?? '✨').toString(),
      isDone: json['isDone'] == true,
    );
  }
}

class _ProgressSummaryCard extends StatelessWidget {
  const _ProgressSummaryCard({
    required this.overallText,
    required this.potentialText,
    required this.potentialDeltaText,
    required this.hasScores,
    required this.overallScore,
    required this.potentialScore,
    required this.imagePath,
    required this.onChevronTap,
    required this.showChevron,
  });

  final String overallText;
  final String potentialText;
  final String? potentialDeltaText;
  final bool hasScores;
  final int overallScore;
  final int potentialScore;
  final String? imagePath;
  final VoidCallback? onChevronTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3E).withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF2B3A51),
            backgroundImage: imagePath != null
                ? FileImage(File(imagePath!))
                : null,
            child: imagePath == null
                ? const Icon(
                    Icons.person_rounded,
                    color: Color(0xFFB9C5D9),
                    size: 30,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricGroup(title: '総合スコア', value: overallText),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricGroup(
                        title: 'ポテンシャル',
                        value: potentialText,
                        suffix: potentialDeltaText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.91,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 10,
                        child: LayoutBuilder(
                          builder:
                              (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                if (!hasScores) {
                                  return Container(
                                    color: const Color(
                                      0xFF9098A8,
                                    ).withValues(alpha: 0.45),
                                  );
                                }
                                final double overallProgress =
                                    (overallScore / 100)
                                        .clamp(0.0, 1.0)
                                        .toDouble();
                                final double potentialProgress =
                                    (potentialScore / 100)
                                        .clamp(0.0, 1.0)
                                        .toDouble();
                                final double overallWidth =
                                    constraints.maxWidth * overallProgress;
                                final double potentialWidth =
                                    constraints.maxWidth *
                                    (potentialProgress - overallProgress).clamp(
                                      0.0,
                                      1.0,
                                    );
                                return Stack(
                                  children: [
                                    Container(color: const Color(0xFFD5DAE2)),
                                    Container(
                                      width: overallWidth,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: <Color>[
                                            Color(0xFF7CC5EA),
                                            Color(0xFF2C59E2),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (potentialWidth > 0)
                                      Positioned(
                                        left: overallWidth,
                                        child: Container(
                                          width: potentialWidth,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: <Color>[
                                                Color(0xFF8A4DFF),
                                                Color(0xFF5A16F4),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (potentialWidth > 0)
                                      Positioned(
                                        left: (overallWidth - 1).clamp(
                                          0.0,
                                          constraints.maxWidth,
                                        ),
                                        child: Container(
                                          width: 1,
                                          height: 10,
                                          color: Colors.white.withValues(
                                            alpha: 0.75,
                                          ),
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
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: showChevron
                ? IconButton(
                    onPressed: onChevronTap,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withValues(
                        alpha: onChevronTap != null ? 1 : 0.35,
                      ),
                      size: 38,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MetricGroup extends StatelessWidget {
  const _MetricGroup({required this.title, required this.value, this.suffix});

  final String title;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 1),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE9EEF7),
          ),
        ),
        const SizedBox(height: 2),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 6,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1,
                color: Colors.white,
              ),
            ),
            if (suffix != null)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 5),
                child: Text(
                  suffix!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9AA8BE),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
