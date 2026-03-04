import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../routes/scan_flow_material_page_route.dart';
import '../services/scan_flow_haptics.dart';
import '../widgets/yomu_gender_two_choice.dart';
import 'side_profile_upload_screen.dart';

class ScanImageConfirmScreen extends StatefulWidget {
  const ScanImageConfirmScreen({
    super.key,
    required this.initialImagePath,
    required this.selectedGender,
    required this.goToSideProfileStepOnContinue,
    this.isConditionFlow = false,
    this.appBarTitle = '正面からの画像をアップロード',
    this.cameraRetakeMode = false,
    this.saveToGrowthRecordMode = false,
    this.onSavedGrowthImage,
    this.laserThumbnailPath,
  });

  final String initialImagePath;
  final YomuGender selectedGender;
  final bool goToSideProfileStepOnContinue;
  final bool isConditionFlow;
  final String appBarTitle;
  final bool cameraRetakeMode;
  final bool saveToGrowthRecordMode;
  final ValueChanged<String>? onSavedGrowthImage;
  final String? laserThumbnailPath;

  @override
  State<ScanImageConfirmScreen> createState() => _ScanImageConfirmScreenState();
}

class _ScanImageConfirmScreenState extends State<ScanImageConfirmScreen> {
  static const String _prefsBoxName = 'app_prefs';
  static const String _latestResultFrontImageKey = 'latest_result_front_image';
  static const String _latestResultSideImageKey = 'latest_result_side_image';
  static const String _latestResultOverallScoreKey =
      'latest_result_overall_score';
  static const String _latestResultPotentialScoreKey =
      'latest_result_potential_score';
  static const String _resultOverallSumKey = 'result_overall_sum';
  static const String _resultPotentialSumKey = 'result_potential_sum';
  static const String _resultCountKey = 'result_count';
  static const String _lastAggregatedResultIdKey = 'last_aggregated_result_id';
  static const String _resultMonthlyScoresKey = 'result_monthly_scores';
  static const String _pendingFaceAnalysisUntilMsKey =
      'pending_face_analysis_until_ms';
  static const String _pendingConditionAnalysisUntilMsKey =
      'pending_condition_analysis_until_ms';
  static const String _homeScanTargetPageKey = 'home_scan_target_page';
  static const String _homeScanTargetAppliedAckKey =
      'home_scan_target_applied_ack';
  static const String _activityScanTargetPageKey = 'activity_scan_target_page';
  static const String _activityScanTargetAppliedAckKey =
      'activity_scan_target_applied_ack';
  static const String _conditionLatestResultFrontImageKey =
      'condition_latest_result_front_image';
  static const String _conditionLatestResultSideImageKey =
      'condition_latest_result_side_image';
  static const String _conditionResultFrontImageHistoryKey =
      'condition_result_front_image_history';
  static const String _resultFrontImageHistoryKey =
      'result_front_image_history';
  static const String _resultFrontImageHistoryMetaKey =
      'result_front_image_history_meta';
  static const double _previewAspectRatio = 1057 / 1403;
  final ImagePicker _picker = ImagePicker();
  late String _currentImagePath;
  CameraController? _cameraController;
  bool _cameraModeEnabled = false;
  bool _initializingCamera = false;
  bool _takingPicture = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.initialImagePath;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
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
                ScanFlowHaptics.secondary();
                Navigator.of(context).pop();
                await _startRetakeCameraMode();
              },
              child: const Text(
                '自撮りを撮影',
                style: TextStyle(color: Colors.white),
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                ScanFlowHaptics.secondary();
                Navigator.of(context).pop();
                await _replaceImage(ImageSource.gallery);
              },
              child: const Text('画像を選択', style: TextStyle(color: Colors.white)),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              ScanFlowHaptics.back();
              Navigator.of(context).pop();
            },
            isDefaultAction: true,
            child: const Text('キャンセル', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Future<void> _startRetakeCameraMode() async {
    if (_cameraModeEnabled || _initializingCamera) return;
    if (widget.cameraRetakeMode) {
      await _deleteTemporaryImageIfSafe(_currentImagePath);
    }
    setState(() {
      _initializingCamera = true;
    });
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('利用可能なカメラが見つかりません');
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
        _initializingCamera = false;
        _cameraModeEnabled = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializingCamera = false;
        _cameraModeEnabled = false;
      });
    }
  }

  Future<void> _captureRetakeAndApply() async {
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
      final String previousPath = _currentImagePath;
      final XFile file = await controller.takePicture();
      final String normalizedPath = await _normalizeFrontCapture(file.path);
      if (!mounted) return;
      setState(() {
        _currentImagePath = normalizedPath;
        _cameraModeEnabled = false;
      });
      await _deleteTemporaryImageIfSafe(previousPath);
    } finally {
      _takingPicture = false;
      if (mounted) setState(() {});
    }
  }

  Future<String> _normalizeFrontCapture(String path) async {
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

  Future<void> _deleteTemporaryImageIfSafe(String path) async {
    try {
      final File file = File(path);
      if (!file.existsSync()) return;
      final String normalized = file.absolute.path;
      final Directory tempDir = await getTemporaryDirectory();
      final bool isTemporary =
          normalized.startsWith(tempDir.path) ||
          normalized.contains('/tmp/') ||
          normalized.contains('/Caches/') ||
          normalized.contains('/cache/');
      if (!isTemporary) return;
      await file.delete();
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  Widget _buildRetakeCaptureButton() {
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
              onTap: cameraReady
                  ? () {
                      ScanFlowHaptics.capture();
                      _captureRetakeAndApply();
                    }
                  : null,
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
          _initializingCamera ? 'カメラを起動中...' : 'カメラを開始できませんでした',
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

  Widget _buildUseAnotherButton() {
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
          onPressed: () async {
            ScanFlowHaptics.secondary();
            if (widget.cameraRetakeMode) {
              await _startRetakeCameraMode();
              return;
            }
            await _showPickerOptions();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          ),
          child: Text(
            widget.cameraRetakeMode ? 'もう一度撮影' : '別の画像を選択',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
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
            ScanFlowHaptics.primary();
            if (widget.saveToGrowthRecordMode) {
              final String savedPath = await _saveToGrowthRecord();
              widget.onSavedGrowthImage?.call(savedPath);
              if (!mounted) return;
              Navigator.of(context).pop<String>(savedPath);
              return;
            }
            if (widget.goToSideProfileStepOnContinue) {
              final String persistentFrontImagePath = await _persistScanImage(
                _currentImagePath,
                prefix: 'front',
              );
              if (!mounted) return;
              Navigator.of(context).push(
                ScanFlowMaterialPageRoute<void>(
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
            if (!widget.isConditionFlow) {
              final Box<String> prefs = Hive.box<String>(_prefsBoxName);
              await prefs.put(_latestResultFrontImageKey, laserImagePath);
              if (sideImagePath != null && sideImagePath.isNotEmpty) {
                await prefs.put(_latestResultSideImageKey, sideImagePath);
              } else {
                await prefs.delete(_latestResultSideImageKey);
              }
              await _persistGrowthSummaryForFaceFlow(
                frontImagePath: laserImagePath,
                sideImagePath: sideImagePath,
              );
              final int pendingUntilMs =
                  DateTime.now().millisecondsSinceEpoch + 8000;
              await prefs.put(
                _pendingFaceAnalysisUntilMsKey,
                pendingUntilMs.toString(),
              );
              final String homePageAckToken = DateTime.now()
                  .microsecondsSinceEpoch
                  .toString();
              await prefs.delete(_homeScanTargetAppliedAckKey);
              await prefs.put(_homeScanTargetPageKey, '1:$homePageAckToken');
              await WidgetsBinding.instance.endOfFrame;
              await _waitHomeTargetPageApplied(prefs, homePageAckToken);
              if (!mounted) return;
              final NavigatorState navigator = Navigator.of(context);
              final Route<dynamic>? currentRoute = ModalRoute.of(context);
              final int removeCount = hasSeparateSideImage ? 3 : 1;
              if (currentRoute != null) {
                for (int i = 0; i < removeCount; i++) {
                  if (!navigator.canPop()) break;
                  navigator.removeRouteBelow(currentRoute);
                }
              }
              if (navigator.canPop()) {
                ScanFlowMaterialPageRoute.armVerticalReverseFor(currentRoute);
                navigator.pop();
              }
              return;
            }
            final Box<String> prefs = Hive.box<String>(_prefsBoxName);
            await prefs.put(
              _conditionLatestResultFrontImageKey,
              laserImagePath,
            );
            if (sideImagePath != null && sideImagePath.isNotEmpty) {
              await prefs.put(
                _conditionLatestResultSideImageKey,
                sideImagePath,
              );
            } else {
              await prefs.delete(_conditionLatestResultSideImageKey);
            }
            await _persistConditionHistory(frontImagePath: laserImagePath);
            final int pendingUntilMs =
                DateTime.now().millisecondsSinceEpoch + 8000;
            await prefs.put(
              _pendingConditionAnalysisUntilMsKey,
              pendingUntilMs.toString(),
            );
            final String activityPageAckToken = DateTime.now()
                .microsecondsSinceEpoch
                .toString();
            await prefs.delete(_activityScanTargetAppliedAckKey);
            await prefs.put(
              _activityScanTargetPageKey,
              '1:$activityPageAckToken',
            );
            await WidgetsBinding.instance.endOfFrame;
            await _waitActivityTargetPageApplied(prefs, activityPageAckToken);
            if (!mounted) return;
            final NavigatorState navigator = Navigator.of(context);
            final Route<dynamic>? currentRoute = ModalRoute.of(context);
            if (currentRoute != null && navigator.canPop()) {
              navigator.removeRouteBelow(currentRoute);
            }
            if (navigator.canPop()) {
              ScanFlowMaterialPageRoute.armVerticalReverseFor(currentRoute);
              navigator.pop();
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          ),
          child: Text(
            widget.saveToGrowthRecordMode ? '保存' : '進む',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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

  Future<String> _saveToGrowthRecord() async {
    final String persistentFrontImagePath = await _persistScanImage(
      _currentImagePath,
      prefix: 'front',
    );
    final Box<String> box = Hive.box<String>(_prefsBoxName);

    final String historyRaw = box.get(_resultFrontImageHistoryKey) ?? '';
    final List<String> history = historyRaw
        .split('\n')
        .where((String p) => p.isNotEmpty)
        .toList();
    history.remove(persistentFrontImagePath);
    history.insert(0, persistentFrontImagePath);
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
      return item['path'] == persistentFrontImagePath;
    });
    normalized.insert(0, <String, dynamic>{
      'path': persistentFrontImagePath,
      'addedAt': DateTime.now().toIso8601String(),
      'imageOnly': true,
    });
    if (normalized.length > 120) {
      normalized.removeRange(120, normalized.length);
    }
    await box.put(_resultFrontImageHistoryMetaKey, jsonEncode(normalized));

    return persistentFrontImagePath;
  }

  Future<void> _persistGrowthSummaryForFaceFlow({
    required String frontImagePath,
    String? sideImagePath,
  }) async {
    const int overallScore = 20;
    const int potentialScore = 40;
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    await box.put(_latestResultOverallScoreKey, overallScore.toString());
    await box.put(_latestResultPotentialScoreKey, potentialScore.toString());

    final String resultId = '$frontImagePath|$overallScore|$potentialScore';
    final String? lastAggregatedId = box.get(_lastAggregatedResultIdKey);
    if (lastAggregatedId != resultId) {
      final int currentOverallSum =
          int.tryParse(box.get(_resultOverallSumKey) ?? '') ?? 0;
      final int currentPotentialSum =
          int.tryParse(box.get(_resultPotentialSumKey) ?? '') ?? 0;
      final int currentCount =
          int.tryParse(box.get(_resultCountKey) ?? '') ?? 0;

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
    }

    final String historyRaw = box.get(_resultFrontImageHistoryKey) ?? '';
    final List<String> history = historyRaw
        .split('\n')
        .where((String p) => p.isNotEmpty)
        .toList();
    history.remove(frontImagePath);
    history.insert(0, frontImagePath);
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
      return item['path'] == frontImagePath;
    });
    final Map<String, dynamic> metaItem = <String, dynamic>{
      'path': frontImagePath,
      'addedAt': DateTime.now().toIso8601String(),
    };
    if (sideImagePath != null && sideImagePath.isNotEmpty) {
      metaItem['sidePath'] = sideImagePath;
    }
    normalized.insert(0, metaItem);
    if (normalized.length > 120) {
      normalized.removeRange(120, normalized.length);
    }
    await box.put(_resultFrontImageHistoryMetaKey, jsonEncode(normalized));
  }

  Future<void> _waitHomeTargetPageApplied(
    Box<String> prefs,
    String ackToken,
  ) async {
    const Duration timeout = Duration(milliseconds: 280);
    const Duration poll = Duration(milliseconds: 12);
    final DateTime deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final String? ack = prefs.get(_homeScanTargetAppliedAckKey);
      if (ack == ackToken) return;
      await Future<void>.delayed(poll);
    }
  }

  Future<void> _waitActivityTargetPageApplied(
    Box<String> prefs,
    String ackToken,
  ) async {
    const Duration timeout = Duration(milliseconds: 280);
    const Duration poll = Duration(milliseconds: 12);
    final DateTime deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final String? ack = prefs.get(_activityScanTargetAppliedAckKey);
      if (ack == ackToken) return;
      await Future<void>.delayed(poll);
    }
  }

  Future<void> _persistConditionHistory({
    required String frontImagePath,
  }) async {
    final Box<String> box = Hive.box<String>(_prefsBoxName);
    final String historyRaw =
        box.get(_conditionResultFrontImageHistoryKey) ?? '';
    final List<String> history = historyRaw
        .split('\n')
        .where((String p) => p.isNotEmpty)
        .toList();
    history.remove(frontImagePath);
    history.insert(0, frontImagePath);
    if (history.length > 120) {
      history.removeRange(120, history.length);
    }
    await box.put(_conditionResultFrontImageHistoryKey, history.join('\n'));
  }

  Future<void> _backToScanStart() async {
    if (_cameraModeEnabled || _initializingCamera) {
      await _cameraController?.dispose();
      _cameraController = null;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _backToScanStart();
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 36),
            onPressed: () async {
              ScanFlowHaptics.back();
              await _backToScanStart();
            },
          ),
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
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: double.infinity,
                            child: AspectRatio(
                              aspectRatio: _previewAspectRatio,
                              child: _cameraModeEnabled
                                  ? _buildCameraSurface()
                                  : Image.file(
                                      File(_currentImagePath),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_cameraModeEnabled)
                      Center(child: _buildRetakeCaptureButton())
                    else ...[
                      _buildUseAnotherButton(),
                      const SizedBox(height: 14),
                      _buildContinueButton(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
