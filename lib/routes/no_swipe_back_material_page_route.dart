import 'package:flutter/material.dart';

class NoSwipeBackMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoSwipeBackMaterialPageRoute({
    required super.builder,
    super.settings,
    super.requestFocus,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
    super.barrierDismissible,
    super.traversalEdgeBehavior,
    super.directionalTraversalEdgeBehavior,
  });

  @override
  bool get popGestureEnabled => false;
}
