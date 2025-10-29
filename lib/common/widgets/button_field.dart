import 'package:flutter/material.dart';

class ButtonField extends StatelessWidget {
  final String name;
  final double? height;
  final bool? isLoading;
  final Color? backgroundColor;
  final Function()? onPressed;

  const ButtonField({super.key, this.height, this.isLoading, this.onPressed, this.backgroundColor, required this.name});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
        minimumSize: Size.fromHeight(height ?? 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: Row(
        spacing: 10.0,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isLoading == true
              ? Container(
                width: 25,
                height: 25,
                margin: const EdgeInsets.all(10),
                child: const CircularProgressIndicator(color: Colors.white),
              )
              : Text(name),
        ],
      ),
    );
  }
}
