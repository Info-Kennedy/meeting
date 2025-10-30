import 'package:chime/meetings/models/attendee_model.dart';
import 'package:flutter/material.dart';

class ParticipantsList extends StatelessWidget {
  final List<AttendeeModel> participants;
  final VoidCallback onClose;

  const ParticipantsList({super.key, required this.participants, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  'Participants (${participants.length})',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Flexible(
            child: participants.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No other participants', style: TextStyle(color: Colors.white70)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(participant.name ?? 'Participant ${index + 1}', style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Audio: ${participant.isAudioEnabled ? "On" : "Off"} | Video: ${participant.isVideoEnabled ? "On" : "Off"}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
