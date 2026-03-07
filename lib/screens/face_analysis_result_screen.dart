import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

import '../services/facey_api_service.dart';
import '../services/scan_flow_haptics.dart';

class ImageViewerRoute<T> extends PageRoute<T> {
  ImageViewerRoute({
    required this.page,
    required Duration transitionDuration,
    required Duration reverseTransitionDuration,
    bool useFadeTransition = true,
  }) : _transitionDuration = transitionDuration,
       _reverseTransitionDuration = reverseTransitionDuration,
       _useFadeTransition = useFadeTransition;

  final Widget page;
  final Duration _transitionDuration;
  Duration _reverseTransitionDuration;
  final bool _useFadeTransition;

  void setReverseDuration(Duration duration) {
    _reverseTransitionDuration = duration;
  }

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _transitionDuration;

  @override
  Duration get reverseTransitionDuration => _reverseTransitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return page;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!_useFadeTransition) return child;
    return FadeTransition(opacity: animation, child: child);
  }
}

Route<void> imageViewerRouteSwipe(Widget page) {
  return ImageViewerRoute<void>(
    page: page,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 200),
  );
}

Route<void> imageViewerRouteClose(Widget page) {
  return ImageViewerRoute<void>(
    page: page,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    useFadeTransition: false,
  );
}

class FaceMetricScore {
  const FaceMetricScore({required this.label, required this.value});

  final String label;
  final int value;
}

class FaceAnalysisResult {
  const FaceAnalysisResult({
    required this.overall,
    required this.metrics,
    this.detailMetrics = const <FaceMetricScore>[],
    this.strengthsSummary = '',
    this.improvementsSummary = '',
    this.nextAction = '',
  });

  final int overall;
  final List<FaceMetricScore> metrics;
  final List<FaceMetricScore> detailMetrics;
  final String strengthsSummary;
  final String improvementsSummary;
  final String nextAction;

  factory FaceAnalysisResult.dummy() {
    return const FaceAnalysisResult(
      overall: 20,
      metrics: <FaceMetricScore>[
        FaceMetricScore(label: 'ポテンシャル', value: 40),
        FaceMetricScore(label: '性的魅力', value: 93),
        FaceMetricScore(label: '印象', value: 91),
        FaceMetricScore(label: '清潔感', value: 89),
        FaceMetricScore(label: '骨格', value: 88),
        FaceMetricScore(label: '肌', value: 86),
      ],
    );
  }
}

class FaceAnalysisResultScreen extends StatefulWidget {
  const FaceAnalysisResultScreen({
    super.key,
    required this.imagePath,
    this.sideImagePath,
    this.result,
    this.persistSummary = true,
  });

  final String imagePath;
  final String? sideImagePath;

  // AI導線用: 後でAPIレスポンスをここへ渡せばUIはそのまま使える。
  final FaceAnalysisResult? result;
  final bool persistSummary;

  @override
  State<FaceAnalysisResultScreen> createState() =>
      _FaceAnalysisResultScreenState();
}

class _FaceAnalysisResultScreenState extends State<FaceAnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  static const String _prefsBoxName = 'app_prefs';
  static const String _genderKey = 'selected_gender';
  static const String _latestResultCardImageKey = 'latest_result_card_image';
  static const String _latestResultOverallScoreKey =
      'latest_result_overall_score';
  static const String _latestResultPotentialScoreKey =
      'latest_result_potential_score';
  static const String _latestResultAnalysisJsonKey =
      'latest_result_analysis_json';
  static const String _latestResultAnalysisFrontPathKey =
      'latest_result_analysis_front_path';
  static const String _latestResultAnalysisSidePathKey =
      'latest_result_analysis_side_path';
  static const String _resultAnalysisByFrontPathKey =
      'result_analysis_by_front_path';
  static const String _resultOverallSumKey = 'result_overall_sum';
  static const String _resultPotentialSumKey = 'result_potential_sum';
  static const String _resultCountKey = 'result_count';
  static const String _lastAggregatedResultIdKey = 'last_aggregated_result_id';
  static const String _resultFrontImageHistoryKey =
      'result_front_image_history';
  static const String _resultFrontImageHistoryMetaKey =
      'result_front_image_history_meta';
  static const String _resultMonthlyScoresKey = 'result_monthly_scores';
  static const List<String> _primaryMetricLabels = <String>[
    'ポテンシャル',
    '性的魅力',
    '印象',
    '清潔感',
    '骨格',
    '肌',
  ];
  static const List<String> _detailMetricLabels = <String>[
    '男性らしさ',
    '自信',
    '親しみやすさ',
    '髪の毛',
    'シャープさ',
    '目力',
    '顎ライン',
    '眉',
  ];
  static const double _resultCardHeight = 500;
  static const int _resultPageCount = 7;
  int _currentPageIndex = 0;
  final List<GlobalKey> _pageCaptureKeys = List<GlobalKey>.generate(
    _resultPageCount,
    (_) => GlobalKey(),
  );
  late final AnimationController _flipController;
  late String _cardBackImagePath;
  bool _didPersistLatestCardThumbnail = false;
  FaceAnalysisResult? _apiResult;
  bool _isApiLoading = false;
  String? _apiResultError;

  Future<Uint8List?> _captureCardAsPng({int? pageIndex}) async {
    final int targetIndex = (pageIndex ?? _currentPageIndex).clamp(
      0,
      _pageCaptureKeys.length - 1,
    );
    final GlobalKey captureKey = _pageCaptureKeys[targetIndex];
    for (int i = 0; i < 8; i++) {
      await SchedulerBinding.instance.endOfFrame;
      final RenderObject? renderObject = captureKey.currentContext
          ?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) continue;
      if (!renderObject.attached || renderObject.debugNeedsPaint) continue;
      try {
        final ui.Image image = await renderObject.toImage(pixelRatio: 3);
        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData == null) continue;
        return byteData.buffer.asUint8List();
      } on AssertionError {
        // Render state can change between checks; retry on next frame.
        continue;
      }
    }
    return null;
  }

  Future<void> _saveCardToGallery() async {
    ScanFlowHaptics.secondary();
    try {
      final Uint8List? bytes = await _captureCardAsPng();
      if (bytes == null || !mounted) return;
      await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'facey_result_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('結果カードを保存しました')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存に失敗しました')));
    }
  }

  Future<void> _shareCardImage() async {
    ScanFlowHaptics.secondary();
    try {
      final Uint8List? bytes = await _captureCardAsPng();
      if (bytes == null) return;
      final Directory tempDir = await getTemporaryDirectory();
      final String path =
          '${tempDir.path}/facey_card_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(path)], text: 'Faceyの解析結果');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('共有に失敗しました')));
    }
  }

  Future<void> _persistLatestCardThumbnail() async {
    if (_didPersistLatestCardThumbnail || !mounted) return;
    for (int i = 0; i < 8; i++) {
      final Uint8List? bytes = await _captureCardAsPng(pageIndex: 0);
      if (bytes != null && bytes.isNotEmpty) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final Directory imageDir = Directory('${appDir.path}/analysis_results');
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }
        final String path = '${imageDir.path}/facey_latest_result_card.png';
        final File file = File(path);
        await file.writeAsBytes(bytes, flush: true);
        final Box<String> box = Hive.box<String>(_prefsBoxName);
        await box.put(_latestResultCardImageKey, path);
        _didPersistLatestCardThumbnail = true;
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  Future<void> _persistLatestSummaryScores(FaceAnalysisResult viewData) async {
    final List<FaceMetricScore> metrics = List<FaceMetricScore>.from(
      viewData.metrics,
    );
    if (metrics.isEmpty) return;
    final int overallScore = viewData.overall.clamp(0, 100);
    final int potentialScore = metrics.first.value.clamp(0, 100);
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    await box.put(_latestResultOverallScoreKey, overallScore.toString());
    await box.put(_latestResultPotentialScoreKey, potentialScore.toString());

    final String resultId = '${widget.imagePath}|$overallScore|$potentialScore';
    final String? lastAggregatedId = box.get(_lastAggregatedResultIdKey);
    if (lastAggregatedId == resultId) return;

    final int currentOverallSum =
        int.tryParse(box.get(_resultOverallSumKey) ?? '') ?? 0;
    final int currentPotentialSum =
        int.tryParse(box.get(_resultPotentialSumKey) ?? '') ?? 0;
    final int currentCount = int.tryParse(box.get(_resultCountKey) ?? '') ?? 0;

    await box.put(
      _resultOverallSumKey,
      (currentOverallSum + overallScore).toString(),
    );
    await box.put(
      _resultPotentialSumKey,
      (currentPotentialSum + potentialScore).toString(),
    );
    await box.put(_resultCountKey, (currentCount + 1).toString());
    await box.put(_lastAggregatedResultIdKey, resultId);

    final DateTime now = DateTime.now();
    final String monthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final String monthlyRaw = box.get(_resultMonthlyScoresKey) ?? '{}';
    Map<String, dynamic> monthlyMap;
    try {
      monthlyMap = Map<String, dynamic>.from(
        jsonDecode(monthlyRaw) as Map<String, dynamic>,
      );
    } catch (_) {
      monthlyMap = <String, dynamic>{};
    }
    final Map<String, dynamic> monthData = Map<String, dynamic>.from(
      monthlyMap[monthKey] as Map? ?? <String, dynamic>{},
    );
    final int monthOverallSum =
        (monthData['overallSum'] is num ? monthData['overallSum'] as num : 0)
            .toInt();
    final int monthPotentialSum =
        (monthData['potentialSum'] is num
                ? monthData['potentialSum'] as num
                : 0)
            .toInt();
    final int monthCount =
        (monthData['count'] is num ? monthData['count'] as num : 0).toInt();
    monthlyMap[monthKey] = <String, dynamic>{
      'overallSum': monthOverallSum + overallScore,
      'potentialSum': monthPotentialSum + potentialScore,
      'count': monthCount + 1,
    };
    await box.put(_resultMonthlyScoresKey, jsonEncode(monthlyMap));

    final String historyRaw = box.get(_resultFrontImageHistoryKey) ?? '';
    final List<String> history = historyRaw
        .split('\n')
        .where((String p) => p.isNotEmpty)
        .toList();
    history.remove(widget.imagePath);
    history.insert(0, widget.imagePath);
    if (history.length > 120) {
      history.removeRange(120, history.length);
    }
    await box.put(_resultFrontImageHistoryKey, history.join('\n'));

    final String metaRaw = box.get(_resultFrontImageHistoryMetaKey) ?? '[]';
    List<dynamic> metaList;
    try {
      metaList = jsonDecode(metaRaw) as List<dynamic>;
    } catch (_) {
      metaList = <dynamic>[];
    }
    final List<Map<String, dynamic>> normalized = metaList
        .whereType<Map<String, dynamic>>()
        .toList();
    normalized.removeWhere((Map<String, dynamic> item) {
      return item['path'] == widget.imagePath;
    });
    final Map<String, dynamic> metaItem = <String, dynamic>{
      'path': widget.imagePath,
      'addedAt': DateTime.now().toIso8601String(),
    };
    if (widget.sideImagePath != null && widget.sideImagePath!.isNotEmpty) {
      metaItem['sidePath'] = widget.sideImagePath;
    }
    normalized.insert(0, metaItem);
    if (normalized.length > 120) {
      normalized.removeRange(120, normalized.length);
    }
    await box.put(_resultFrontImageHistoryMetaKey, jsonEncode(normalized));
  }

  Map<String, dynamic> _encodeResult(FaceAnalysisResult result) {
    return <String, dynamic>{
      'overall': result.overall,
      'metrics': result.metrics
          .map(
            (FaceMetricScore metric) => <String, dynamic>{
              'label': metric.label,
              'value': metric.value,
            },
          )
          .toList(),
      'detailMetrics': result.detailMetrics
          .map(
            (FaceMetricScore metric) => <String, dynamic>{
              'label': metric.label,
              'value': metric.value,
            },
          )
          .toList(),
      'strengthsSummary': result.strengthsSummary,
      'improvementsSummary': result.improvementsSummary,
      'nextAction': result.nextAction,
    };
  }

  Future<void> _persistLatestAnalysis(FaceAnalysisResult result) async {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    final Map<String, dynamic> encoded = _encodeResult(result);
    await box.put(_latestResultAnalysisFrontPathKey, widget.imagePath);
    if (widget.sideImagePath != null && widget.sideImagePath!.isNotEmpty) {
      await box.put(_latestResultAnalysisSidePathKey, widget.sideImagePath!);
    } else {
      await box.delete(_latestResultAnalysisSidePathKey);
    }
    await box.put(_latestResultAnalysisJsonKey, jsonEncode(encoded));

    final String rawByPath = box.get(_resultAnalysisByFrontPathKey) ?? '{}';
    Map<String, dynamic> byPath;
    try {
      byPath = Map<String, dynamic>.from(
        jsonDecode(rawByPath) as Map<String, dynamic>,
      );
    } catch (_) {
      byPath = <String, dynamic>{};
    }
    byPath[widget.imagePath] = encoded;
    await box.put(_resultAnalysisByFrontPathKey, jsonEncode(byPath));
  }

  FaceAnalysisResult? _loadPersistedAnalysisForCurrentImage() {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    final String? frontPath = box.get(_latestResultAnalysisFrontPathKey);
    if (frontPath != widget.imagePath) return null;

    final String currentSide = widget.sideImagePath ?? '';
    final String savedSide = box.get(_latestResultAnalysisSidePathKey) ?? '';
    if (currentSide != savedSide) return null;

    final String raw = box.get(_latestResultAnalysisJsonKey) ?? '';
    if (raw.isEmpty) return null;
    try {
      final Map<String, dynamic> map = Map<String, dynamic>.from(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return _parseHomeAnalysis(map);
    } catch (_) {
      return null;
    }
  }

  int _toScore(Object? value, int fallback) {
    final int parsed = switch (value) {
      int v => v,
      double v => v.round(),
      String v => int.tryParse(v) ?? fallback,
      _ => fallback,
    };
    return parsed.clamp(0, 100);
  }

  List<FaceMetricScore> _parseMetricList(
    Object? raw,
    List<String> fallbackLabels,
  ) {
    final List<dynamic> list = raw is List<dynamic> ? raw : <dynamic>[];
    return List<FaceMetricScore>.generate(fallbackLabels.length, (int index) {
      final Object? item = index < list.length ? list[index] : null;
      final Map<String, dynamic> map = item is Map<String, dynamic>
          ? item
          : <String, dynamic>{};
      final String label = (map['label'] ?? fallbackLabels[index])
          .toString()
          .trim();
      final int value = _toScore(map['value'], 50);
      return FaceMetricScore(
        label: label.isEmpty ? fallbackLabels[index] : label,
        value: value,
      );
    });
  }

  FaceAnalysisResult _parseHomeAnalysis(Map<String, dynamic> json) {
    const List<String> primaryLabels = <String>[
      'ポテンシャル',
      '性的魅力',
      '印象',
      '清潔感',
      '骨格',
      '肌',
    ];
    const List<String> detailLabels = <String>[
      '男性らしさ',
      '自信',
      '親しみやすさ',
      '髪の毛',
      'シャープさ',
      '目力',
      '顎ライン',
      '眉',
    ];
    final int overall = _toScore(json['overall'], 50);
    final List<FaceMetricScore> metrics = _parseMetricList(
      json['metrics'],
      primaryLabels,
    );
    final List<FaceMetricScore> detailMetrics = _parseMetricList(
      json['detailMetrics'],
      detailLabels,
    );
    final String strengthsSummary = (json['strengthsSummary'] ?? '')
        .toString()
        .trim();
    final String improvementsSummary = (json['improvementsSummary'] ?? '')
        .toString()
        .trim();
    final String nextAction = (json['nextAction'] ?? '').toString().trim();

    return FaceAnalysisResult(
      overall: overall,
      metrics: metrics,
      detailMetrics: detailMetrics,
      strengthsSummary: strengthsSummary,
      improvementsSummary: improvementsSummary,
      nextAction: nextAction,
    );
  }

  Future<void> _loadHomeAnalysis() async {
    if (widget.result != null) return;
    final FaceAnalysisResult? cached = _loadPersistedAnalysisForCurrentImage();
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _apiResult = cached;
        _isApiLoading = false;
        _apiResultError = null;
      });
      return;
    }
    if (!widget.persistSummary) {
      if (!mounted) return;
      setState(() {
        _apiResult = null;
        _isApiLoading = false;
        _apiResultError = '保存済みの解析結果が見つかりません。';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _isApiLoading = true;
      _apiResultError = null;
    });
    try {
      final Uint8List frontImageBytes = await File(
        widget.imagePath,
      ).readAsBytes();
      final Uint8List? sideImageBytes =
          widget.sideImagePath != null && widget.sideImagePath!.isNotEmpty
          ? await File(widget.sideImagePath!).readAsBytes()
          : null;
      final String gender = _isFemaleSelected() ? 'female' : 'male';
      final Map<String, dynamic> analysis = await FaceyApiService.analyzeHome(
        frontImageBytes: frontImageBytes,
        sideImageBytes: sideImageBytes,
        gender: gender,
      );
      final FaceAnalysisResult parsed = _parseHomeAnalysis(analysis);
      if (!mounted) return;
      setState(() {
        _apiResult = parsed;
        _isApiLoading = false;
        _apiResultError = null;
      });
      if (widget.persistSummary) {
        unawaited(_persistLatestSummaryScores(parsed));
        unawaited(_persistLatestAnalysis(parsed));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apiResult = null;
        _isApiLoading = false;
        _apiResultError = '解析APIの取得に失敗しました。';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cardBackImagePath = widget.imagePath;
    unawaited(_loadHomeAnalysis());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.persistSummary) return;
      _persistLatestCardThumbnail();
      final FaceAnalysisResult? resolved = widget.result ?? _apiResult;
      if (resolved != null) {
        unawaited(_persistLatestSummaryScores(resolved));
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCardFlip() {
    if (_flipController.isAnimating) return;
    if (_flipController.value >= 0.5) {
      _flipController.reverse();
      return;
    }
    _flipController.forward();
  }

  Future<void> _showBackImagePreview() async {
    if (_flipController.value < 0.5) return;
    final List<String> previewImagePaths = <String>[
      _cardBackImagePath,
      widget.imagePath,
      if (widget.sideImagePath != null) widget.sideImagePath!,
    ];
    final List<String> uniquePreviewImagePaths = <String>[];
    for (final String path in previewImagePaths) {
      if (!uniquePreviewImagePaths.contains(path)) {
        uniquePreviewImagePaths.add(path);
      }
    }
    await Navigator.of(context).push<void>(
      imageViewerRouteClose(
        BackImagePreviewScreen(
          previewImagePaths: uniquePreviewImagePaths,
          heroTagForPath: _heroTagForPath,
          onWillClose: (String selectedPath) {
            if (!mounted || _cardBackImagePath == selectedPath) return;
            setState(() {
              _cardBackImagePath = selectedPath;
            });
          },
        ),
      ),
    );
  }

  String _heroTagForPath(String path) => 'face_analysis_preview_$path';

  bool _isFemaleSelected() {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    return box.get(_genderKey) == 'female';
  }

  Widget _buildResultCardFrame({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(14, 14, 14, 14),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F14),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      clipBehavior: Clip.antiAlias,
      padding: padding,
      child: child,
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: SizedBox(
        height: 66,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(33),
          ),
          child: TextButton.icon(
            onPressed: onTap,
            style: TextButton.styleFrom(
              iconAlignment: IconAlignment.end,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(33),
              ),
            ),
            icon: Icon(icon, size: 24, color: const Color(0xFF111216)),
            label: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF111216),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardWithFaceyOverlay(Widget card) {
    return Stack(
      fit: StackFit.expand,
      children: [
        card,
        const Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Text(
              'facey',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8A8A8A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final FaceAnalysisResult? resolvedResult = widget.result ?? _apiResult;
    if (resolvedResult == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              ScanFlowHaptics.back();
              Navigator.of(context).pop();
            },
            child: const Center(child: Icon(Icons.close_rounded, size: 34)),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(widget.imagePath), fit: BoxFit.cover),
            ColoredBox(color: Colors.black.withValues(alpha: 0.9)),
            Center(
              child: _isApiLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _apiResultError ?? '解析結果を取得できませんでした。',
                          style: const TextStyle(
                            color: Color(0xFFFFCDD2),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _loadHomeAnalysis,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }
    final FaceAnalysisResult viewData = resolvedResult;
    final List<FaceMetricScore> metrics = List<FaceMetricScore>.generate(
      _primaryMetricLabels.length,
      (int index) => FaceMetricScore(
        label: _primaryMetricLabels[index],
        value: index < viewData.metrics.length
            ? viewData.metrics[index].value.clamp(0, 100)
            : 50,
      ),
    );
    final List<FaceMetricScore> secondPageMetrics =
        List<FaceMetricScore>.generate(
          _detailMetricLabels.length,
          (int index) => FaceMetricScore(
            label: _detailMetricLabels[index],
            value: index < viewData.detailMetrics.length
                ? viewData.detailMetrics[index].value.clamp(0, 100)
                : 50,
          ),
        );
    final int potentialScore = metrics.first.value.clamp(0, 100);
    final int potentialDeltaFromOverall = potentialScore - viewData.overall;
    final String potentialDeltaText = potentialDeltaFromOverall >= 0
        ? '+$potentialDeltaFromOverall'
        : '$potentialDeltaFromOverall';
    final int betterThan = (viewData.overall + 20).clamp(0, 99).toInt();
    final int potentialBetterThan = (potentialScore + 2).clamp(0, 99).toInt();
    final String strengthsSummary = viewData.strengthsSummary.isNotEmpty
        ? viewData.strengthsSummary
        : '目元にやわらかい印象があり、親しみやすさがしっかり出ています。\n鼻筋と輪郭のバランスが良く、正面から見たときに顔立ちが整って見えるタイプです。\n口元も清潔感があり、全体として好印象につながる顔立ちです。';
    final String improvementsSummary = viewData.improvementsSummary.isNotEmpty
        ? viewData.improvementsSummary
        : '輪郭はすでに整っているので、次は肌の質感を上げると全体の印象がさらに伸びます。\n眉の形をほんの少しだけ整えると、目元の強さが自然に引き立ちます。\n髪型は額まわりに軽さを作ると、顔全体がよりシャープに見えます。';
    final String nextAction = viewData.nextAction.isNotEmpty
        ? viewData.nextAction
        : '明日から1週間は朝と夜の保湿を固定し、肌の質感を安定させましょう。次のヘアカットでは前髪を少し軽めにし、サイドのボリュームを抑えると全体のバランスが整います。眉は上ラインを触りすぎず下側の産毛だけを整えることで、目元を自然にシャープに見せられます。';
    final int visiblePageCount = 7;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ScanFlowHaptics.back();
            Navigator.of(context).pop();
          },
          child: const Center(child: Icon(Icons.close_rounded, size: 34)),
        ),
        title: Transform.translate(
          offset: Offset(0, 2),
          child: Text(
            '総合評価',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w700,
              fontFamily: 'Hiragino Sans',
              letterSpacing: 1,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/images/keke.png',
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(widget.imagePath), fit: BoxFit.cover),
          ColoredBox(color: Colors.black.withValues(alpha: 0.9)),
          SafeArea(
            child: Transform.translate(
              offset: const Offset(0, 20),
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      onPageChanged: (int index) {
                        setState(() {
                          _currentPageIndex = index;
                        });
                      },
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          child: Column(
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -8),
                                child: Align(
                                  alignment: const Alignment(0, -0.02),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 392,
                                    ),
                                    child: RepaintBoundary(
                                      key: _pageCaptureKeys[0],
                                      child: GestureDetector(
                                        onTap: _toggleCardFlip,
                                        onLongPress: _showBackImagePreview,
                                        child: AnimatedBuilder(
                                          animation: _flipController,
                                          builder: (BuildContext context, _) {
                                            final double angle =
                                                _flipController.value * math.pi;
                                            final bool showFront =
                                                angle <= (math.pi / 2);
                                            final Widget frontCardContent =
                                                Column(
                                                  children: [
                                                    _OverallHeaderSection(
                                                      imagePath:
                                                          widget.imagePath,
                                                      score: viewData.overall,
                                                      title: '総合スコア',
                                                    ),
                                                    const SizedBox(height: 22),
                                                    _MetricPairCard(
                                                      left: metrics[0],
                                                      right: metrics[1],
                                                      potentialDeltaText:
                                                          potentialDeltaText,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    _MetricPairCard(
                                                      left: metrics[2],
                                                      right: metrics[3],
                                                      potentialDeltaText:
                                                          potentialDeltaText,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    _MetricPairCard(
                                                      left: metrics[4],
                                                      right: metrics[5],
                                                      potentialDeltaText:
                                                          potentialDeltaText,
                                                    ),
                                                    const SizedBox(height: 4),
                                                  ],
                                                );

                                            return Transform(
                                              alignment: Alignment.center,
                                              transform: Matrix4.identity()
                                                ..setEntry(3, 2, 0.0012)
                                                ..rotateY(angle),
                                              child: SizedBox(
                                                height: _resultCardHeight,
                                                child: showFront
                                                    ? _buildCardWithFaceyOverlay(
                                                        _buildResultCardFrame(
                                                          child:
                                                              frontCardContent,
                                                        ),
                                                      )
                                                    : Transform(
                                                        alignment:
                                                            Alignment.center,
                                                        transform:
                                                            Matrix4.identity()
                                                              ..rotateY(
                                                                math.pi,
                                                              ),
                                                        child: _buildResultCardFrame(
                                                          child: Stack(
                                                            children: [
                                                              Opacity(
                                                                opacity: 0,
                                                                child:
                                                                    frontCardContent,
                                                              ),
                                                              Positioned.fill(
                                                                child: Stack(
                                                                  fit: StackFit
                                                                      .expand,
                                                                  children: [
                                                                    Hero(
                                                                      tag: _heroTagForPath(
                                                                        _cardBackImagePath,
                                                                      ),
                                                                      child: Image.file(
                                                                        File(
                                                                          _cardBackImagePath,
                                                                        ),
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    ),
                                                                    ColoredBox(
                                                                      color: Colors
                                                                          .black
                                                                          .withValues(
                                                                            alpha:
                                                                                0.2,
                                                                          ),
                                                                    ),
                                                                    Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .bottomCenter,
                                                                      child: Container(
                                                                        width: double
                                                                            .infinity,
                                                                        padding: const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                        ),
                                                                        color: Colors
                                                                            .black
                                                                            .withValues(
                                                                              alpha: 0.35,
                                                                            ),
                                                                        child: const Text(
                                                                          '長押しでプレビュー',
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          style: TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _buildActionButton(
                                    label: '保存',
                                    icon: Icons.download_rounded,
                                    onTap: _saveCardToGallery,
                                  ),
                                  const SizedBox(width: 14),
                                  _buildActionButton(
                                    label: '共有',
                                    icon: Icons.send_rounded,
                                    onTap: _shareCardImage,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          child: Column(
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -8),
                                child: Align(
                                  alignment: const Alignment(0, -0.02),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 392,
                                    ),
                                    child: RepaintBoundary(
                                      key: _pageCaptureKeys[1],
                                      child: SizedBox(
                                        height: _resultCardHeight,
                                        child: _buildCardWithFaceyOverlay(
                                          _buildResultCardFrame(
                                            child: Column(
                                              children: [
                                                const Spacer(flex: 2),
                                                _MetricPairCard(
                                                  left: secondPageMetrics[0],
                                                  right: secondPageMetrics[1],
                                                  potentialDeltaText:
                                                      potentialDeltaText,
                                                ),
                                                const Spacer(flex: 1),
                                                _MetricPairCard(
                                                  left: secondPageMetrics[2],
                                                  right: secondPageMetrics[3],
                                                  potentialDeltaText:
                                                      potentialDeltaText,
                                                ),
                                                const Spacer(flex: 1),
                                                _MetricPairCard(
                                                  left: secondPageMetrics[4],
                                                  right: secondPageMetrics[5],
                                                  potentialDeltaText:
                                                      potentialDeltaText,
                                                ),
                                                const Spacer(flex: 1),
                                                _MetricPairCard(
                                                  left: secondPageMetrics[6],
                                                  right: secondPageMetrics[7],
                                                  potentialDeltaText:
                                                      potentialDeltaText,
                                                ),
                                                const Spacer(flex: 2),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _buildActionButton(
                                    label: '保存',
                                    icon: Icons.download_rounded,
                                    onTap: _saveCardToGallery,
                                  ),
                                  const SizedBox(width: 14),
                                  _buildActionButton(
                                    label: '共有',
                                    icon: Icons.send_rounded,
                                    onTap: _shareCardImage,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          child: Column(
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -8),
                                child: Align(
                                  alignment: const Alignment(0, -0.02),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 392,
                                    ),
                                    child: RepaintBoundary(
                                      key: _pageCaptureKeys[2],
                                      child: SizedBox(
                                        height: _resultCardHeight,
                                        child: _buildResultCardFrame(
                                          padding: const EdgeInsets.fromLTRB(
                                            22,
                                            18,
                                            22,
                                            22,
                                          ),
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                top: 0,
                                                right: 6,
                                                child: ClipOval(
                                                  child: Image.file(
                                                    File(widget.imagePath),
                                                    width: 85,
                                                    height: 85,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Positioned.fill(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 0,
                                                      ),
                                                  child: Column(
                                                    children: [
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          '総合スコア',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 31,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          '${viewData.overall}',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 83,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                height: 1,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 30,
                                                      ),
                                                      _OverallBellCurve(
                                                        score: viewData.overall,
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        'あなたのスコアは全体の$betterThan%を上回っています',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: 0.52,
                                                              ),
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
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
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _buildActionButton(
                                    label: '保存',
                                    icon: Icons.download_rounded,
                                    onTap: _saveCardToGallery,
                                  ),
                                  const SizedBox(width: 14),
                                  _buildActionButton(
                                    label: '共有',
                                    icon: Icons.send_rounded,
                                    onTap: _shareCardImage,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          child: Column(
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -8),
                                child: Align(
                                  alignment: const Alignment(0, -0.02),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 392,
                                    ),
                                    child: RepaintBoundary(
                                      key: _pageCaptureKeys[3],
                                      child: SizedBox(
                                        height: _resultCardHeight,
                                        child: _buildResultCardFrame(
                                          padding: const EdgeInsets.fromLTRB(
                                            22,
                                            18,
                                            22,
                                            22,
                                          ),
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                top: 0,
                                                right: 6,
                                                child: ClipOval(
                                                  child: Image.file(
                                                    File(widget.imagePath),
                                                    width: 85,
                                                    height: 85,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Positioned.fill(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 0,
                                                      ),
                                                  child: Column(
                                                    children: [
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const Text(
                                                              'ポテンシャル',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 31,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          '$potentialScore',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 83,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                height: 1,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 30,
                                                      ),
                                                      _OverallBellCurve(
                                                        score: potentialScore,
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        'あなたのポテンシャルは全体の$potentialBetterThan%を上回っています',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: 0.52,
                                                              ),
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
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
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _buildActionButton(
                                    label: '保存',
                                    icon: Icons.download_rounded,
                                    onTap: _saveCardToGallery,
                                  ),
                                  const SizedBox(width: 14),
                                  _buildActionButton(
                                    label: '共有',
                                    icon: Icons.send_rounded,
                                    onTap: _shareCardImage,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          child: Column(
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -8),
                                child: Align(
                                  alignment: const Alignment(0, -0.02),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 392,
                                    ),
                                    child: RepaintBoundary(
                                      key: _pageCaptureKeys[4],
                                      child: SizedBox(
                                        height: _resultCardHeight,
                                        child: _buildResultCardFrame(
                                          padding: const EdgeInsets.fromLTRB(
                                            22,
                                            18,
                                            22,
                                            22,
                                          ),
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                top: 0,
                                                right: 6,
                                                child: ClipOval(
                                                  child: Image.file(
                                                    File(widget.imagePath),
                                                    width: 85,
                                                    height: 85,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Positioned.fill(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 0,
                                                      ),
                                                  child: Column(
                                                    children: [
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          'あなたの魅力',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 31,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 63,
                                                      ),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          strengthsSummary,
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.74,
                                                                ),
                                                            fontSize: 16,
                                                            height: 1.55,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      const Spacer(),
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
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _buildActionButton(
                                    label: '保存',
                                    icon: Icons.download_rounded,
                                    onTap: _saveCardToGallery,
                                  ),
                                  const SizedBox(width: 14),
                                  _buildActionButton(
                                    label: '共有',
                                    icon: Icons.send_rounded,
                                    onTap: _shareCardImage,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          child: Column(
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -8),
                                child: Align(
                                  alignment: const Alignment(0, -0.02),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 392,
                                    ),
                                    child: RepaintBoundary(
                                      key: _pageCaptureKeys[5],
                                      child: SizedBox(
                                        height: _resultCardHeight,
                                        child: _buildResultCardFrame(
                                          padding: const EdgeInsets.fromLTRB(
                                            22,
                                            18,
                                            22,
                                            22,
                                          ),
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                top: 0,
                                                right: 6,
                                                child: ClipOval(
                                                  child: Image.file(
                                                    File(widget.imagePath),
                                                    width: 85,
                                                    height: 85,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Positioned.fill(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 0,
                                                      ),
                                                  child: Column(
                                                    children: [
                                                      const Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          '改善点',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 31,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 72,
                                                      ),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          improvementsSummary,
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.74,
                                                                ),
                                                            fontSize: 16,
                                                            height: 1.55,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      const Spacer(),
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
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _buildActionButton(
                                    label: '保存',
                                    icon: Icons.download_rounded,
                                    onTap: _saveCardToGallery,
                                  ),
                                  const SizedBox(width: 14),
                                  _buildActionButton(
                                    label: '共有',
                                    icon: Icons.send_rounded,
                                    onTap: _shareCardImage,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          child: Column(
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -8),
                                child: Align(
                                  alignment: const Alignment(0, -0.02),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 392,
                                    ),
                                    child: RepaintBoundary(
                                      key: _pageCaptureKeys[6],
                                      child: SizedBox(
                                        height: _resultCardHeight,
                                        child: _buildResultCardFrame(
                                          padding: const EdgeInsets.fromLTRB(
                                            22,
                                            18,
                                            22,
                                            22,
                                          ),
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                top: 0,
                                                right: 6,
                                                child: ClipOval(
                                                  child: Image.file(
                                                    File(widget.imagePath),
                                                    width: 85,
                                                    height: 85,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Positioned.fill(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 0,
                                                      ),
                                                  child: Column(
                                                    children: [
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          '次の一手',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 31,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 72,
                                                      ),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          nextAction,
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.74,
                                                                ),
                                                            fontSize: 16,
                                                            height: 1.55,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      const Spacer(),
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
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(29),
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: <Color>[
                                        Color(0xFF6C1CFF),
                                        Color(0xFFB62BFF),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.36,
                                      ),
                                    ),
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      ScanFlowHaptics.primary();
                                      Navigator.of(context).pop();
                                    },
                                    style: TextButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(29),
                                      ),
                                    ),
                                    child: const Text(
                                      '終了',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -44),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(visiblePageCount, (
                        int index,
                      ) {
                        final bool active = _currentPageIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.34),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BackImagePreviewScreen extends StatefulWidget {
  const BackImagePreviewScreen({
    super.key,
    required this.previewImagePaths,
    required this.heroTagForPath,
    required this.onWillClose,
    this.initialIndex = 0,
  });

  final List<String> previewImagePaths;
  final String Function(String path) heroTagForPath;
  final ValueChanged<String> onWillClose;
  final int initialIndex;

  @override
  State<BackImagePreviewScreen> createState() => _BackImagePreviewScreenState();
}

class _BackImagePreviewScreenState extends State<BackImagePreviewScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _page;
  int _index = 0;
  double _dragY = 0;

  late final AnimationController _resetCtrl;
  Animation<double>? _backAnim;
  VoidCallback? _backListener;

  late final int _initialIndex;
  late final String _initialPath;
  late final String _fixedHeroTag;
  bool _popping = false;

  late final List<PhotoViewController> _pvCtrls;
  late final List<StreamSubscription<PhotoViewControllerValue>> _pvSubs;
  late final List<double?> _baseScale;
  late final List<bool> _atBaseScale;

  int _pointerCount = 0;

  @override
  void initState() {
    super.initState();
    final int total = widget.previewImagePaths.length;
    _initialIndex = widget.initialIndex.clamp(0, total - 1);
    _initialPath = widget.previewImagePaths[_initialIndex];
    _fixedHeroTag = widget.heroTagForPath(_initialPath);
    _index = _initialIndex;
    _page = PageController(initialPage: _index);

    _resetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _pvCtrls = List<PhotoViewController>.generate(
      total,
      (_) => PhotoViewController(),
    );
    _pvSubs = <StreamSubscription<PhotoViewControllerValue>>[];
    _baseScale = List<double?>.filled(total, null);
    _atBaseScale = List<bool>.filled(total, true);

    for (int i = 0; i < total; i++) {
      _pvSubs.add(
        _pvCtrls[i].outputStateStream.listen((PhotoViewControllerValue value) {
          final double? scale = value.scale;
          if (scale == null) return;

          _baseScale[i] ??= scale;
          final double base = _baseScale[i] ?? scale;
          final bool atBase = scale <= base * 1.02;

          if (_atBaseScale[i] == atBase) return;
          _atBaseScale[i] = atBase;
          if (mounted && i == _index) setState(() {});
        }),
      );
    }
  }

  @override
  void dispose() {
    _page.dispose();
    for (final StreamSubscription<PhotoViewControllerValue> sub in _pvSubs) {
      sub.cancel();
    }
    for (final PhotoViewController controller in _pvCtrls) {
      controller.dispose();
    }
    if (_backListener != null) {
      _resetCtrl.removeListener(_backListener!);
    }
    _resetCtrl.dispose();
    super.dispose();
  }

  bool get _canDragDismiss {
    if (_pointerCount >= 2) return false;
    return _atBaseScale[_index];
  }

  bool get _canPageSwipe {
    return _atBaseScale[_index] && _pointerCount < 2 && !_popping;
  }

  void _animateBack() {
    _resetCtrl.stop();
    _resetCtrl.value = 0;

    if (_backListener != null) {
      _resetCtrl.removeListener(_backListener!);
      _backListener = null;
    }

    final double start = _dragY;
    _backAnim = Tween<double>(
      begin: start,
      end: 0,
    ).animate(CurvedAnimation(parent: _resetCtrl, curve: Curves.easeOutCubic));

    _backListener = () {
      if (!mounted) return;
      final Animation<double>? animation = _backAnim;
      if (animation == null) return;
      setState(() => _dragY = animation.value);
    };

    _resetCtrl.addListener(_backListener!);
    _resetCtrl.forward().whenComplete(() {
      if (_backListener != null) {
        _resetCtrl.removeListener(_backListener!);
        _backListener = null;
      }
      _backAnim = null;
    });
  }

  void _setPopSpeed(Duration reverseDuration) {
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is ImageViewerRoute) {
      route.setReverseDuration(reverseDuration);
    }
  }

  void _popByCloseButton() {
    if (_popping) return;
    ScanFlowHaptics.back();
    _popping = true;

    _setPopSpeed(const Duration(milliseconds: 320));
    _pvCtrls[_index].reset();
    _dragY = 0;

    if (_index != _initialIndex) {
      _page.jumpToPage(_initialIndex);
      setState(() => _index = _initialIndex);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _closePreview();
    });
  }

  void _popSmoothToOrigin() {
    if (_popping) return;
    _popping = true;

    _setPopSpeed(const Duration(milliseconds: 200));
    _pvCtrls[_index].reset();

    if (_index != _initialIndex) {
      _page.jumpToPage(_initialIndex);
      setState(() => _index = _initialIndex);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _closePreview();
    });
  }

  void _closePreview() {
    final String selectedPath = widget.previewImagePaths[_index];
    widget.onWillClose(selectedPath);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.previewImagePaths.length;
    final double topPad = MediaQuery.of(context).padding.top;
    final double bottomPad = MediaQuery.of(context).padding.bottom;

    final double t = (_dragY / 260).clamp(0.0, 1.0);
    final double dim = ui.lerpDouble(0.42, 0.0, t)!;
    final double dragScale = (1.0 - t * 0.06).clamp(0.94, 1.0);
    final double radius = 18.0 * t;

    return Material(
      color: Colors.transparent,
      child: Listener(
        onPointerDown: (_) => _pointerCount++,
        onPointerUp: (_) => _pointerCount = math.max(0, _pointerCount - 1),
        onPointerCancel: (_) => _pointerCount = math.max(0, _pointerCount - 1),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (DragUpdateDetails details) {
            if (!_canDragDismiss) return;
            final double next = (_dragY + details.delta.dy).clamp(0.0, 500.0);
            setState(() => _dragY = next);
          },
          onVerticalDragEnd: (DragEndDetails details) {
            if (!_canDragDismiss) {
              if (_dragY != 0) setState(() => _dragY = 0);
              return;
            }
            final double velocity = details.primaryVelocity ?? 0.0;
            final bool shouldClose = (velocity > 250) || (_dragY > 60);
            if (shouldClose) {
              _popSmoothToOrigin();
            } else {
              _animateBack();
            }
          },
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(color: Colors.black.withValues(alpha: dim)),
                ),
              ),
              Transform.translate(
                offset: Offset(0, _dragY),
                child: Transform.scale(
                  scale: dragScale,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: PhotoViewGallery.builder(
                      pageController: _page,
                      itemCount: total,
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      scrollPhysics: _canPageSwipe
                          ? const BouncingScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      onPageChanged: (int index) {
                        setState(() {
                          _index = index;
                          _dragY = 0;
                        });
                      },
                      loadingBuilder:
                          (BuildContext context, ImageChunkEvent? progress) =>
                              const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                      builder: (BuildContext context, int i) {
                        final String path = widget.previewImagePaths[i];
                        return PhotoViewGalleryPageOptions(
                          imageProvider: FileImage(File(path)),
                          controller: _pvCtrls[i],
                          initialScale: PhotoViewComputedScale.contained,
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.contained * 3.0,
                          basePosition: Alignment.center,
                          scaleStateCycle: (PhotoViewScaleState state) =>
                              PhotoViewScaleState.initial,
                          heroAttributes: i == _index
                              ? PhotoViewHeroAttributes(tag: _fixedHeroTag)
                              : null,
                          errorBuilder:
                              (
                                BuildContext context,
                                Object error,
                                StackTrace? stackTrace,
                              ) => const Center(
                                child: Text(
                                  '画像を読み込めませんでした',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: topPad + 8,
                right: 8,
                child: IconButton(
                  onPressed: _popByCloseButton,
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white,
                  iconSize: 30,
                  splashRadius: 22,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10 + bottomPad,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${_index + 1} / $total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverallHeaderSection extends StatelessWidget {
  const _OverallHeaderSection({
    required this.imagePath,
    required this.score,
    this.title = '総合スコア',
  });

  final String imagePath;
  final int score;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF1F5FF),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(-8, -2),
              child: ClipOval(
                child: Image.file(
                  File(imagePath),
                  width: 85,
                  height: 85,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: _ScoreBar(value: score, width: 243, height: 14),
        ),
      ],
    );
  }
}

class _MetricPairCard extends StatelessWidget {
  const _MetricPairCard({
    required this.left,
    required this.right,
    required this.potentialDeltaText,
  });

  final FaceMetricScore left;
  final FaceMetricScore right;
  final String potentialDeltaText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: _MetricCell(
                metric: left,
                potentialDeltaText: potentialDeltaText,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 70,
            color: Colors.white.withValues(alpha: 0.14),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: Center(
              child: _MetricCell(
                metric: right,
                potentialDeltaText: potentialDeltaText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.metric, required this.potentialDeltaText});

  final FaceMetricScore metric;
  final String potentialDeltaText;

  @override
  Widget build(BuildContext context) {
    final bool isPotentialMetric = metric.label == 'ポテンシャル';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              metric.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isPotentialMetric) ...[
              const SizedBox(width: 12),
              Text(
                potentialDeltaText,
                style: const TextStyle(
                  color: Color(0xFF39D353),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 1),
        Text(
          '${metric.value}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        _ScoreBar(
          value: metric.value,
          width: double.infinity,
          height: 12,
          usePurpleGradient: isPotentialMetric,
        ),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.value,
    required this.width,
    this.height = 14,
    this.usePurpleGradient = false,
  });

  final int value;
  final double width;
  final double height;
  final bool usePurpleGradient;

  (Color, Color) _gradientByScore(int score) {
    final double t = (score.clamp(0, 100)) / 100;
    final Color start =
        Color.lerp(const Color(0xFF6A7696), const Color(0xFF95EEFF), t) ??
        const Color(0xFF6A7696);
    final Color end =
        Color.lerp(const Color(0xFF3F4B6E), const Color(0xFF124CFF), t) ??
        const Color(0xFF124CFF);
    return (start, end);
  }

  @override
  Widget build(BuildContext context) {
    final int score = value.clamp(0, 100);
    final double clamped = score / 100;
    final (Color startColor, Color endColor) = usePurpleGradient
        ? (const Color(0xFF6C1CFF), const Color(0xFFB62BFF))
        : _gradientByScore(score);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFD2D2D4)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [startColor, endColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: endColor.withValues(alpha: 0.30),
                      blurRadius: 6,
                      spreadRadius: 0.2,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallBellCurve extends StatelessWidget {
  const _OverallBellCurve({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final double marker = score.clamp(0, 100) / 100;
    return SizedBox(
      width: double.infinity,
      height: 175,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final double markerX = (width * (0.12 + marker * 0.76))
              .clamp(16.0, width - 16.0)
              .toDouble();
          final double textLeft = (markerX - 54)
              .clamp(0.0, width - 120)
              .toDouble();
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _BellCurvePainter(marker: marker)),
              ),
              Positioned(
                left: markerX - 11,
                bottom: 34,
                child: const Icon(
                  Icons.change_history_rounded,
                  size: 26,
                  color: Colors.white,
                ),
              ),
              Positioned(
                left: textLeft,
                bottom: 0,
                child: const Text(
                  "あなたのスコア",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BellCurvePainter extends CustomPainter {
  const _BellCurvePainter({required this.marker});

  final double marker;

  @override
  void paint(Canvas canvas, Size size) {
    final double baseline = size.height * 0.68;
    final double clampedMarker = marker.clamp(0.0, 1.0);
    final double markerX = size.width * (0.12 + clampedMarker * 0.76);
    final Path curvePath = Path()
      ..moveTo(0, baseline)
      ..cubicTo(
        size.width * 0.18,
        baseline,
        size.width * 0.28,
        size.height * 0.08,
        size.width * 0.5,
        size.height * 0.08,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.08,
        size.width * 0.82,
        baseline,
        size.width,
        baseline,
      );

    final Path fillPath = Path.from(curvePath)
      ..lineTo(size.width, baseline)
      ..lineTo(0, baseline)
      ..close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        colors: const <Color>[Color(0xFF1B0C3B), Color(0xFF4D23A6)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, markerX, size.height));

    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5
      ..color = Colors.white;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, markerX, size.height));
    canvas.drawPath(fillPath, fillPaint);
    canvas.restore();
    canvas.drawPath(curvePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _BellCurvePainter oldDelegate) =>
      oldDelegate.marker != marker;
}
