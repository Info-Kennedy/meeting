import 'package:chime/common/common.dart';
import 'package:flutter/material.dart';

class MessageTextWidget extends StatefulWidget {
  const MessageTextWidget({super.key, this.messageType, required this.message});

  final String? messageType;
  final String message;

  @override
  MessageTextWidgetState createState() => MessageTextWidgetState();
}

class MessageTextWidgetState extends State<MessageTextWidget> {
  UiHelper uiHelper = UiHelper();
  CommonHelper commonHelper = CommonHelper();

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.message,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: widget.messageType == Constants.MESSAGE_ERROR ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
