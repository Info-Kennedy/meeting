import 'package:flutter/material.dart';

class StopShareButton extends StatelessWidget {
  final VoidCallback onPressed;

  const StopShareButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.stop_screen_share),
      label: const Text('Stop Share'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
    );
  }
}
