import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../routes/no_swipe_back_material_page_route.dart';
import '../widgets/yomu_gender_two_choice.dart';
import 'laser_analyze_screen.dart';
import 'side_profile_upload_screen.dart';

class ScanImageConfirmScreen extends StatefulWidget {
  const ScanImageConfirmScreen({
    super.key,
    required this.initialImagePath,
    required this.selectedGender,
    required this.goToSideProfileStepOnContinue,
    this.isConditionFlow = false,
    this.appBarTitle = '正面からの画像をアップロード',
    this.laserThumbnailPath,
  });

  final String initialImagePath;
  final YomuGender selectedGender;
  final bool goToSideProfileStepOnContinue;
  final bool isConditionFlow;
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
              child: const Text('画像を選択', style: TextStyle(color: Colors.white)),
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

  Widget _buildContinueButton() {
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
          onPressed: () async {
            if (widget.goToSideProfileStepOnContinue) {
              final String persistentFrontImagePath = await _persistScanImage(
                _currentImagePath,
                prefix: 'front',
              );
              if (!mounted) return;
              Navigator.of(context).push(
                NoSwipeBackMaterialPageRoute<void>(
                  builder: (_) => SideProfileUploadScreen(
                    selectedGender: widget.selectedGender,
                    frontImagePath: persistentFrontImagePath,
                  ),
                ),
              );
              return;
            }
            final String laserImagePath = await _persistScanImage(
              widget.laserThumbnailPath ?? _currentImagePath,
              prefix: 'front',
            );
            final bool hasSeparateSideImage =
                widget.laserThumbnailPath != null &&
                widget.laserThumbnailPath!.isNotEmpty;
            final String? sideImagePath = hasSeparateSideImage
                ? await _persistScanImage(_currentImagePath, prefix: 'side')
                : null;
            if (!mounted) return;
            Navigator.of(context).push(
              NoSwipeBackMaterialPageRoute<void>(
                builder: (_) => LaserAnalyzeShell(
                  imagePath: laserImagePath,
                  sideImagePath: sideImagePath,
                  isConditionFlow: widget.isConditionFlow,
                ),
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

  Future<String> _persistScanImage(
    String sourcePath, {
    required String prefix,
  }) async {
    final File source = File(sourcePath);
    if (!source.existsSync()) return sourcePath;
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory imageDir = Directory('${appDir.path}/scan_results');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    final int dotIndex = sourcePath.lastIndexOf('.');
    final String ext = dotIndex >= 0
        ? sourcePath.substring(dotIndex).toLowerCase()
        : '.jpg';
    final String targetPath =
        '${imageDir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
    await source.copy(targetPath);
    return targetPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.appBarTitle,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
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
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF042448),
                    Color(0xFF021A35),
                    Color(0xFF000D20),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1.05),
                  radius: 1.12,
                  colors: [
                    Color(0x802766AA),
                    Color(0x3323588A),
                    Color(0x00071B36),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xD9001024),
                    Color(0x00001024),
                    Color(0xD9001024),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000817),
                    Color(0x80000713),
                    Color(0xE6000610),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
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
                  _buildContinueButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
