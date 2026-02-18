import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../routes/no_swipe_back_material_page_route.dart';
import 'face_analysis_result_screen.dart';
import 'scan_next_screen.dart';
import '../widgets/top_header.dart';
import '../widgets/yomu_gender_two_choice.dart';

class ScanTabScreen extends StatefulWidget {
  const ScanTabScreen({super.key, required this.selectedGender});

  final YomuGender selectedGender;

  @override
  State<ScanTabScreen> createState() => _ScanTabScreenState();
}

class _ScanTabScreenState extends State<ScanTabScreen> {
  static const String _prefsBoxName = 'app_prefs';
  static const String _latestResultFrontImageKey = 'latest_result_front_image';
  static const String _latestResultSideImageKey = 'latest_result_side_image';
  int _currentPageIndex = 0;
  String? _latestResultFrontImagePath;
  String? _latestResultSideImagePath;

  @override
  void initState() {
    super.initState();
    _loadLatestResult();
  }

  void _loadLatestResult() {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    if (!mounted) return;
    setState(() {
      _latestResultFrontImagePath = box.get(_latestResultFrontImageKey);
      _latestResultSideImagePath = box.get(_latestResultSideImageKey);
    });
  }

  Widget _buildStartAnalysisButton(double scale) {
    final double buttonHeight = (58 * scale).clamp(44.0, 62.0);
    final double buttonRadius = (38 * scale).clamp(28.0, 40.0);
    final double textSize = (22 * scale).clamp(18.0, 24.0);

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(buttonRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF5B22FF), Color(0xFFB61DFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8C35FF).withValues(alpha: 0.5),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextButton(
          onPressed: () async {
            await Navigator.of(context).push(
              NoSwipeBackMaterialPageRoute<void>(
                builder: (_) =>
                    ScanNextScreen(selectedGender: widget.selectedGender),
              ),
            );
            _loadLatestResult();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.25),
            splashFactory: InkRipple.splashFactory,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
          ),
          child: Text(
            'スキャンする',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenLatestResultButton(double scale) {
    final double buttonHeight = (58 * scale).clamp(44.0, 62.0);
    final double buttonRadius = (38 * scale).clamp(28.0, 40.0);
    final double textSize = (22 * scale).clamp(18.0, 24.0);
    final String? path = _latestResultFrontImagePath;
    final bool enabled =
        path != null && path.isNotEmpty && File(path).existsSync();

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(buttonRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: enabled
                ? const [Color(0xFF5B22FF), Color(0xFFB61DFF)]
                : const [Color(0xFF444A57), Color(0xFF383D47)],
          ),
          boxShadow: [
            BoxShadow(
              color: (enabled ? const Color(0xFF8C35FF) : Colors.black)
                  .withValues(alpha: enabled ? 0.5 : 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextButton(
          onPressed: enabled
              ? () {
                  Navigator.of(context).push(
                    NoSwipeBackMaterialPageRoute<void>(
                      builder: (_) => FaceAnalysisResultScreen(
                        imagePath: path,
                        sideImagePath: _latestResultSideImagePath,
                      ),
                    ),
                  );
                }
              : null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
            overlayColor: Colors.white.withValues(alpha: 0.25),
            splashFactory: InkRipple.splashFactory,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
          ),
          child: Text(
            enabled ? '結果を見る' : '結果がありません',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlidingPages(double scale) {
    final double imageWidth = (420 * scale).clamp(260.0, 440.0);
    final String imagePath = widget.selectedGender == YomuGender.female
        ? 'assets/images/まま.png'
        : 'assets/images/いもり.png';
    return PageView(
      onPageChanged: (int index) {
        setState(() {
          _currentPageIndex = index;
        });
      },
      children: [
        Center(
          child: SizedBox(
            width: imageWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(imagePath, width: imageWidth, fit: BoxFit.contain),
                Positioned(
                  left: imageWidth * 0.16,
                  right: imageWidth * 0.16,
                  bottom: imageWidth * 0.09,
                  child: _buildStartAnalysisButton(scale),
                ),
              ],
            ),
          ),
        ),
        Center(
          child: SizedBox(
            width: imageWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 0.72,
                    child:
                        _latestResultFrontImagePath != null &&
                            _latestResultFrontImagePath!.isNotEmpty &&
                            File(_latestResultFrontImagePath!).existsSync()
                        ? Image.file(
                            File(_latestResultFrontImagePath!),
                            fit: BoxFit.cover,
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(
                                    0xFF212936,
                                  ).withValues(alpha: 0.95),
                                  const Color(
                                    0xFF111720,
                                  ).withValues(alpha: 0.98),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '直近の分析結果が\nここに表示されます',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFAEB7C8),
                                  fontSize: 18,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  left: imageWidth * 0.16,
                  right: imageWidth * 0.16,
                  bottom: imageWidth * 0.09,
                  child: _buildOpenLatestResultButton(scale),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(2, (int index) {
        final bool isActive = _currentPageIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isActive ? 22 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double widthScale = (constraints.maxWidth / 430).clamp(0.82, 1.0);
        final double heightScale = (constraints.maxHeight / 860).clamp(
          0.74,
          1.0,
        );
        final double scale = widthScale < heightScale
            ? widthScale
            : heightScale;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              const TopHeader(
                title: 'ビジュアル評価',
                titleStyle: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Transform.translate(
                offset: const Offset(3, -4),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'あなたの魅力と改善点を分析',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB9C0CF),
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildSlidingPages(scale)),
              const SizedBox(height: 8),
              _buildPageIndicator(),
              const SizedBox(height: 23),
            ],
          ),
        );
      },
    );
  }
}
