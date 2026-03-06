import 'dart:async';
import 'dart:convert';
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
import 'package:share_plus/share_plus.dart';

import '../services/facey_api_service.dart';
import 'face_analysis_result_screen.dart';

class ConditionAnalysisResultScreen extends StatefulWidget {
  const ConditionAnalysisResultScreen({
    super.key,
    required this.imagePath,
    this.sideImagePath,
    this.result,
  });

  final String imagePath;
  final String? sideImagePath;
  final FaceAnalysisResult? result;

  @override
  State<ConditionAnalysisResultScreen> createState() =>
      _ConditionAnalysisResultScreenState();
}

class _ConditionAnalysisResultScreenState
    extends State<ConditionAnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  static const String _prefsBoxName = 'app_prefs';
  static const String _genderKey = 'selected_gender';
  static const String _conditionLatestResultAnalysisJsonKey =
      'condition_latest_result_analysis_json';
  static const String _conditionLatestResultAnalysisFrontPathKey =
      'condition_latest_result_analysis_front_path';
  static const String _conditionLatestResultAnalysisSidePathKey =
      'condition_latest_result_analysis_side_path';
  static const String _conditionResultAnalysisByFrontPathKey =
      'condition_result_analysis_by_front_path';
  static const List<String> _conditionLabels = <String>[
    '清潔感',
    '肌',
    '雰囲気',
    '活力',
    '髪',
    '目元',
  ];
  static const double _resultCardHeight = 500;
  final PageController _pageController = PageController();
  final List<GlobalKey> _cardCaptureKeys = <GlobalKey>[
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
  ];
  late final AnimationController _flipController;
  late String _cardBackImagePath;
  FaceAnalysisResult? _apiResult;
  bool _isApiLoading = false;
  String? _apiResultError;

  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cardBackImagePath = widget.imagePath;
    unawaited(_loadConditionAnalysis());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCardFlip() {
    if (_flipController.isAnimating) return;
    if (_flipController.value >= 0.5) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  Future<void> _showImagePreview() async {
    if (_flipController.value < 0.5) return;
    final List<String> previewImagePaths = <String>[
      _cardBackImagePath,
      widget.imagePath,
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

  String _heroTagForPath(String path) => 'condition_analysis_preview_$path';

  int _scoreFrom(Object? value, int fallback) {
    final int parsed = switch (value) {
      int v => v,
      double v => v.round(),
      String v => int.tryParse(v) ?? fallback,
      _ => fallback,
    };
    return parsed.clamp(0, 100);
  }

  FaceAnalysisResult _parseConditionAnalysis(Map<String, dynamic> json) {
    final List<dynamic> metricsRaw = (json['metrics'] as List?) ?? <dynamic>[];
    final List<FaceMetricScore> metrics = List<FaceMetricScore>.generate(
      _conditionLabels.length,
      (int index) {
        final dynamic item = index < metricsRaw.length
            ? metricsRaw[index]
            : null;
        final Map<String, dynamic> map = item is Map<String, dynamic>
            ? item
            : <String, dynamic>{};
        return FaceMetricScore(
          label: _conditionLabels[index],
          value: _scoreFrom(map['value'], 50),
        );
      },
    );
    return FaceAnalysisResult(
      overall: _scoreFrom(json['overall'], 50),
      metrics: metrics,
      strengthsSummary: (json['strengthsSummary'] ?? '').toString(),
      improvementsSummary: (json['improvementsSummary'] ?? '').toString(),
      nextAction: (json['nextAction'] ?? '').toString(),
    );
  }

  FaceAnalysisResult? _loadPersistedResultForCurrentImage() {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    final String rawMap =
        box.get(_conditionResultAnalysisByFrontPathKey) ?? '{}';
    try {
      final Map<String, dynamic> byPath = Map<String, dynamic>.from(
        jsonDecode(rawMap) as Map<String, dynamic>,
      );
      final Object? hit = byPath[widget.imagePath];
      if (hit is Map<String, dynamic>) {
        return _parseConditionAnalysis(hit);
      }
    } catch (_) {
      // fallback to latest keys below
    }

    final String? latestFront = box.get(
      _conditionLatestResultAnalysisFrontPathKey,
    );
    if (latestFront != widget.imagePath) return null;
    final String currentSide = widget.sideImagePath ?? '';
    final String latestSide =
        box.get(_conditionLatestResultAnalysisSidePathKey) ?? '';
    if (currentSide != latestSide) return null;
    final String raw = box.get(_conditionLatestResultAnalysisJsonKey) ?? '';
    if (raw.isEmpty) return null;
    try {
      final Map<String, dynamic> map = Map<String, dynamic>.from(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return _parseConditionAnalysis(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistConditionResult(Map<String, dynamic> analysis) async {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    await box.put(_conditionLatestResultAnalysisFrontPathKey, widget.imagePath);
    if (widget.sideImagePath != null && widget.sideImagePath!.isNotEmpty) {
      await box.put(
        _conditionLatestResultAnalysisSidePathKey,
        widget.sideImagePath!,
      );
    } else {
      await box.delete(_conditionLatestResultAnalysisSidePathKey);
    }
    await box.put(_conditionLatestResultAnalysisJsonKey, jsonEncode(analysis));

    final String rawMap =
        box.get(_conditionResultAnalysisByFrontPathKey) ?? '{}';
    Map<String, dynamic> byPath;
    try {
      byPath = Map<String, dynamic>.from(
        jsonDecode(rawMap) as Map<String, dynamic>,
      );
    } catch (_) {
      byPath = <String, dynamic>{};
    }
    byPath[widget.imagePath] = analysis;
    await box.put(_conditionResultAnalysisByFrontPathKey, jsonEncode(byPath));
  }

  Future<void> _loadConditionAnalysis() async {
    if (widget.result != null) return;
    final FaceAnalysisResult? cached = _loadPersistedResultForCurrentImage();
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _apiResult = cached;
        _isApiLoading = false;
        _apiResultError = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isApiLoading = true;
      _apiResultError = null;
    });
    try {
      final List<int> frontImageBytes = await File(
        widget.imagePath,
      ).readAsBytes();
      final List<int>? sideImageBytes =
          widget.sideImagePath != null && widget.sideImagePath!.isNotEmpty
          ? await File(widget.sideImagePath!).readAsBytes()
          : null;
      final Box<String> box = Hive.box<String>(_prefsBoxName);
      final String gender = box.get(_genderKey) == 'female' ? 'female' : 'male';
      final Map<String, dynamic> analysis = await FaceyApiService.analyzeHome(
        frontImageBytes: frontImageBytes,
        sideImageBytes: sideImageBytes,
        gender: gender,
      );
      final FaceAnalysisResult parsed = _parseConditionAnalysis(analysis);
      await _persistConditionResult(analysis);
      if (!mounted) return;
      setState(() {
        _apiResult = parsed;
        _isApiLoading = false;
        _apiResultError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isApiLoading = false;
        _apiResultError = '解析APIの取得に失敗しました。';
      });
    }
  }

  Future<Uint8List?> _captureCurrentCardAsPng() async {
    final GlobalKey captureKey =
        _cardCaptureKeys[_currentPageIndex.clamp(0, 4)];
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
        continue;
      }
    }
    return null;
  }

  Future<void> _saveCardToGallery() async {
    try {
      final Uint8List? bytes = await _captureCurrentCardAsPng();
      if (bytes == null || !mounted) return;
      await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'facey_condition_${DateTime.now().millisecondsSinceEpoch}',
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
    try {
      final Uint8List? bytes = await _captureCurrentCardAsPng();
      if (bytes == null) return;
      final Directory tempDir = await getTemporaryDirectory();
      final String path =
          '${tempDir.path}/facey_condition_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(path)], text: 'Faceyのコンディション結果');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('共有に失敗しました')));
    }
  }

  Widget _buildResultCardFrame({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(22, 18, 22, 22),
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

  Widget _buildBottomActions() {
    return Row(
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
    );
  }

  Widget _buildFlippableConditionCard({
    required FaceAnalysisResult viewData,
    required List<String> labels,
    required List<int> values,
  }) {
    final Widget frontCardContent = Column(
      children: [
        _OverallHeaderSection(
          imagePath: widget.imagePath,
          score: viewData.overall.clamp(0, 100),
          title: 'コンディション',
        ),
        const SizedBox(height: 22),
        _MetricPairCard(
          left: FaceMetricScore(label: labels[0], value: values[0]),
          right: FaceMetricScore(label: labels[1], value: values[1]),
        ),
        const SizedBox(height: 10),
        _MetricPairCard(
          left: FaceMetricScore(label: labels[2], value: values[2]),
          right: FaceMetricScore(label: labels[3], value: values[3]),
        ),
        const SizedBox(height: 10),
        _MetricPairCard(
          left: FaceMetricScore(label: labels[4], value: values[4]),
          right: FaceMetricScore(label: labels[5], value: values[5]),
        ),
        const SizedBox(height: 4),
      ],
    );

    return GestureDetector(
      onTap: _toggleCardFlip,
      onLongPress: _showImagePreview,
      child: AnimatedBuilder(
        animation: _flipController,
        builder: (BuildContext context, _) {
          final double angle = _flipController.value * math.pi;
          final bool showFront = angle <= (math.pi / 2);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: SizedBox(
              height: _resultCardHeight,
              child: showFront
                  ? _buildCardWithFaceyOverlay(
                      _buildResultCardFrame(child: frontCardContent),
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _buildResultCardFrame(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: _heroTagForPath(_cardBackImagePath),
                              child: Image.file(
                                File(_cardBackImagePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                            ColoredBox(
                              color: Colors.black.withValues(alpha: 0.2),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                color: Colors.black.withValues(alpha: 0.35),
                                child: const Text(
                                  '長押しでプレビュー',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
    );
  }

  Widget _buildConditionMeterPage({
    required int score,
    required List<String> labels,
    required List<int> values,
  }) {
    return SizedBox(
      height: _resultCardHeight,
      child: _buildCardWithFaceyOverlay(
        _buildResultCardFrame(
          child: Column(
            children: [
              _OverallHeaderSection(
                imagePath: widget.imagePath,
                score: score.clamp(0, 100),
                title: 'コンディション',
              ),
              const SizedBox(height: 22),
              _MetricPairCard(
                left: FaceMetricScore(label: labels[0], value: values[0]),
                right: FaceMetricScore(label: labels[1], value: values[1]),
              ),
              const SizedBox(height: 10),
              _MetricPairCard(
                left: FaceMetricScore(label: labels[2], value: values[2]),
                right: FaceMetricScore(label: labels[3], value: values[3]),
              ),
              const SizedBox(height: 10),
              _MetricPairCard(
                left: FaceMetricScore(label: labels[4], value: values[4]),
                right: FaceMetricScore(label: labels[5], value: values[5]),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
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
            onTap: () => Navigator.of(context).pop(),
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
                          onPressed: _loadConditionAnalysis,
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
    final List<int> values = <int>[
      for (final FaceMetricScore m in viewData.metrics.take(6))
        m.value.clamp(0, 100),
      ...List<int>.filled((6 - viewData.metrics.length).clamp(0, 6), 0),
    ];
    const List<String> labels = _conditionLabels;
    const List<String> conditionMeterLabels = <String>[
      '異性吸引力',
      '自信オーラ',
      '第一印象',
      '潤い',
      'シャープさ',
      'ハリ',
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: const Center(child: Icon(Icons.close_rounded, size: 34)),
        ),
        title: const Text(
          '総合評価',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w700,
            fontFamily: 'Hiragino Sans',
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
                      controller: _pageController,
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
                                      key: _cardCaptureKeys[0],
                                      child: _buildFlippableConditionCard(
                                        viewData: viewData,
                                        labels: labels,
                                        values: values,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildBottomActions(),
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
                                      key: _cardCaptureKeys[1],
                                      child: _buildConditionMeterPage(
                                        score: viewData.overall,
                                        labels: conditionMeterLabels,
                                        values: values,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildBottomActions(),
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
                                      key: _cardCaptureKeys[2],
                                      child: SizedBox(
                                        height: _resultCardHeight,
                                        child: _buildCardWithFaceyOverlay(
                                          _buildResultCardFrame(
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
                                                  child: Column(
                                                    children: [
                                                      const Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          '現在の印象',
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
                                                          '全体的に整った印象で、清潔感が安定しています。\n'
                                                          '目元の強さが程よく、表情にメリハリが出ています。\n'
                                                          '肌のコンディションも良く、顔全体の見え方が自然です。',
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
                              _buildBottomActions(),
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
                                      key: _cardCaptureKeys[3],
                                      child: SizedBox(
                                        height: _resultCardHeight,
                                        child: _buildCardWithFaceyOverlay(
                                          _buildResultCardFrame(
                                            padding: const EdgeInsets.fromLTRB(
                                              18,
                                              18,
                                              18,
                                              22,
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Expanded(
                                                      child: Text(
                                                        '周囲からの印象',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 31,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    ClipOval(
                                                      child: Image.file(
                                                        File(widget.imagePath),
                                                        width: 82,
                                                        height: 82,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 22),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    '「清潔感があって、話しかけやすい」\n'
                                                    '「目元に意志があって、頼れる印象」\n'
                                                    '「落ち着いて見えるのに、重くなりすぎない」\n\n'
                                                    '全体として、安心感と誠実さが先に伝わる見え方です。',
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
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildBottomActions(),
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
                                      key: _cardCaptureKeys[4],
                                      child: SizedBox(
                                        height: _resultCardHeight,
                                        child: _buildCardWithFaceyOverlay(
                                          _buildResultCardFrame(
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
                                                  child: Column(
                                                    children: [
                                                      const Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          '微調整',
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
                                                          '朝夜の保湿を固定して、肌の安定感を維持しましょう。'
                                                          '眉下ラインを少し整えると目元の印象が締まり、前髪の重さを少し軽くすると顔全体に自然な抜け感が出ます。',
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
                                              ],
                                            ),
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
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
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
                      children: List<Widget>.generate(5, (int index) {
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
  const _MetricPairCard({required this.left, required this.right});

  final FaceMetricScore left;
  final FaceMetricScore right;

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
            child: Center(child: _MetricCell(metric: left)),
          ),
          Container(
            width: 1,
            height: 70,
            color: Colors.white.withValues(alpha: 0.14),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: Center(child: _MetricCell(metric: right)),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.metric});

  final FaceMetricScore metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
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
        _ScoreBar(value: metric.value, width: double.infinity, height: 12),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.value, required this.width, this.height = 14});

  final int value;
  final double width;
  final double height;

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
    final (Color startColor, Color endColor) = _gradientByScore(score);
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
