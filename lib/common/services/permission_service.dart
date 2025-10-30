import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:logger/logger.dart';

enum MeetingPermission { microphone, camera, storage }

class PermissionService {
  final log = Logger();

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await permission_handler.Permission.microphone.request();
      log.d("PermissionService:::Microphone permission status: $status");
      return status.isGranted;
    } catch (e) {
      log.e("PermissionService:::Error requesting microphone permission: $e");
      return false;
    }
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      final status = await permission_handler.Permission.camera.request();
      log.d("PermissionService:::Camera permission status: $status");
      return status.isGranted;
    } catch (e) {
      log.e("PermissionService:::Error requesting camera permission: $e");
      return false;
    }
  }

  /// Check microphone permission
  Future<bool> checkMicrophonePermission() async {
    try {
      final status = await permission_handler.Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      log.e("PermissionService:::Error checking microphone permission: $e");
      return false;
    }
  }

  /// Check camera permission
  Future<bool> checkCameraPermission() async {
    try {
      final status = await permission_handler.Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      log.e("PermissionService:::Error checking camera permission: $e");
      return false;
    }
  }

  /// Request all meeting permissions (microphone, camera)
  Future<Map<MeetingPermission, bool>> requestMeetingPermissions() async {
    final results = <MeetingPermission, bool>{};

    final micGranted = await requestMicrophonePermission();
    results[MeetingPermission.microphone] = micGranted;

    final cameraGranted = await requestCameraPermission();
    results[MeetingPermission.camera] = cameraGranted;

    log.d("PermissionService:::Meeting permissions result: $results");
    return results;
  }

  /// Check all meeting permissions
  Future<Map<MeetingPermission, bool>> checkMeetingPermissions() async {
    final results = <MeetingPermission, bool>{};

    final micGranted = await checkMicrophonePermission();
    results[MeetingPermission.microphone] = micGranted;

    final cameraGranted = await checkCameraPermission();
    results[MeetingPermission.camera] = cameraGranted;

    return results;
  }

  /// Request screen sharing permission (platform specific - may need platform channels)
  /// Note: Screen sharing permissions are handled differently on different platforms
  Future<bool> requestScreenSharePermission() async {
    try {
      // On Android 13+ (API 33+), apps must request the notifications permission.
      // Foreground services for screen capture rely on a visible notification.
      if (Platform.isAndroid) {
        // permission_handler maps to runtime 'notification' on Android 13+
        final notifStatus = await permission_handler.Permission.notification.status;
        if (!notifStatus.isGranted) {
          final requested = await permission_handler.Permission.notification.request();
          log.d("PermissionService:::Notification permission requested for screen share: $requested");
          // Do not hard-fail if denied; MediaProjection may still work but OEMs can blank frames without a visible notification.
        }
      }
      log.d("PermissionService:::Screen share permission requested");
      return true;
    } catch (e) {
      log.e("PermissionService:::Error requesting screen share permission: $e");
      return false;
    }
  }

  /// Open app settings if permissions are permanently denied
  Future<bool> openAppSettings() async {
    try {
      return await permission_handler.openAppSettings();
    } catch (e) {
      log.e("PermissionService:::Error opening app settings: $e");
      return false;
    }
  }
}
