import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget to display Twilio Video SDK video tracks using Platform Views
///
/// This widget wraps the native video view (AndroidView for Android, UiKitView for iOS)
/// that renders the Twilio Video track.
class TwilioVideoView extends StatelessWidget {
  /// The view ID returned from the native platform
  final int viewId;

  /// Whether this is a local or remote video view
  final bool isLocal;

  /// Whether this view is for screen share (local only currently)
  final bool isScreen;

  /// The participant ID (for remote videos)
  final String? participantId;

  const TwilioVideoView({super.key, required this.viewId, this.isLocal = false, this.isScreen = false, this.participantId});

  @override
  Widget build(BuildContext context) {
    final params = {'viewId': viewId, 'isLocal': isLocal, 'isScreen': isScreen, 'participantId': participantId};
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: 'twilio_video_view',
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int id) {
          // View created successfully
          debugPrint('TwilioVideoView: Android view created with id: $id');
        },
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: 'twilio_video_view',
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int id) {
          // View created successfully
          debugPrint('TwilioVideoView: iOS view created with id: $id');
        },
      );
    } else {
      // Unsupported platform
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text('Video not supported on this platform', style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }
}
