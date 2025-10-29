import 'package:chime/common/common.dart';
import 'package:logger/logger.dart';

class ErrorHandler {
  static final log = Logger();

  /// Handle exceptions and return appropriate error message
  static String handleException(dynamic error) {
    log.e('ErrorHandler::handleException::Error: $error');

    if (error is NetworkException) {
      return error.message;
    } else if (error is UnauthorizedException) {
      return error.message;
    } else if (error is Exception) {
      return error.toString().replaceAll("Exception:", "").trim();
    } else {
      return error.toString();
    }
  }

  /// Check if the error is a network-related error
  static bool isNetworkError(dynamic error) {
    return error is NetworkException;
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    if (error is NetworkException) {
      return error.message;
    } else if (error is UnauthorizedException) {
      return error.message;
    } else if (error.toString().contains('Connection') || error.toString().contains('timeout') || error.toString().contains('network')) {
      return 'Network connection error. Please check your internet connection and try again.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }
}
