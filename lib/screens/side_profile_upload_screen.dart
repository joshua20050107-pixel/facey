import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  final ImagePicker _picker = ImagePicker();

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
