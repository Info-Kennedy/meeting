import 'dart:async';
import 'package:chime/meetings/models/attendee_model.dart';
import 'package:logger/logger.dart';
import 'package:chime/common/services/twilio_platform_service.dart';

/// Service to handle Twilio Video SDK operations
///
/// This service uses platform channels to communicate with native iOS/Android Twilio Video SDK implementations
class TwilioService {
  final log = Logger();
  final TwilioPlatformService _platformService = TwilioPlatformService();

  bool _isAudioEnabled = false;
  bool _isVideoEnabled = false;
  bool _isScreenShareActive = false;
  bool _isConnected = false;

  StreamSubscription<List<AttendeeModel>>? _participantsSubscription;
  StreamSubscription<Map<String, dynamic>>? _roomEventSubscription;

  /// Stream of participants list
  Stream<List<AttendeeModel>> get participantsStream => _platformService.participantsStream;

  /// Stream of room disconnected events
  Stream<String> get roomDisconnectedStream {
    // Transform room events stream to extract room disconnected events
    return _platformService.roomEventStream
        .where((event) => event['type'] == 'room_disconnected' || event['type'] == 'room_left')
        .map((event) => event['data'] ?? 'room_disconnected')
        .cast<String>();
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
      log.d("TwilioService:::connectToRoom::roomName: $roomName");

      // Connect to room via platform channel
      final success = await _platformService.connectToRoom(
        accessToken: accessToken,
        roomName: roomName,
        identity: identity,
        enableAudio: enableAudio,
        enableVideo: enableVideo,
      );

      if (success) {
        _isConnected = true;

        // Set up event listeners
        _participantsSubscription = _platformService.participantsStream.listen(
          (participants) {
            log.d("TwilioService:::Participants updated: ${participants.length}");
          },
          onError: (error) {
            log.e("TwilioService:::Participants stream error: $error");
          },
        );

        _roomEventSubscription = _platformService.roomEventStream.listen(
          (event) {
            log.d("TwilioService:::Room event: ${event['type']}");
            if (event['type'] == 'audioStateChanged') {
              _isAudioEnabled = event['enabled'] as bool? ?? false;
            } else if (event['type'] == 'videoStateChanged') {
              _isVideoEnabled = event['enabled'] as bool? ?? false;
            } else if (event['type'] == 'screenShareStateChanged') {
              _isScreenShareActive = event['active'] as bool? ?? false;
            } else if (event['type'] == 'room_disconnected') {
              _isConnected = false;
            }
          },
          onError: (error) {
            log.e("TwilioService:::Room event stream error: $error");
          },
        );

        // Update local state
        if (enableAudio) {
          _isAudioEnabled = await _platformService.isAudioEnabled();
        }
        if (enableVideo) {
          _isVideoEnabled = await _platformService.isVideoEnabled();
        }

        log.d("TwilioService:::connectToRoom::Successfully connected to room");
      }

      return success;
    } catch (e) {
      log.e("TwilioService:::connectToRoom::Error: $e");
      return false;
    }
  }

  /// Mute/unmute audio
  Future<bool> setAudioEnabled(bool enabled) async {
    try {
      log.d("TwilioService:::setAudioEnabled::enabled: $enabled");
      final success = await _platformService.setAudioEnabled(enabled);
      if (success) {
        _isAudioEnabled = enabled;
      }
      return success;
    } catch (e) {
      log.e("TwilioService:::setAudioEnabled::Error: $e");
      _isAudioEnabled = !enabled;
      return false;
    }
  }

  /// Toggle audio mute/unmute
  Future<bool> toggleAudioMute() async {
    try {
      final currentState = _isAudioEnabled;
      log.d("TwilioService:::toggleAudioMute::Current state: $currentState");
      final success = await _platformService.setAudioEnabled(!currentState);
      if (success) {
        _isAudioEnabled = !currentState;
      }
      return success;
    } catch (e) {
      log.e("TwilioService:::toggleAudioMute::Error: $e");
      return false;
    }
  }

  /// Check if audio is enabled (asynchronous - gets current state from platform)
  Future<bool> isAudioEnabledAsync() async {
    try {
      _isAudioEnabled = await _platformService.isAudioEnabled();
      return _isAudioEnabled;
    } catch (e) {
      log.e("TwilioService:::isAudioEnabledAsync::Error: $e");
      return _isAudioEnabled;
    }
  }

  /// Check if audio is enabled (synchronous - returns cached value)
  bool get isAudioEnabled => _isAudioEnabled;

  /// Enable/disable video
  Future<bool> setVideoEnabled(bool enabled) async {
    try {
      log.d("TwilioService:::setVideoEnabled::enabled: $enabled");
      final success = await _platformService.setVideoEnabled(enabled);
      if (success) {
        _isVideoEnabled = enabled;
      }
      return success;
    } catch (e) {
      log.e("TwilioService:::setVideoEnabled::Error: $e");
      _isVideoEnabled = !enabled;
      return false;
    }
  }

  /// Toggle video on/off
  Future<bool> toggleVideo() async {
    try {
      if (_isVideoEnabled) {
        return await setVideoEnabled(false);
      } else {
        return await setVideoEnabled(true);
      }
    } catch (e) {
      log.e("TwilioService:::toggleVideo::Error: $e");
      return false;
    }
  }

  /// Check if video is enabled (asynchronous - gets current state from platform)
  Future<bool> isVideoEnabledAsync() async {
    try {
      _isVideoEnabled = await _platformService.isVideoEnabled();
      return _isVideoEnabled;
    } catch (e) {
      log.e("TwilioService:::isVideoEnabledAsync::Error: $e");
      return _isVideoEnabled;
    }
  }

  /// Check if video is enabled (synchronous - returns cached value)
  bool get isVideoEnabled => _isVideoEnabled;

  /// Check if connected to room
  bool get isConnected => _isConnected;

  /// Start screen sharing
  Future<bool> startScreenShare() async {
    try {
      log.d("TwilioService:::startScreenShare");
      final success = await _platformService.startScreenShare();
      if (success) {
        _isScreenShareActive = true;
      }
      return success;
    } catch (e) {
      log.e("TwilioService:::startScreenShare::Error: $e");
      _isScreenShareActive = false;
      return false;
    }
  }

  /// Stop screen sharing
  Future<bool> stopScreenShare() async {
    try {
      log.d("TwilioService:::stopScreenShare");
      final success = await _platformService.stopScreenShare();
      if (success) {
        _isScreenShareActive = false;
      }
      return success;
    } catch (e) {
      log.e("TwilioService:::stopScreenShare::Error: $e");
      return false;
    }
  }

  /// Check if screen share is active (asynchronous - gets current state from platform)
  Future<bool> isScreenShareActiveAsync() async {
    try {
      _isScreenShareActive = await _platformService.isScreenShareActive();
      return _isScreenShareActive;
    } catch (e) {
      log.e("TwilioService:::isScreenShareActiveAsync::Error: $e");
      return _isScreenShareActive;
    }
  }

  /// Check if screen share is active (synchronous - returns cached value)
  bool get isScreenShareActive => _isScreenShareActive;

  /// Get list of participants
  Future<List<AttendeeModel>> getParticipants() async {
    try {
      return await _platformService.getParticipants();
    } catch (e) {
      log.e("TwilioService:::getParticipants::Error: $e");
      return [];
    }
  }

  /// Get the platform view ID for local video
  Future<int?> getLocalVideoViewId() async {
    try {
      return await _platformService.getLocalVideoViewId();
    } catch (e) {
      log.e("TwilioService:::getLocalVideoViewId::Error: $e");
      return null;
    }
  }

  /// Get the platform view ID for a remote participant's video
  Future<int?> getRemoteVideoViewId(String participantId) async {
    try {
      return await _platformService.getRemoteVideoViewId(participantId);
    } catch (e) {
      log.e("TwilioService:::getRemoteVideoViewId::Error: $e");
      return null;
    }
  }

  /// Get the platform view ID for local screen share
  Future<int?> getLocalScreenShareViewId() async {
    try {
      return await _platformService.getLocalScreenShareViewId();
    } catch (e) {
      log.e("TwilioService:::getLocalScreenShareViewId::Error: $e");
      return null;
    }
  }

  /// Disconnect from the Room
  Future<bool> disconnectFromRoom() async {
    try {
      log.d("TwilioService:::disconnectFromRoom");

      // Cancel subscriptions
      await _participantsSubscription?.cancel();
      await _roomEventSubscription?.cancel();
      _participantsSubscription = null;
      _roomEventSubscription = null;

      // Disconnect from room via platform channel
      final success = await _platformService.disconnectFromRoom();

      _isConnected = false;
      _isAudioEnabled = false;
      _isVideoEnabled = false;
      _isScreenShareActive = false;

      return success;
    } catch (e) {
      log.e("TwilioService:::disconnectFromRoom::Error: $e");
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _participantsSubscription?.cancel();
    _roomEventSubscription?.cancel();
    _platformService.dispose();
    log.d("TwilioService:::dispose");
  }
}
