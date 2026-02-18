import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/yomu_gender_two_choice.dart';

class ScanNextScreen extends StatefulWidget {
  const ScanNextScreen({super.key, required this.selectedGender});

  final YomuGender selectedGender;

  @override
  State<ScanNextScreen> createState() => _ScanNextScreenState();
}

class _ScanNextScreenState extends State<ScanNextScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 92,
    );
    if (file == null || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ScanImageConfirmScreen(
          initialImagePath: file.path,
          selectedGender: widget.selectedGender,
          goToSideProfileStepOnContinue: true,
        ),
      ),
    );
  }

  Future<void> _showPickerOptions() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text(
            '画像をアップロード',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickImage(ImageSource.camera);
              },
              child: const Text(
                '自撮りを撮影',
                style: TextStyle(color: Colors.white),
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickImage(ImageSource.gallery);
              },
              child: const Text('写真を選択', style: TextStyle(color: Colors.white)),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            isDefaultAction: true,
            child: const Text('キャンセル', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildStartScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.0,
          ),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF5D2DFF), Color(0xFFAD24FF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B31FF).withValues(alpha: 0.5),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextButton(
          onPressed: _showPickerOptions,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'スキャン開始',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imagePath = widget.selectedGender == YomuGender.female
        ? 'assets/images/bay.png'
        : 'assets/images/pay.png';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '正面からの画像をアップロード',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0C10), Color(0xFF1A2230), Color(0xFF2E3F5B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(
                children: [
                  Align(
                    alignment: const Alignment(0, -0.9),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: SizedBox(
                        width: constraints.maxWidth - 34,
                        child: Image.asset(imagePath, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 36,
                    right: 36,
                    bottom: 32,
                    child: _buildStartScanButton(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class LaserAnalyzeSpec {
  const LaserAnalyzeSpec({
    this.laserDuration = const Duration(milliseconds: 1650),
    this.analysisDuration = const Duration(milliseconds: 2800),
    this.laserWidth = 20.0,
  });

  final Duration laserDuration;
  final Duration analysisDuration;
  final double laserWidth;
}

class LaserAnalyzeShell extends StatefulWidget {
  const LaserAnalyzeShell({
    super.key,
    required this.imagePath,
    this.spec = const LaserAnalyzeSpec(),
  });

  final String imagePath;
  final LaserAnalyzeSpec spec;

  @override
  State<LaserAnalyzeShell> createState() => _LaserAnalyzeShellState();
}

class _LaserAnalyzeShellState extends State<LaserAnalyzeShell>
    with TickerProviderStateMixin {
  late final AnimationController _laserController;
  late final Animation<double> _laserProgress;
  late final AnimationController _resultController;
  late final Animation<double> _resultAnim;
  bool _showLaser = true;
  bool _didNavigate = false;
  bool _hasReversed = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: widget.spec.laserDuration,
    );
    _laserProgress = CurvedAnimation(
      parent: _laserController,
      curve: Curves.easeInOut,
    );
    _laserController.addStatusListener((AnimationStatus status) {
      if (!_showLaser) return;
      if (status == AnimationStatus.completed) {
        if (!_hasReversed) {
          _hasReversed = true;
          _laserController.reverse();
        }
      } else if (status == AnimationStatus.dismissed) {
        if (_hasReversed) {
          _completeAnalyze();
        }
      }
    });
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _resultAnim = CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _tryStartLaser());
  }

  void _tryStartLaser() {
    if (!mounted) return;
    _laserController.forward();
  }

  Future<void> _completeAnalyze() async {
    if (!mounted || _didNavigate) return;
    _laserController.stop();
    setState(() {
      _showLaser = false;
    });
    await _resultController.forward();
    if (!mounted || _didNavigate) return;
    _didNavigate = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => FaceAnalysisResultScreen(imagePath: widget.imagePath),
      ),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0C10), Color(0xFF1A2230), Color(0xFF2E3F5B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double frameWidth = (constraints.maxWidth * 0.84).clamp(
                260.0,
                370.0,
              );
              final double frameHeight = (constraints.maxHeight * 0.64).clamp(
                390.0,
                560.0,
              );
              return Align(
                alignment: const Alignment(0, -0.75),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_laserProgress, _resultAnim]),
                  builder: (BuildContext context, _) {
                    final double scale = 1 - (_resultAnim.value * 0.02);
                    return Transform.scale(
                      scale: scale,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: frameWidth,
                          height: frameHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(widget.imagePath),
                                fit: BoxFit.cover,
                              ),
                              CustomPaint(
                                painter: YomuLaserPainter(
                                  progress: _laserProgress.value,
                                  showLaser: _showLaser,
                                  laserWidth: widget.spec.laserWidth,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class YomuLaserPainter extends CustomPainter {
  const YomuLaserPainter({
    required this.progress,
    required this.showLaser,
    required this.laserWidth,
  });

  final double progress;
  final bool showLaser;
  final double laserWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (!showLaser) return;
    final double x = progress * size.width;
    final Rect rect = Rect.fromLTWH(
      x - laserWidth / 2,
      0,
      laserWidth,
      size.height,
    );
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x00FFFFFF),
          Color(0x66FFFFFF),
          Color(0xDDFFFFFF),
          Color(0x66FFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant YomuLaserPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.showLaser != showLaser ||
        oldDelegate.laserWidth != laserWidth;
  }
}

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
        FaceMetricScore(label: '伸び代', value: 78),
        FaceMetricScore(label: '骨格', value: 86),
        FaceMetricScore(label: '清潔感', value: 73),
        FaceMetricScore(label: '印象', value: 91),
        FaceMetricScore(label: '性的魅力', value: 82),
        FaceMetricScore(label: '肌', value: 69),
      ],
    );
  }
}

class FaceAnalysisResultScreen extends StatefulWidget {
  const FaceAnalysisResultScreen({
    super.key,
    required this.imagePath,
    this.result,
  });

  final String imagePath;

  // AI導線用: 後でAPIレスポンスをここへ渡せばUIはそのまま使える。
  final FaceAnalysisResult? result;

  @override
  State<FaceAnalysisResultScreen> createState() =>
      _FaceAnalysisResultScreenState();
}

class _FaceAnalysisResultScreenState extends State<FaceAnalysisResultScreen> {
  int _currentPageIndex = 0;
  final GlobalKey _cardCaptureKey = GlobalKey();

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
    while (metrics.length < 6) {
      metrics.add(const FaceMetricScore(label: '-', value: 0));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
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
          ColoredBox(color: Colors.black.withValues(alpha: 0.88)),
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
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF08090C),
                                          borderRadius: BorderRadius.circular(
                                            34,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.20,
                                            ),
                                          ),
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          14,
                                          14,
                                          14,
                                        ),
                                        child: Column(
                                          children: [
                                            _OverallHeaderSection(
                                              imagePath: widget.imagePath,
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
                                    label: 'Save',
                                    icon: Icons.download_rounded,
                                    onTap: _saveCardToGallery,
                                  ),
                                  const SizedBox(width: 14),
                                  _buildActionButton(
                                    label: 'Share',
                                    icon: Icons.send_rounded,
                                    onTap: _shareCardImage,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox.expand(),
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

class SideProfileUploadScreen extends StatefulWidget {
  const SideProfileUploadScreen({
    super.key,
    required this.selectedGender,
    required this.frontImagePath,
  });

  final YomuGender selectedGender;
  final String frontImagePath;

  @override
  State<SideProfileUploadScreen> createState() =>
      _SideProfileUploadScreenState();
}

class _SideProfileUploadScreenState extends State<SideProfileUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 92,
    );
    if (file == null || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ScanImageConfirmScreen(
          initialImagePath: file.path,
          selectedGender: widget.selectedGender,
          goToSideProfileStepOnContinue: false,
          appBarTitle: '横顔をアップロード',
          laserThumbnailPath: widget.frontImagePath,
        ),
      ),
    );
  }

  Future<void> _showPickerOptions() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text(
            '画像をアップロード',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickImage(ImageSource.camera);
              },
              child: const Text(
                '自撮りを撮影',
                style: TextStyle(color: Colors.white),
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickImage(ImageSource.gallery);
              },
              child: const Text('写真を選択', style: TextStyle(color: Colors.white)),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            isDefaultAction: true,
            child: const Text('キャンセル', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildStartScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.0,
          ),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF5D2DFF), Color(0xFFAD24FF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B31FF).withValues(alpha: 0.5),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextButton(
          onPressed: _showPickerOptions,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'アップロード',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imagePath = widget.selectedGender == YomuGender.female
        ? 'assets/images/memem.png'
        : 'assets/images/papipe.png';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '横顔をアップロード',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0C10), Color(0xFF1A2230), Color(0xFF2E3F5B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(
                children: [
                  Align(
                    alignment: const Alignment(0, -0.9),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: SizedBox(
                        width: constraints.maxWidth - 34,
                        child: Image.asset(imagePath, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 36,
                    right: 36,
                    bottom: 32,
                    child: _buildStartScanButton(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ScanImageConfirmScreen extends StatefulWidget {
  const ScanImageConfirmScreen({
    super.key,
    required this.initialImagePath,
    required this.selectedGender,
    required this.goToSideProfileStepOnContinue,
    this.appBarTitle = '正面からの画像をアップロード',
    this.laserThumbnailPath,
  });

  final String initialImagePath;
  final YomuGender selectedGender;
  final bool goToSideProfileStepOnContinue;
  final String appBarTitle;
  final String? laserThumbnailPath;

  @override
  State<ScanImageConfirmScreen> createState() => _ScanImageConfirmScreenState();
}

class _ScanImageConfirmScreenState extends State<ScanImageConfirmScreen> {
  final ImagePicker _picker = ImagePicker();
  late String _currentImagePath;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.initialImagePath;
  }

  Future<void> _replaceImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 92,
    );
    if (file == null || !mounted) return;
    setState(() {
      _currentImagePath = file.path;
    });
  }

  Future<void> _showPickerOptions() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text(
            '画像をアップロード',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                await _replaceImage(ImageSource.camera);
              },
              child: const Text(
                '自撮りを撮影',
                style: TextStyle(color: Colors.white),
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                await _replaceImage(ImageSource.gallery);
              },
              child: const Text('写真を選択', style: TextStyle(color: Colors.white)),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            isDefaultAction: true,
            child: const Text('キャンセル', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildUseAnotherButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.82),
            width: 1.3,
          ),
          color: const Color(0x0FFFFFFF),
        ),
        child: TextButton(
          onPressed: _showPickerOptions,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          ),
          child: const Text(
            '別の画像を選択',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 0.9,
          ),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF5B22FF), Color(0xFFB61DFF)],
          ),
        ),
        child: TextButton(
          onPressed: () {
            if (widget.goToSideProfileStepOnContinue) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SideProfileUploadScreen(
                    selectedGender: widget.selectedGender,
                    frontImagePath: _currentImagePath,
                  ),
                ),
              );
              return;
            }
            final String laserImagePath =
                widget.laserThumbnailPath ?? _currentImagePath;
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LaserAnalyzeShell(imagePath: laserImagePath),
              ),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          ),
          child: const Text(
            '進む',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.appBarTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0C10), Color(0xFF1A2230), Color(0xFF2E3F5B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      File(_currentImagePath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _buildUseAnotherButton(context),
                const SizedBox(height: 14),
                _buildContinueButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
