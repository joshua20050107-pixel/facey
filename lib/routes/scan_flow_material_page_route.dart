import 'package:flutter/material.dart';

class ScanFlowMaterialPageRoute<T> extends MaterialPageRoute<T> {
  static Route<dynamic>? _verticalReverseTargetRoute;

  static void armVerticalReverseFor(Route<dynamic>? route) {
    _verticalReverseTargetRoute = route;
  }

  ScanFlowMaterialPageRoute({
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

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => false;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (secondaryAnimation.status != AnimationStatus.dismissed) {
      return child;
    }
    if (identical(this, _verticalReverseTargetRoute) &&
        animation.status == AnimationStatus.dismissed) {
      _verticalReverseTargetRoute = null;
    }
    if (identical(this, _verticalReverseTargetRoute) &&
        animation.status == AnimationStatus.reverse) {
      final Animation<Offset> reverseOffsetAnimation =
          Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1)).animate(
            CurvedAnimation(
              parent: ReverseAnimation(animation),
              curve: Curves.easeInOutCubic,
            ),
          );
      return SlideTransition(position: reverseOffsetAnimation, child: child);
    }
    return super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
