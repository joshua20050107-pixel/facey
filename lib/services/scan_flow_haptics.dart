import 'package:flutter/services.dart';

class ScanFlowHaptics {
  const ScanFlowHaptics._();

  static void primary() {
    HapticFeedback.mediumImpact();
  }

  static void secondary() {
    HapticFeedback.selectionClick();
  }

  static void capture() {
    HapticFeedback.mediumImpact();
  }

  static void toggle() {
    HapticFeedback.selectionClick();
  }

  static void back() {
    HapticFeedback.lightImpact();
  }
}
