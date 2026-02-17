import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LaserAnalyzeShell(imagePath: file.path),
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
          'あなたの顔を解析します',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
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
        builder: (_) => ScanImagePreviewScreen(imagePath: widget.imagePath),
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

class ScanImagePreviewScreen extends StatelessWidget {
  const ScanImagePreviewScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: frameWidth,
                    height: frameHeight,
                    child: Image.file(File(imagePath), fit: BoxFit.cover),
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
