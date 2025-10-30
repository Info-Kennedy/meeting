import 'package:flutter/material.dart';

class ScreenShareIndicator extends StatelessWidget {
  const ScreenShareIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(16)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.screen_share, size: 14, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'Sharing Screen',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
