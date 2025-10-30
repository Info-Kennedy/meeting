// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:chime/common/common.dart';
import 'package:chime/common/services/twilio_service.dart';
import 'package:chime/common/services/permission_service.dart';
import 'package:chime/meetings/views/widgets/stop_share_button.dart';
import 'package:chime/meetings/views/widgets/control_bar.dart';
import 'package:chime/meetings/views/widgets/expanded_participant_overlay.dart';
import 'package:chime/meetings/views/widgets/participants_list.dart';
import 'package:chime/meetings/views/widgets/screen_share_indicator.dart';
import 'package:chime/meetings/views/widgets/video_grid.dart';
import 'package:chime/meetings/models/attendee_model.dart';
import 'package:chime/meetings/models/meeting_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

class ActiveMeetingScreen extends StatefulWidget {
  final MeetingModel meeting;

  const ActiveMeetingScreen({super.key, required this.meeting});

  @override
  State<ActiveMeetingScreen> createState() => _ActiveMeetingScreenState();
}

class _ActiveMeetingScreenState extends State<ActiveMeetingScreen> {
  final log = Logger();
  final CommonHelper commonHelper = CommonHelper();
  late final TwilioService _twilioService;
  late final PermissionService _permissionService;

  bool _isAudioEnabled = false;
  bool _isVideoEnabled = false;
  bool _isScreenShareActive = false;
  bool _isMeetingJoined = false;
  List<AttendeeModel> _participants = [];
  bool _showParticipantsList = false;
  int? _localVideoViewId;
  final Map<String, int?> _remoteVideoViewIds = {};
  String? _expandedParticipantId;
  Timer? _controlsTimer;

  // Note: Network awareness is handled globally via NetworkService/NetworkBanner
  StreamSubscription<List<AttendeeModel>>? _participantsSubscription;
  StreamSubscription<String>? _roomDisconnectedSubscription;

  @override
  void initState() {
    super.initState();
    _twilioService = TwilioService();
    _permissionService = PermissionService();
    _initializeMeeting();
  }

  Future<void> _initializeMeeting() async {
    try {
      // Block when offline (use NetworkService)
      final isConnected = await NetworkService().isConnected();
      if (!isConnected) {
        if (mounted) {
          ToastUtil.showErrorToast(context, 'You are offline. Connect to the internet to join.');
          context.pop();
        }
        return;
      }
      // Validate required data
      if (widget.meeting.accessToken == null || widget.meeting.roomName == null) {
        if (mounted) {
          ToastUtil.showErrorToast(context, 'Missing access token or room name');
          context.pop();
        }
        return;
      }

      // Request permissions first
      final permissions = await _permissionService.requestMeetingPermissions();
      final micGranted = permissions[MeetingPermission.microphone] ?? false;
      final cameraGranted = permissions[MeetingPermission.camera] ?? false;

      if (!micGranted || !cameraGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please grant microphone and camera permissions to join the meeting'), duration: Duration(seconds: 3)),
          );
          return;
        }
      }

      // Connect to the room
      final connected = await _twilioService.connectToRoom(
        accessToken: widget.meeting.accessToken!,
        roomName: widget.meeting.roomName!,
        identity: widget.meeting.identity,
        enableAudio: micGranted,
        enableVideo: cameraGranted,
      );

      if (connected) {
        // Update state first
        setState(() {
          _isMeetingJoined = true;
          _isAudioEnabled = _twilioService.isAudioEnabled;
          _isVideoEnabled = _twilioService.isVideoEnabled;
        });
        _showControlsTemporarily();

        // Wait a bit for tracks to be ready, then get local video view ID
        if (cameraGranted) {
          // Delay to ensure video track is fully initialized
          await Future.delayed(const Duration(milliseconds: 500));

          // Refresh video status from service
          final videoEnabledAsync = await _twilioService.isVideoEnabledAsync();
          if (mounted) {
            setState(() {
              _isVideoEnabled = videoEnabledAsync;
            });
          }

          // Try to get local video view ID multiple times if needed
          int? localViewId;
          for (int i = 0; i < 3; i++) {
            localViewId = await _twilioService.getLocalVideoViewId();
            if (localViewId != null) {
              break;
            }
            await Future.delayed(const Duration(milliseconds: 300));
          }

          if (mounted && localViewId != null) {
            setState(() {
              _localVideoViewId = localViewId;
              _isVideoEnabled = true;
            });
            log.d("ActiveMeetingScreen:::Local video view ID obtained: $localViewId");
          } else {
            log.w("ActiveMeetingScreen:::Could not get local video view ID");
          }
        }
        // Listen to participants updates
        _participantsSubscription = _twilioService.participantsStream.listen((participants) async {
          if (mounted) {
            // Update view IDs for remote participants
            final updatedViewIds = <String, int?>{};
            for (final participant in participants) {
              if (participant.isVideoEnabled) {
                final viewId = await _twilioService.getRemoteVideoViewId(participant.attendeeId);
                updatedViewIds[participant.attendeeId] = viewId;
              }
            }
            setState(() {
              _participants = participants;
              _remoteVideoViewIds.addAll(updatedViewIds);
            });
          }
        });

        // Listen to room disconnected events
        _roomDisconnectedSubscription = _twilioService.roomDisconnectedStream.listen((event) {
          if (mounted && event == 'room_disconnected') {
            _leaveMeeting();
          }
        });

        // Fetch initial participants
        final initialParticipants = await _twilioService.getParticipants();
        if (mounted) {
          // Get view IDs for remote participants
          final initialViewIds = <String, int?>{};
          for (final participant in initialParticipants) {
            if (participant.isVideoEnabled) {
              final viewId = await _twilioService.getRemoteVideoViewId(participant.attendeeId);
              initialViewIds[participant.attendeeId] = viewId;
            }
          }
          setState(() {
            _participants = initialParticipants;
            _remoteVideoViewIds.addAll(initialViewIds);
          });
        }
      } else {
        if (mounted) {
          ToastUtil.showErrorToast(context, 'Failed to connect to room');
        }
      }
    } catch (e) {
      log.e("ActiveMeetingScreen:::Error initializing meeting: $e");
      if (mounted) {
        ToastUtil.showErrorToast(context, 'Error connecting to room: $e');
      }
    }
  }

  Future<void> _toggleAudio() async {
    final success = await _twilioService.toggleAudioMute();
    if (success && mounted) {
      setState(() {
        _isAudioEnabled = _twilioService.isAudioEnabled;
      });
      _showControlsTemporarily();
    }
  }

  Future<void> _toggleVideo() async {
    final success = await _twilioService.toggleVideo();
    if (success && mounted) {
      setState(() {
        _isVideoEnabled = _twilioService.isVideoEnabled;
      });
      _showControlsTemporarily();
    }
  }

  Future<void> _toggleScreenShare() async {
    if (_isScreenShareActive) {
      final success = await _twilioService.stopScreenShare();
      if (success && mounted) {
        // Always re-fetch camera view id after stop
        int? cameraViewId;
        for (int i = 0; i < 3; i++) {
          cameraViewId = await _twilioService.getLocalVideoViewId();
          if (cameraViewId != null) break;
          await Future.delayed(const Duration(milliseconds: 300));
        }
        setState(() {
          _isScreenShareActive = false;
          _localVideoViewId = cameraViewId; // ensure fresh
        });
        _showControlsTemporarily();
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Failed to Stop Screen Share'),
              content: const Text('Screen sharing could not be stopped due to a system or connection issue. Please try again.'),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
            ),
          );
        }
      }
    } else {
      // Request screen share permission
      final granted = await _permissionService.requestScreenSharePermission();
      if (granted) {
        final success = await _twilioService.startScreenShare();
        if (success && mounted) {
          // Always re-fetch screen view id (for instant UI)
          setState(() {
            _isScreenShareActive = true;
          });
          _showControlsTemporarily();
        } else {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Failed to Start Screen Share'),
                content: const Text(
                  'Screen sharing could not be started. This may be due to a device limitation, system settings, or an active connection issue.',
                ),
                actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
              ),
            );
          }
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Screen Sharing Permission Denied'),
              content: const Text(
                "Screen sharing permission was denied. To enable screen sharing, please allow this permission in your device's settings.",
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _permissionService.openAppSettings();
                  },
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _leaveMeeting() async {
    await _twilioService.disconnectFromRoom();
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _endMeetingForAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Meeting'),
        content: const Text('Are you sure you want to end this meeting for all participants? This requires server-side action.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('End Meeting')),
        ],
      ),
    );

    if (confirmed == true) {
      // Note: Ending meeting for all requires server-side API call
      // For now, just disconnect
      await _leaveMeeting();
    }
  }

  void _toggleParticipantsList() {
    setState(() {
      _showParticipantsList = !_showParticipantsList;
    });
  }

  Widget _buildVideoGrid() {
    return VideoGrid(
      participants: _participants,
      isLocalVideoEnabled: _isVideoEnabled,
      localVideoViewId: _localVideoViewId,
      remoteVideoViewIds: _remoteVideoViewIds,
      isLocalParticipant: _isLocalParticipant,
      onExpandParticipant: (pid) => setState(() => _expandedParticipantId = pid),
    );
  }

  bool _isLocalParticipant(AttendeeModel p) {
    final id = widget.meeting.identity;
    if (id != null && id.isNotEmpty) {
      if (p.attendeeId == id) return true;
      if (p.name != null && p.name == id) return true;
    }
    // Fallback: treat tiles labeled 'You' as local
    if (p.name != null && p.name!.toLowerCase() == 'you') return true;
    return false;
  }

  void _showControlsTemporarily() {
    _controlsTimer?.cancel();
    // Always show controls; do not auto-hide
  }

  @override
  void dispose() {
    _participantsSubscription?.cancel();
    _roomDisconnectedSubscription?.cancel();
    _controlsTimer?.cancel();
    _twilioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _leaveMeeting();
        }
      },
      child: NetworkAwareScaffoldWithBanner(
        backgroundColor: Colors.black,
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.meeting.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(_isMeetingJoined ? 'Connected' : 'Connecting...', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          actions: [
            if (widget.meeting.roomName != null)
              IconButton(
                tooltip: 'Copy Meeting ID',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: widget.meeting.roomName!));
                  if (mounted) {
                    ToastUtil.showSuccessToast(context, 'Meeting ID copied');
                  }
                },
              ),
            IconButton(
              tooltip: _showParticipantsList ? 'Hide Participants' : 'Show Participants',
              icon: Icon(_showParticipantsList ? Icons.people_alt : Icons.people_outline),
              onPressed: _toggleParticipantsList,
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'leave') {
                  await _leaveMeeting();
                } else if (value == 'toggle_audio') {
                  await _toggleAudio();
                } else if (value == 'toggle_video') {
                  await _toggleVideo();
                } else if (value == 'share') {
                  await _toggleScreenShare();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'toggle_audio', child: Text(_isAudioEnabled ? 'Mute' : 'Unmute')),
                PopupMenuItem(value: 'toggle_video', child: Text(_isVideoEnabled ? 'Stop Video' : 'Start Video')),
                PopupMenuItem(value: 'share', child: Text(_isScreenShareActive ? 'Stop Share' : 'Share Screen')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'leave', child: Text('Leave Meeting')),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showControlsTemporarily,
            child: Stack(
              children: [
                // Video Grid/View
                _isMeetingJoined ? _buildVideoGrid() : const Center(child: CircularProgressIndicator(color: Colors.white)),

                // Screen share active indicator (small banner)
                if (_isScreenShareActive) const Positioned(top: 90, right: 16, child: ScreenShareIndicator()),

                // Stop share quick action
                if (_isScreenShareActive) Positioned(bottom: 100, left: 16, child: StopShareButton(onPressed: _toggleScreenShare)),

                // Expanded overlays are removed for equal-grid experience
                if (_expandedParticipantId != null)
                  ExpandedParticipantOverlay(
                    participantId: _expandedParticipantId!,
                    participants: _participants,
                    remoteVideoViewIds: _remoteVideoViewIds,
                    localVideoViewId: _localVideoViewId,
                    isLocalVideoEnabled: _isVideoEnabled,
                    isLocalParticipant: _isLocalParticipant,
                    onClose: () => setState(() => _expandedParticipantId = null),
                  ),
                // Participants List
                if (_showParticipantsList)
                  Positioned(
                    top: 80,
                    left: 16,
                    right: 16,
                    child: ParticipantsList(participants: _participants, onClose: _toggleParticipantsList),
                  ),
                // Bottom Controls (always visible)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ControlBar(
                    isAudioEnabled: _isAudioEnabled,
                    isVideoEnabled: _isVideoEnabled,
                    isScreenShareActive: _isScreenShareActive,
                    onToggleAudio: _toggleAudio,
                    onToggleVideo: _toggleVideo,
                    onToggleScreenShare: _toggleScreenShare,
                    onEndMeetingForAll: _endMeetingForAll,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
