import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FaceMetricScore {
  const FaceMetricScore({required this.label, required this.value});

  final String label;
  final int value;
}

class FaceAnalysisResult {
  const FaceAnalysisResult({required this.overall, required this.metrics});

  final int overall;
  final List<FaceMetricScore> metrics;

  factory FaceAnalysisResult.dummy() {
    return const FaceAnalysisResult(
      overall: 84,
      metrics: <FaceMetricScore>[
        FaceMetricScore(label: 'ポテンシャル', value: 78),
        FaceMetricScore(label: '性的魅力', value: 86),
        FaceMetricScore(label: '印象', value: 73),
        FaceMetricScore(label: '清潔感', value: 91),
        FaceMetricScore(label: '骨格', value: 82),
        FaceMetricScore(label: '肌', value: 69),
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
  });

  final String imagePath;
  final String? sideImagePath;

  // AI導線用: 後でAPIレスポンスをここへ渡せばUIはそのまま使える。
  final FaceAnalysisResult? result;

  @override
  State<FaceAnalysisResultScreen> createState() =>
      _FaceAnalysisResultScreenState();
}

class _FaceAnalysisResultScreenState extends State<FaceAnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  static const double _resultCardHeight = 500;
  int _currentPageIndex = 0;
  final GlobalKey _cardCaptureKey = GlobalKey();
  late final AnimationController _flipController;
  late String _cardBackImagePath;

  Future<Uint8List?> _captureCardAsPng() async {
    final RenderObject? renderObject = _cardCaptureKey.currentContext
        ?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;
    final ui.Image image = await renderObject.toImage(pixelRatio: 3);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData?.buffer.asUint8List();
  }

  Future<void> _saveCardToGallery() async {
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

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cardBackImagePath = widget.imagePath;
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
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (BuildContext context, _, __) {
          return _BackImagePreviewScreen(
            previewImagePaths: uniquePreviewImagePaths,
            heroTagForPath: _heroTagForPath,
            onWillClose: (String selectedPath) {
              if (!mounted || _cardBackImagePath == selectedPath) return;
              setState(() {
                _cardBackImagePath = selectedPath;
              });
            },
          );
        },
        transitionsBuilder: (BuildContext context, _, __, Widget child) {
          return child;
        },
      ),
    );
  }

  String _heroTagForPath(String path) => 'face_analysis_preview_$path';

  Widget _buildResultCardFrame({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(14, 14, 14, 14),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF08090C),
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
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: TextButton.icon(
            onPressed: onTap,
            style: TextButton.styleFrom(
              iconAlignment: IconAlignment.end,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
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

  @override
  Widget build(BuildContext context) {
    final FaceAnalysisResult viewData =
        widget.result ?? FaceAnalysisResult.dummy();
    final List<FaceMetricScore> metrics = List<FaceMetricScore>.from(
      viewData.metrics,
    );
    final List<FaceMetricScore> secondPageMetrics = <FaceMetricScore>[
      const FaceMetricScore(label: '男性らしさ', value: 88),
      const FaceMetricScore(label: '自信', value: 84),
      const FaceMetricScore(label: '親しみやすさ', value: 79),
      const FaceMetricScore(label: '髪の毛', value: 86),
      const FaceMetricScore(label: 'シャープさ', value: 82),
      const FaceMetricScore(label: '目力', value: 90),
      const FaceMetricScore(label: '顎ライン', value: 84),
      const FaceMetricScore(label: '眉', value: 86),
    ];
    while (metrics.length < 6) {
      metrics.add(const FaceMetricScore(label: '-', value: 0));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: const Center(child: Icon(Icons.close_rounded, size: 34)),
        ),
        title: const Text(
          '分析結果',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
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
              offset: const Offset(0, 10),
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
                                      key: _cardCaptureKey,
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
                                                    ),
                                                    const SizedBox(height: 22),
                                                    _MetricPairCard(
                                                      left: metrics[0],
                                                      right: metrics[1],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    _MetricPairCard(
                                                      left: metrics[2],
                                                      right: metrics[3],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    _MetricPairCard(
                                                      left: metrics[4],
                                                      right: metrics[5],
                                                    ),
                                                    const SizedBox(height: 4),
                                                  ],
                                                );

                                            return Transform(
                                              alignment: Alignment.center,
                                              transform: Matrix4.identity()
                                                ..setEntry(3, 2, 0.0012)
                                                ..rotateY(angle),
                                              child: showFront
                                                  ? SizedBox(
                                                      height: _resultCardHeight,
                                                      child:
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
                                                            ..rotateY(math.pi),
                                                      child: SizedBox(
                                                        height:
                                                            _resultCardHeight,
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
                              const SizedBox(height: 22),
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
                                    child: SizedBox(
                                      height: _resultCardHeight,
                                      child: _buildResultCardFrame(
                                        child: Column(
                                          children: [
                                            const Spacer(flex: 2),
                                            _MetricPairCard(
                                              left: secondPageMetrics[0],
                                              right: secondPageMetrics[1],
                                            ),
                                            const Spacer(flex: 1),
                                            _MetricPairCard(
                                              left: secondPageMetrics[2],
                                              right: secondPageMetrics[3],
                                            ),
                                            const Spacer(flex: 1),
                                            _MetricPairCard(
                                              left: secondPageMetrics[4],
                                              right: secondPageMetrics[5],
                                            ),
                                            const Spacer(flex: 1),
                                            _MetricPairCard(
                                              left: secondPageMetrics[6],
                                              right: secondPageMetrics[7],
                                            ),
                                            const Spacer(flex: 2),
                                          ],
                                        ),
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
                    offset: const Offset(0, -68),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(2, (int index) {
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

class _BackImagePreviewScreen extends StatefulWidget {
  const _BackImagePreviewScreen({
    required this.previewImagePaths,
    required this.heroTagForPath,
    required this.onWillClose,
  });

  final List<String> previewImagePaths;
  final String Function(String path) heroTagForPath;
  final ValueChanged<String> onWillClose;

  @override
  State<_BackImagePreviewScreen> createState() =>
      _BackImagePreviewScreenState();
}

class _BackImagePreviewScreenState extends State<_BackImagePreviewScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  double _dragOffsetY = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _closePreview() async {
    final String selectedPath = widget.previewImagePaths[_currentIndex];
    widget.onWillClose(selectedPath);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (DragUpdateDetails details) {
              setState(() {
                _isDragging = true;
                _dragOffsetY = (_dragOffsetY + details.delta.dy).clamp(
                  0.0,
                  220.0,
                );
              });
            },
            onVerticalDragEnd: (DragEndDetails details) {
              final double velocity = details.primaryVelocity ?? 0;
              final bool shouldDismiss = _dragOffsetY > 90 || velocity > 650;
              if (shouldDismiss) {
                _closePreview();
                return;
              }
              setState(() {
                _isDragging = false;
                _dragOffsetY = 0;
              });
            },
            onVerticalDragCancel: () {
              setState(() {
                _isDragging = false;
                _dragOffsetY = 0;
              });
            },
            child: AnimatedContainer(
              duration: _isDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, _dragOffsetY, 0),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.previewImagePaths.length,
                        onPageChanged: (int index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        itemBuilder: (BuildContext context, int index) {
                          final String imagePath =
                              widget.previewImagePaths[index];
                          final Widget imageWidget = Image.file(
                            File(imagePath),
                            fit: BoxFit.contain,
                          );
                          return InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Hero(
                              tag: widget.heroTagForPath(imagePath),
                              child: imageWidget,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (widget.previewImagePaths.length > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(
                        widget.previewImagePaths.length,
                        (int index) {
                          final bool active = _currentIndex == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _closePreview,
                    child: const Text(
                      '閉じる',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverallHeaderSection extends StatelessWidget {
  const _OverallHeaderSection({required this.imagePath, required this.score});

  final String imagePath;
  final int score;

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
                  const Text(
                    '総合スコア',
                    style: TextStyle(
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
        color: const Color(0xFF101218),
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

  @override
  Widget build(BuildContext context) {
    final double clamped = (value.clamp(0, 100)) / 100;
    final Color startColor =
        Color.lerp(const Color(0xFF95EEFF), const Color(0xFF3CC8FF), clamped) ??
        const Color(0xFF95EEFF);
    final Color endColor =
        Color.lerp(const Color(0xFF5BB9FF), const Color(0xFF124CFF), clamped) ??
        const Color(0xFF124CFF);
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
