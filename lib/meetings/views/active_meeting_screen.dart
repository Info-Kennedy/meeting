import 'dart:async';
import 'package:chime/common/common.dart';
import 'package:chime/common/services/twilio_service.dart';
import 'package:chime/common/services/permission_service.dart';
import 'package:chime/common/widgets/twilio_video_view.dart';
import 'package:chime/meetings/models/attendee_model.dart';
import 'package:chime/meetings/models/meeting_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
// Removed: collection and connectivity_plus; using global NetworkService instead

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

  // Removed local connectivity monitoring; rely on NetworkService and global banner

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

      // Permissions granted, proceed

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

        // If screen share already active (edge case), no-op; UI shows indicator

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
    final allParticipants = _participants;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final count = allParticipants.length;
        if (count == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 64, color: Colors.white54),
                const SizedBox(height: 16),
                Text(
                  widget.meeting.title,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        // Determine optimal layout to fill available width and height
        int bestCols = 1;
        double bestAspect = 1.0;
        double bestArea = -1;
        const spacing = 8.0;
        for (int cols = 1; cols <= count; cols++) {
          final rows = (count / cols).ceil();
          final totalHSpacing = (rows - 1) * spacing;
          final totalWSpacing = (cols - 1) * spacing;
          final tileWidth = (availableWidth - totalWSpacing) / cols;
          final tileHeight = (availableHeight - totalHSpacing) / rows;
          if (tileWidth <= 0 || tileHeight <= 0) continue;
          final area = tileWidth * tileHeight;
          if (area > bestArea) {
            bestArea = area;
            bestCols = cols;
            bestAspect = tileWidth / tileHeight;
          }
        }
        final crossAxisCount = bestCols.clamp(1, count);

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: bestAspect,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: allParticipants.length,
          itemBuilder: (context, index) {
            final participant = allParticipants[index];
            final isLocal = _isLocalParticipant(participant);
            final isSharer = participant.isScreenSharing == true;

            int? viewId;
            if (isLocal) {
              viewId = _localVideoViewId;
            } else {
              viewId = _remoteVideoViewIds[participant.attendeeId];
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isLocal ? Colors.blue : (participant.isScreenSharing ? Colors.green : Colors.grey), width: 3),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isSharer && isLocal)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.screen_share, color: Colors.redAccent, size: 36),
                            SizedBox(height: 8),
                            Text("You're sharing your screen", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      )
                    else if (!isLocal && isSharer)
                      (viewId != null)
                          ? TwilioVideoView(
                              key: ValueKey("${participant.attendeeId}-${participant.isVideoEnabled}-${viewId}-screen"),
                              viewId: viewId,
                              isLocal: false,
                              participantId: participant.attendeeId,
                            )
                          : Center(child: CircularProgressIndicator(color: Colors.white.withOpacity(0.6)))
                    else if ((isLocal && _isVideoEnabled && _localVideoViewId != null) || (!isLocal && participant.isVideoEnabled && viewId != null))
                      TwilioVideoView(
                        key: ValueKey("${participant.attendeeId}-${participant.isVideoEnabled}-${viewId}"),
                        viewId: viewId!,
                        isLocal: isLocal,
                        participantId: isLocal ? null : participant.attendeeId,
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: const Icon(Icons.person, color: Colors.white, size: 30),
                            ),
                            const SizedBox(height: 8),
                            Text(participant.name ?? 'Participant', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),

                    // Name overlay
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
                        child: Text(isLocal ? 'You' : (participant.name ?? 'Participant'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),

                    // Mic state overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                          participant.isAudioEnabled ? Icons.mic : Icons.mic_off,
                          size: 14,
                          color: participant.isAudioEnabled ? Colors.white : Colors.redAccent,
                        ),
                      ),
                    ),

                    // Full-size GestureDetector overlay to ensure taps work over PlatformViews
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(onTap: () => setState(() => _expandedParticipantId = participant.attendeeId)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    return WillPopScope(
      onWillPop: () async {
        await _leaveMeeting();
        return true;
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting ID copied')));
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

                // Connectivity banner handled globally via NetworkBanner

                // Remove local PIP and special full-screen share views. Keep quick Stop Share button.

                // Screen share active indicator (small banner)
                if (_isScreenShareActive)
                  Positioned(
                    top: 90,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.screen_share, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Sharing Screen',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Stop share quick action
                if (_isScreenShareActive)
                  Positioned(
                    bottom: 100,
                    left: 16,
                    child: ElevatedButton.icon(
                      onPressed: _toggleScreenShare,
                      icon: const Icon(Icons.stop_screen_share),
                      label: const Text('Stop Share'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    ),
                  ),

                // Expanded overlays are removed for equal-grid experience
                if (_expandedParticipantId != null)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black,
                      child: Stack(
                        children: [
                          Builder(
                            builder: (context) {
                              final pid = _expandedParticipantId!;
                              final p = _participants.firstWhere((e) => e.attendeeId == pid, orElse: () => AttendeeModel(attendeeId: pid));
                              final isLocal = _isLocalParticipant(p);
                              final isSharer = p.isScreenSharing == true;
                              int? viewId;
                              if (isLocal) {
                                viewId = _localVideoViewId;
                              } else {
                                viewId = _remoteVideoViewIds[pid];
                              }

                              Widget content;
                              if (isSharer && isLocal) {
                                content = Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.screen_share, color: Colors.redAccent, size: 48),
                                      SizedBox(height: 12),
                                      Text("You're sharing your screen", style: TextStyle(color: Colors.white, fontSize: 16)),
                                    ],
                                  ),
                                );
                              } else if (!isLocal && isSharer) {
                                if (viewId != null) {
                                  content = TwilioVideoView(
                                    key: ValueKey("expanded-${pid}-${p.isVideoEnabled}-${viewId}-screen"),
                                    viewId: viewId,
                                    isLocal: false,
                                    participantId: pid,
                                  );
                                } else {
                                  content = const Center(child: CircularProgressIndicator(color: Colors.white));
                                }
                              } else if ((isLocal && _isVideoEnabled && _localVideoViewId != null) ||
                                  (!isLocal && p.isVideoEnabled && viewId != null)) {
                                content = TwilioVideoView(
                                  key: ValueKey("expanded-${pid}-${p.isVideoEnabled}-${viewId}"),
                                  viewId: viewId!,
                                  isLocal: isLocal,
                                  participantId: isLocal ? null : pid,
                                );
                              } else {
                                content = Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        child: const Icon(Icons.person, color: Colors.white, size: 40),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(p.name ?? 'Participant', style: const TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                );
                              }

                              return Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(color: Colors.black, child: content),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: InkWell(
                              onTap: () => setState(() => _expandedParticipantId = null),
                              child: Container(
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.close, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Top Bar with meeting info
                // (Top bar replaced by AppBar)

                // Participants List
                if (_showParticipantsList)
                  Positioned(
                    top: 80,
                    left: 16,
                    right: 16,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Participants (${_participants.length})',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: _toggleParticipantsList,
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: _participants.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('No other participants', style: TextStyle(color: Colors.white70)),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _participants.length,
                                    itemBuilder: (context, index) {
                                      final participant = _participants[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.white.withOpacity(0.2),
                                          child: const Icon(Icons.person, color: Colors.white),
                                        ),
                                        title: Text(participant.name ?? 'Participant ${index + 1}', style: const TextStyle(color: Colors.white)),
                                        subtitle: Text(
                                          'Audio: ${participant.isAudioEnabled ? "On" : "Off"} | Video: ${participant.isVideoEnabled ? "On" : "Off"}',
                                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom Controls (always visible)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ControlButton(
                                icon: _isAudioEnabled ? Icons.mic : Icons.mic_off,
                                label: _isAudioEnabled ? 'Mute' : 'Unmute',
                                isActive: _isAudioEnabled,
                                onPressed: _toggleAudio,
                              ),
                              _ControlButton(
                                icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                                label: _isVideoEnabled ? 'Stop Video' : 'Start Video',
                                isActive: _isVideoEnabled,
                                onPressed: _toggleVideo,
                              ),
                              _ControlButton(
                                icon: Icons.screen_share,
                                label: _isScreenShareActive ? 'Stop Share' : 'Share Screen',
                                isActive: _isScreenShareActive,
                                onPressed: _toggleScreenShare,
                              ),
                              _ControlButton(
                                icon: Icons.call_end,
                                label: 'End',
                                isActive: false,
                                backgroundColor: Colors.red,
                                onPressed: _endMeetingForAll,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? backgroundColor;
  final VoidCallback onPressed;

  const _ControlButton({required this.icon, required this.label, required this.isActive, required this.onPressed, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? (isActive ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
            iconSize: 28,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
