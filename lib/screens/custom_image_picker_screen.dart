import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class CustomImagePickerScreen extends StatefulWidget {
  const CustomImagePickerScreen({super.key, required this.maxSelection});

  final int maxSelection;

  @override
  State<CustomImagePickerScreen> createState() =>
      _CustomImagePickerScreenState();
}

class _CustomImagePickerScreenState extends State<CustomImagePickerScreen> {
  final List<AssetEntity> _assets = <AssetEntity>[];
  final List<AssetEntity> _selected = <AssetEntity>[];
  bool _loading = true;
  bool _permissionDenied = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();
    if (!mounted) return;
    if (!permission.hasAccess) {
      setState(() {
        _loading = false;
        _permissionDenied = true;
      });
      return;
    }

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (!mounted) return;
    if (albums.isEmpty) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final List<AssetEntity> assets = await albums.first.getAssetListPaged(
      page: 0,
      size: 400,
    );
    if (!mounted) return;
    setState(() {
      _assets
        ..clear()
        ..addAll(assets);
      _loading = false;
    });
  }

  void _toggleSelection(AssetEntity asset) {
    final int selectedIndex = _selected.indexWhere(
      (AssetEntity a) => a.id == asset.id,
    );
    if (selectedIndex >= 0) {
      setState(() {
        _selected.removeAt(selectedIndex);
      });
      return;
    }
    if (_selected.length >= widget.maxSelection) return;
    setState(() {
      _selected.add(asset);
    });
  }

  Future<void> _submitSelection() async {
    if (_selected.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
    });
    final List<String> paths = <String>[];
    for (final AssetEntity entity in _selected) {
      final File? file = await entity.file;
      if (file == null) continue;
      paths.add(file.path);
    }
    if (!mounted) return;
    Navigator.of(context).pop(paths);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ColoredBox(
          color: const Color(0xFFF3F3F5),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(top: 9, bottom: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8C9CE),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'キャンセル',
                        style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _selected.isEmpty ? null : _submitSelection,
                      child: Text(
                        '追加',
                        style: TextStyle(
                          color: _selected.isEmpty
                              ? const Color(0xFFB7B8BC)
                              : const Color(0xFF111216),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                )
              else if (_permissionDenied)
                Expanded(
                  child: Center(
                    child: Text(
                      '写真へのアクセスが必要です',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF3E4148),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else if (_assets.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      '画像がありません',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF3E4148),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                        ),
                    itemCount: _assets.length,
                    itemBuilder: (BuildContext context, int index) {
                      final AssetEntity asset = _assets[index];
                      final int selectedOrder = _selected.indexWhere(
                        (AssetEntity a) => a.id == asset.id,
                      );
                      final bool selected = selectedOrder >= 0;
                      final bool reachedLimit =
                          _selected.length >= widget.maxSelection;
                      final bool disabled = !selected && reachedLimit;
                      return GestureDetector(
                        onTap: disabled ? null : () => _toggleSelection(asset),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FutureBuilder<Uint8List?>(
                              future: asset.thumbnailDataWithSize(
                                const ThumbnailSize.square(320),
                              ),
                              builder:
                                  (
                                    BuildContext context,
                                    AsyncSnapshot<Uint8List?> snapshot,
                                  ) {
                                    final Uint8List? bytes = snapshot.data;
                                    if (bytes == null) {
                                      return ColoredBox(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                      );
                                    }
                                    return Image.memory(
                                      bytes,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    );
                                  },
                            ),
                            if (disabled)
                              ColoredBox(
                                color: Colors.black.withValues(alpha: 0.28),
                              ),
                            Positioned(
                              top: 7,
                              right: 7,
                              child: Container(
                                width: 25,
                                height: 25,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected
                                      ? const Color(0xFF007AFF)
                                      : Colors.black.withValues(alpha: 0.34),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    width: 1.6,
                                  ),
                                ),
                                child: selected
                                    ? Center(
                                        child: Text(
                                          '${selectedOrder + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
