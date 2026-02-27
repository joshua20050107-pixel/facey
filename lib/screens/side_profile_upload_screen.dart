import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../routes/no_swipe_back_material_page_route.dart';
import '../widgets/yomu_gender_two_choice.dart';
import 'scan_image_confirm_screen.dart';

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
  static const double _previewAspectRatio = 1057 / 1403;
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  bool _cameraModeEnabled = false;
  bool _initializingCamera = false;
  bool _takingPicture = false;
  bool _flashEnabled = false;
  String? _cameraErrorText;

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 92,
    );
    if (file == null || !mounted) return;
    await Navigator.of(context).push<void>(
      NoSwipeBackMaterialPageRoute<void>(
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

  Future<void> _startCameraMode() async {
    if (_cameraModeEnabled || _initializingCamera) return;
    setState(() {
      _initializingCamera = true;
      _cameraErrorText = null;
    });
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('利用可能なカメラが見つかりません');
      }
      final CameraDescription camera = cameras.firstWhere(
        (CameraDescription item) =>
            item.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      await _cameraController?.dispose();
      final CameraController controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _cameraController = controller;
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) return;
      setState(() {
        _cameraModeEnabled = true;
        _initializingCamera = false;
        _flashEnabled = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraModeEnabled = false;
        _initializingCamera = false;
        _cameraErrorText = 'カメラを開始できませんでした';
      });
    }
  }

  Future<void> _captureAndContinue() async {
    final CameraController? controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _takingPicture) {
      return;
    }
    setState(() {
      _takingPicture = true;
    });
    try {
      final XFile file = await controller.takePicture();
      final String normalizedPath = await _normalizeSideCapture(file.path);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        NoSwipeBackMaterialPageRoute<void>(
          builder: (_) => ScanImageConfirmScreen(
            initialImagePath: normalizedPath,
            selectedGender: widget.selectedGender,
            goToSideProfileStepOnContinue: false,
            appBarTitle: '横顔をアップロード',
            laserThumbnailPath: widget.frontImagePath,
          ),
        ),
      );
    } finally {
      _takingPicture = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<String> _normalizeSideCapture(String path) async {
    try {
      final File file = File(path);
      if (!file.existsSync()) return path;
      final Uint8List bytes = await file.readAsBytes();
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) return path;
      final img.Image mirrored = img.flipHorizontal(decoded);
      final List<int> encoded = img.encodeJpg(mirrored, quality: 92);
      await file.writeAsBytes(encoded, flush: true);
      return file.path;
    } catch (_) {
      return path;
    }
  }

  Future<void> _toggleFlash() async {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final bool next = !_flashEnabled;
    try {
      await controller.setFlashMode(next ? FlashMode.always : FlashMode.off);
      if (!mounted) return;
      setState(() {
        _flashEnabled = next;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _flashEnabled = false;
      });
    }
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
                await _startCameraMode();
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

  Widget _buildCaptureButton() {
    final bool cameraReady =
        _cameraModeEnabled &&
        !_initializingCamera &&
        _cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_takingPicture;
    return SizedBox(
      width: 70,
      height: 70,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: cameraReady ? 0.95 : 0.45),
            width: 3,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Material(
            color: cameraReady ? Colors.white : Colors.white38,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: cameraReady ? _captureAndContinue : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraSurface() {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: Text(
          _cameraErrorText ?? 'カメラを開始できませんでした',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final Size previewSize =
        controller.value.previewSize ?? const Size(1080, 1920);
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: previewSize.height,
        height: previewSize.width,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildFlashToggle() {
    final bool enabled =
        _cameraModeEnabled &&
        !_initializingCamera &&
        _cameraController != null &&
        _cameraController!.value.isInitialized;
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? _toggleFlash : null,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            _flashEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            size: 22,
            color: enabled
                ? Colors.white.withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.42),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    if (_cameraModeEnabled) {
      return Center(child: _buildCaptureButton());
    }
    return _buildStartScanButton();
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
            fontSize: 22,
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
                        child: Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: _previewAspectRatio,
                              child:
                                  (_cameraModeEnabled && !_initializingCamera)
                                  ? _buildCameraSurface()
                                  : Image.asset(imagePath, fit: BoxFit.cover),
                            ),
                            if (_cameraModeEnabled)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: _buildFlashToggle(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 36,
                    right: 36,
                    bottom: 32,
                    child: _buildBottomAction(),
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
