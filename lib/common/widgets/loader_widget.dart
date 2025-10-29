import 'package:chime/common/common.dart';
import 'package:flutter/material.dart';

class LoaderWidget extends StatefulWidget {
  const LoaderWidget({super.key, this.loaderType, this.progressValue, this.loadingText});

  final String? loaderType;
  final double? progressValue;
  final String? loadingText;

  @override
  LoaderWidgetState createState() => LoaderWidgetState();
}

class LoaderWidgetState extends State<LoaderWidget> {
  UiHelper uiHelper = UiHelper();
  CommonHelper commonHelper = CommonHelper();

  @override
  Widget build(BuildContext context) {
    return widget.loaderType == Constants.LOADER_LINER
        ? LinearProgressIndicator(
            minHeight: 5,
            value: widget.progressValue,
            color: Theme.of(context).colorScheme.primaryContainer,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          )
        : Wrap(
            direction: Axis.vertical,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 10.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CircularProgressIndicator(
                value: widget.progressValue,
                color: Theme.of(context).colorScheme.primaryContainer,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
              if (widget.loadingText?.isNotEmpty == true)
                Text(widget.loadingText ?? "", style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
            ],
          );
  }
}
