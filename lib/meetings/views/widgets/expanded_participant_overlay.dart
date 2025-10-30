import 'package:chime/common/widgets/twilio_video_view.dart';
import 'package:chime/meetings/models/attendee_model.dart';
import 'package:flutter/material.dart';

typedef IsLocalParticipant = bool Function(AttendeeModel participant);

class ExpandedParticipantOverlay extends StatelessWidget {
  final String participantId;
  final List<AttendeeModel> participants;
  final Map<String, int?> remoteVideoViewIds;
  final int? localVideoViewId;
  final bool isLocalVideoEnabled;
  final IsLocalParticipant isLocalParticipant;
  final VoidCallback onClose;

  const ExpandedParticipantOverlay({
    super.key,
    required this.participantId,
    required this.participants,
    required this.remoteVideoViewIds,
    required this.localVideoViewId,
    required this.isLocalVideoEnabled,
    required this.isLocalParticipant,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final p = participants.firstWhere((e) => e.attendeeId == participantId, orElse: () => AttendeeModel(attendeeId: participantId));
    final isLocal = isLocalParticipant(p);
    final isSharer = p.isScreenSharing == true;
    int? viewId = isLocal ? localVideoViewId : remoteVideoViewIds[participantId];

    Widget content;
    if (isSharer && isLocal) {
      content = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.screen_share, color: Colors.redAccent, size: 48),
            SizedBox(height: 12),
            Text("You're sharing your screen", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      );
    } else if (!isLocal && isSharer) {
      if (viewId != null) {
        content = TwilioVideoView(
          key: ValueKey("expanded-$participantId-${p.isVideoEnabled}-$viewId-screen"),
          viewId: viewId,
          isLocal: false,
          participantId: participantId,
        );
      } else {
        content = const Center(child: CircularProgressIndicator(color: Colors.white));
      }
    } else if ((isLocal && isLocalVideoEnabled && localVideoViewId != null) || (!isLocal && p.isVideoEnabled && viewId != null)) {
      content = TwilioVideoView(
        key: ValueKey("expanded-$participantId-${p.isVideoEnabled}-$viewId"),
        viewId: viewId!,
        isLocal: isLocal,
        participantId: isLocal ? null : participantId,
      );
    } else {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 12),
            Text(p.name ?? 'Participant', style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(color: Colors.black, child: content),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: InkWell(
                onTap: onClose,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
