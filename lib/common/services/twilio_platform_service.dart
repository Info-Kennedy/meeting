import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:chime/meetings/models/attendee_model.dart';

/// Platform channel service for Twilio Video SDK
/// Handles communication between Flutter and native iOS/Android code
class TwilioPlatformService {
  static const MethodChannel _channel = MethodChannel('com.twilio.video/twilio_sdk');
  static const EventChannel _participantsChannel = EventChannel('com.twilio.video/twilio_sdk_participants');
  static const EventChannel _roomEventChannel = EventChannel('com.twilio.video/twilio_sdk_events');

  final Logger log = Logger();

  // Streams for participants and room events
  Stream<List<AttendeeModel>>? _participantsStream;
  Stream<Map<String, dynamic>>? _roomEventStream;

  /// Stream of participants updates
  Stream<List<AttendeeModel>> get participantsStream {
    _participantsStream ??= _participantsChannel.receiveBroadcastStream().map((dynamic event) {
      try {
        if (event is List) {
          return event.map((e) => AttendeeModel.fromJson(Map<String, dynamic>.from(e))).toList();
        }
        return <AttendeeModel>[];
      } catch (e) {
        log.e("TwilioPlatformService:::Error parsing participants: $e");
        return <AttendeeModel>[];
      }
    });
    return _participantsStream!;
  }

  /// Stream of room events (e.g., room ended, audio/video state changed)
  Stream<Map<String, dynamic>> get roomEventStream {
    _roomEventStream ??= _roomEventChannel.receiveBroadcastStream().map((dynamic event) {
      try {
        if (event is Map) {
          return Map<String, dynamic>.from(event);
        }
        return <String, dynamic>{};
      } catch (e) {
        log.e("TwilioPlatformService:::Error parsing room event: $e");
        return <String, dynamic>{};
      }
    });
    return _roomEventStream!;
  }

  /// Connect to a Room with access token
  Future<bool> connectToRoom({
    required String accessToken,
    required String roomName,
    String? identity,
    bool enableAudio = true,
    bool enableVideo = true,
  }) async {
    try {
      log.d("TwilioPlatformService:::connectToRoom::roomName: $roomName");
      final result = await _channel.invokeMethod<bool>('connectToRoom', {
        'accessToken': accessToken,
        'roomName': roomName,
        'identity': identity,
        'enableAudio': enableAudio,
        'enableVideo': enableVideo,
      });
      return result ?? false;
    } catch (e) {
      log.e("TwilioPlatformService:::connectToRoom::Error: $e");
      return false;
    }
  }

  /// Disconnect from the current Room
  Future<bool> disconnectFromRoom() async {
    try {
      log.d("TwilioPlatformService:::disconnectFromRoom");
      final result = await _channel.invokeMethod<bool>('disconnectFromRoom');
      return result ?? false;
    } catch (e) {
      log.e("TwilioPlatformService:::disconnectFromRoom::Error: $e");
      return false;
    }
  }

  /// Mute/unmute audio
  Future<bool> setAudioEnabled(bool enabled) async {
    try {
      log.d("TwilioPlatformService:::setAudioEnabled::enabled: $enabled");
      final result = await _channel.invokeMethod<bool>('setAudioEnabled', {'enabled': enabled});
      return result ?? false;
    } catch (e) {
      log.e("TwilioPlatformService:::setAudioEnabled::Error: $e");
      return false;
    }
  }

  /// Enable/disable video
  Future<bool> setVideoEnabled(bool enabled) async {
    try {
      log.d("TwilioPlatformService:::setVideoEnabled::enabled: $enabled");
      final result = await _channel.invokeMethod<bool>('setVideoEnabled', {'enabled': enabled});
      return result ?? false;
    } catch (e) {
      log.e("TwilioPlatformService:::setVideoEnabled::Error: $e");
      return false;
    }
  }

  /// Check if audio is enabled
  Future<bool> isAudioEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAudioEnabled');
      return result ?? false;
    } catch (e) {
      log.e("TwilioPlatformService:::isAudioEnabled::Error: $e");
      return false;
    }
  }

  /// Check if video is enabled
  Future<bool> isVideoEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isVideoEnabled');
      return result ?? false;
    } catch (e) {
      log.e("TwilioPlatformService:::isVideoEnabled::Error: $e");
      return false;
    }
  }

  /// Start screen share (if supported)
  Future<bool> startScreenShare() async {
    try {
      log.d("TwilioPlatformService:::startScreenShare");
      final result = await _channel.invokeMethod<bool>('startScreenShare');
      return result ?? false;
    } catch (e) {
      log.e("TwilioPlatformService:::startScreenShare::Error: $e");
      return false;
    }
  }

  /// Stop screen share
  Future<bool> stopScreenShare() async {
    try {
      log.d("TwilioPlatformService:::stopScreenShare");
      final result = await _channel.invokeMethod<bool>('stopScreenShare');
      return result ?? false;
    } catch (e) {
      log.e("TwilioPlatformService:::stopScreenShare::Error: $e");
      return false;
    }
  }

  /// Check if screen share is active
  Future<bool> isScreenShareActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isScreenShareActive');
      return result ?? false;
    } catch (e) {
      log.e("TwilioPlatformService:::isScreenShareActive::Error: $e");
      return false;
    }
  }

  /// Get current list of participants
  Future<List<AttendeeModel>> getParticipants() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getParticipants');
      if (result != null) {
        return result.map((e) => AttendeeModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (e) {
      log.e("TwilioPlatformService:::getParticipants::Error: $e");
      return [];
    }
  }

  /// Get the platform view ID for local video
  /// This returns a view ID that can be used with PlatformView widgets
  Future<int?> getLocalVideoViewId() async {
    try {
      final result = await _channel.invokeMethod<int>('getLocalVideoViewId');
      return result;
    } catch (e) {
      log.e("TwilioPlatformService:::getLocalVideoViewId::Error: $e");
      return null;
    }
  }

  /// Get the platform view ID for a remote participant's video
  /// [participantId] - The identity/SID of the remote participant
  Future<int?> getRemoteVideoViewId(String participantId) async {
    try {
      final result = await _channel.invokeMethod<int>('getRemoteVideoViewId', {'participantId': participantId});
      return result;
    } catch (e) {
      log.e("TwilioPlatformService:::getRemoteVideoViewId::Error: $e");
      return null;
    }
  }

  /// Get the platform view ID for local screen share video
  Future<int?> getLocalScreenShareViewId() async {
    try {
      final result = await _channel.invokeMethod<int>('getLocalScreenShareViewId');
      return result;
    } catch (e) {
      log.e("TwilioPlatformService:::getLocalScreenShareViewId::Error: $e");
      return null;
    }
  }

  /// Dispose and cleanup
  void dispose() {
    // Streams will be cleaned up automatically
    log.d("TwilioPlatformService:::dispose");
  }
}
