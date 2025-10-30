import 'package:chime/common/widgets/twilio_video_view.dart';
import 'package:chime/meetings/models/attendee_model.dart';
import 'package:flutter/material.dart';

typedef IsLocalParticipant = bool Function(AttendeeModel participant);

class VideoGrid extends StatelessWidget {
  final List<AttendeeModel> participants;
  final bool isLocalVideoEnabled;
  final int? localVideoViewId;
  final Map<String, int?> remoteVideoViewIds;
  final IsLocalParticipant isLocalParticipant;
  final ValueChanged<String> onExpandParticipant;

  const VideoGrid({
    super.key,
    required this.participants,
    required this.isLocalVideoEnabled,
    required this.localVideoViewId,
    required this.remoteVideoViewIds,
    required this.isLocalParticipant,
    required this.onExpandParticipant,
  });

  @override
  Widget build(BuildContext context) {
    final allParticipants = participants;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final count = allParticipants.length;
        if (count == 0) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 64, color: Colors.white54),
                SizedBox(height: 16),
                Text(
                  'No participants yet',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

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
            final isLocal = isLocalParticipant(participant);
            final isSharer = participant.isScreenSharing == true;

            int? viewId;
            if (isLocal) {
              viewId = localVideoViewId;
            } else {
              viewId = remoteVideoViewIds[participant.attendeeId];
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
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.screen_share, color: Colors.redAccent, size: 36),
                            SizedBox(height: 8),
                            Text("You're sharing your screen", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      )
                    else if (!isLocal && isSharer)
                      (viewId != null)
                          ? TwilioVideoView(
                              key: ValueKey("${participant.attendeeId}-${participant.isVideoEnabled}-$viewId-screen"),
                              viewId: viewId,
                              isLocal: false,
                              participantId: participant.attendeeId,
                            )
                          : Center(child: CircularProgressIndicator(color: Colors.white.withValues(alpha: 0.6)))
                    else if ((isLocal && isLocalVideoEnabled && localVideoViewId != null) ||
                        (!isLocal && participant.isVideoEnabled && viewId != null))
                      TwilioVideoView(
                        key: ValueKey("${participant.attendeeId}-${participant.isVideoEnabled}-$viewId"),
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
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              child: const Icon(Icons.person, color: Colors.white, size: 30),
                            ),
                            const SizedBox(height: 8),
                            Text(participant.name ?? 'Participant', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),

                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
                        child: Text(isLocal ? 'You' : (participant.name ?? 'Participant'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),

                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                          participant.isAudioEnabled ? Icons.mic : Icons.mic_off,
                          size: 14,
                          color: participant.isAudioEnabled ? Colors.white : Colors.redAccent,
                        ),
                      ),
                    ),

                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(onTap: () => onExpandParticipant(participant.attendeeId)),
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
}
