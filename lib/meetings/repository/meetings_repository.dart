import 'dart:async';
import 'package:chime/common/common.dart';
import 'package:chime/common/services/twilio_token_service.dart';
import 'package:chime/login/models/user_model.dart';
import 'package:chime/meetings/models/meeting_model.dart';
import 'package:get_it/get_it.dart';
import "package:logger/logger.dart";

class MeetingsRepository {
  final log = Logger();
  GetIt getIt = GetIt.instance;
  final PreferencesRepository prefRepo;
  final NetworkAwareApiRepository apiRepo;
  final TwilioTokenService _twilioTokenService = TwilioTokenService();

  MeetingsRepository({required this.prefRepo, required this.apiRepo});

  Future<List<Map<String, dynamic>>> getMeetings() async {
    try {
      // Mock list backed by Twilio-compatible room names for multi-device testing
      // Share these IDs with another device and use "Join Meeting" to join the same room.
      return [
        {
          'id': 'test-room', // stable room name
          'title': 'Test Room',
          'description': 'Join this from multiple phones to test Twilio',
          'isActive': true,
        },
        {'id': 'demo-room', 'title': 'Demo Room', 'description': 'Alternative demo room', 'isActive': true},
      ];
    } catch (error) {
      log.e("MeetingsRepository:::getMeetings::Error:$error");
      throw Exception('$error');
    }
  }

  /// Create a new meeting
  /// This should call your backend API that creates a Twilio Video room
  Future<MeetingModel> createMeeting({required String title, String? description, String? mediaRegion}) async {
    try {
      log.d("MeetingsRepository:::createMeeting::title: $title");

      // Create a stable, shareable room name based on the title to allow multi-device join.
      String roomName = _generateRoomNameFromTitle(title);
      if (roomName.isEmpty) {
        roomName = 'test-room';
      }
      // Get identity from stored user profile
      String identity = await _getPreferredIdentity() ?? 'user-${DateTime.now().millisecondsSinceEpoch}';

      // Generate Twilio access token
      String accessToken;
      try {
        accessToken = await _twilioTokenService.generateAccessToken(identity: identity, roomName: roomName);
        log.d("MeetingsRepository:::createMeeting::Generated access token successfully (length: ${accessToken.length})");
      } catch (e, stackTrace) {
        log.e("MeetingsRepository:::createMeeting::Token generation failed: $e");
        log.e("MeetingsRepository:::createMeeting::Stack trace: $stackTrace");
        throw Exception('Failed to generate access token: $e');
      }

      final meetingData = {
        'id': roomName, // use roomName as meeting id so others can join by this ID
        'title': title,
        'description': description,
        'roomName': roomName,
        'accessToken': accessToken,
        'identity': identity,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };

      return MeetingModel.fromJson(meetingData);
    } catch (error) {
      log.e("MeetingsRepository:::createMeeting::Error:$error");
      throw Exception('Failed to create meeting: $error');
    }
  }

  /// Join an existing meeting
  /// This should call your backend API to get an access token for the room
  Future<MeetingModel> joinMeeting({required String meetingId, String? name}) async {
    try {
      log.d("MeetingsRepository:::joinMeeting::meetingId: $meetingId");

      // Prefer provided name, then stored user profile, then fallback
      String identity = name?.trim().isNotEmpty == true
          ? name!.trim()
          : (await _getPreferredIdentity() ?? 'anonymous-${DateTime.now().millisecondsSinceEpoch}');

      String accessToken;
      try {
        accessToken = await _twilioTokenService.generateAccessToken(identity: identity, roomName: meetingId);
        log.d("MeetingsRepository:::joinMeeting::Generated access token successfully (length: ${accessToken.length})");
      } catch (e, stackTrace) {
        log.e("MeetingsRepository:::joinMeeting::Token generation failed: $e");
        log.e("MeetingsRepository:::joinMeeting::Stack trace: $stackTrace");
        throw Exception('Failed to generate access token: $e');
      }

      final meetingData = {
        'id': meetingId,
        'title': 'Joined Meeting',
        'roomName': meetingId,
        'accessToken': accessToken,
        'identity': identity,
        'isActive': true,
      };

      return MeetingModel.fromJson(meetingData);
    } catch (error) {
      log.e("MeetingsRepository:::joinMeeting::Error:$error");
      throw Exception('Failed to join meeting: $error');
    }
  }

  /// End meeting (host only - deletes the room)
  Future<bool> endMeeting({required String meetingId}) async {
    try {
      log.d("MeetingsRepository:::endMeeting::meetingId: $meetingId");

      // TODO: Replace with actual API call to your backend
      // The backend should call Twilio Video API to complete/delete the room
      // Note: Twilio rooms don't need to be explicitly deleted - they auto-complete when empty
      // But you can call the CompleteRoom API if needed

      // Example API call:
      // await apiRepo.postRequest(
      //   url: '${Constants.API_MAP['endMeeting']!}/$meetingId',
      // );

      return true;
    } catch (error) {
      log.e("MeetingsRepository:::endMeeting::Error:$error");
      throw Exception('Failed to end meeting: $error');
    }
  }

  String _generateRoomNameFromTitle(String title) {
    final normalized = title.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), '-').replaceAll(RegExp(r"-+"), '-');
    final trimmed = normalized.replaceAll(RegExp(r"^-+|-+$"), '');
    return trimmed.isEmpty ? 'test-room' : trimmed;
  }

  Future<String?> _getPreferredIdentity() async {
    try {
      final userJson = await prefRepo.getPreference(Constants.PREF_KEY_USER);
      if (userJson != null && userJson.isNotEmpty) {
        final user = UserModel.fromJson(userJson);
        if (user.name.trim().isNotEmpty) return user.name.trim();
        if (user.emailId.trim().isNotEmpty) return user.emailId.trim();
        if (user.mobileNo.trim().isNotEmpty) return user.mobileNo.trim();
      }
    } catch (e) {
      log.w("MeetingsRepository::_getPreferredIdentity::Error:$e");
    }
    return null;
  }
}
