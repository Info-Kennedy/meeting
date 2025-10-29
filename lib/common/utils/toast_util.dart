import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtil {
  static void showSuccessToast(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      type: ToastificationType.success,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  static void showErrorToast(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      type: ToastificationType.error,
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  static void showWarningToast(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      type: ToastificationType.warning,
      backgroundColor: Colors.orange,
      icon: Icons.crisis_alert_outlined,
    );
  }

  static void _showToast({
    required BuildContext context,
    required String message,
    required ToastificationType type,
    required Color backgroundColor,
    required IconData icon,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.minimal,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text(
        type == ToastificationType.success
            ? 'Success'
            : type == ToastificationType.warning
            ? 'Warning'
            : 'Error',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
      ),
      description: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
      ),
      alignment: Alignment.bottomRight,
      primaryColor: backgroundColor,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      icon: Icon(icon, color: backgroundColor),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 16, offset: Offset(0, 16), spreadRadius: 0)],
      showProgressBar: true,
      closeButton: ToastCloseButton(showType: CloseButtonShowType.always),
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: false,
    );
  }
}
