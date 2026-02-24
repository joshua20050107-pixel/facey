import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionService {
  static bool _isAllowedStatus(PermissionStatus status) {
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  static Future<bool> isEnabled() async {
    if (kIsWeb) return false;
    final PermissionStatus status = await Permission.notification.status;
    return _isAllowedStatus(status);
  }

  static Future<bool> requestEnable() async {
    if (kIsWeb) return false;
    PermissionStatus status = await Permission.notification.status;
    if (_isAllowedStatus(status)) return true;
    status = await Permission.notification.request();
    return _isAllowedStatus(status);
  }

  static Future<bool> openSettings() async {
    return openAppSettings();
  }
}
