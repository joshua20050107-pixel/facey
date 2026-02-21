import 'dart:io';
import 'dart:convert';

import 'package:facey/screens/face_analysis_result_screen.dart';
import 'package:flutter/material.dart';
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

  int? _overallScore;
  int? _potentialScore;
  String? _latestFrontImagePath;
  List<_FrontImageEntry> _frontImageHistory = <_FrontImageEntry>[];
  Map<String, _MonthlyScore> _monthlyScores = <String, _MonthlyScore>{};

  @override
  void initState() {
    super.initState();
    _loadLatestScores();
  }

  void _loadLatestScores() {
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
    if (!mounted) return;
    setState(() {
      _overallScore = overallParsed?.clamp(0, 100);
      _potentialScore = potentialParsed?.clamp(0, 100);
      _latestFrontImagePath = hasLatestImage ? latestFrontPath : null;
      _frontImageHistory = history;
      _monthlyScores = monthlyScores;
    });
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
                  padding: const EdgeInsets.only(bottom: 160),
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
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE9EEF7),
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
        const _FloatingAddButton(),
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
            colors: [Color(0xFF10151D), Color(0xFF222C3B), Color(0xFF364B68)],
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
                          offset: const Offset(0, -8),
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
                        offset: const Offset(0, -8),
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
                                builder: (_) => const _GrowthBlankScreen(),
                              ),
                            );
                          },
                          showChevron: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
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

class _GrowthBlankScreen extends StatelessWidget {
  const _GrowthBlankScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF10151D), Color(0xFF222C3B), Color(0xFF364B68)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingAddButton extends StatelessWidget {
  const _FloatingAddButton({this.bottom = 50});

  final double bottom;

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
            onPressed: () {},
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
