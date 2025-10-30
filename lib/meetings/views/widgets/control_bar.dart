import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  final bool isAudioEnabled;
  final bool isVideoEnabled;
  final bool isScreenShareActive;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onEndMeetingForAll;

  const ControlBar({
    super.key,
    required this.isAudioEnabled,
    required this.isVideoEnabled,
    required this.isScreenShareActive,
    required this.onToggleAudio,
    required this.onToggleVideo,
    required this.onToggleScreenShare,
    required this.onEndMeetingForAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
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
                  icon: isAudioEnabled ? Icons.mic : Icons.mic_off,
                  label: isAudioEnabled ? 'Mute' : 'Unmute',
                  isActive: isAudioEnabled,
                  onPressed: onToggleAudio,
                ),
                _ControlButton(
                  icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                  label: isVideoEnabled ? 'Stop Video' : 'Start Video',
                  isActive: isVideoEnabled,
                  onPressed: onToggleVideo,
                ),
                _ControlButton(
                  icon: Icons.screen_share,
                  label: isScreenShareActive ? 'Stop Share' : 'Share Screen',
                  isActive: isScreenShareActive,
                  onPressed: onToggleScreenShare,
                ),
                _ControlButton(icon: Icons.call_end, label: 'End', isActive: false, backgroundColor: Colors.red, onPressed: onEndMeetingForAll),
              ],
            ),
          ],
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
    final bgColor = backgroundColor ?? (isActive ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1));

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
