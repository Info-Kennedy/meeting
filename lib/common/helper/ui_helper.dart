import 'package:flutter/material.dart';
import 'package:chime/common/common.dart';
import 'package:logger/logger.dart';

class UiHelper {
  final log = Logger();

  UiHelper();

  ThemeData themeData(String themeMode) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF005CF4),
        primary: const Color(0xFF005CF4),
        brightness: themeMode == Constants.themeConfig.LIGHT ? Brightness.light : Brightness.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0))),
          textStyle: WidgetStateProperty.all(TextStyle(inherit: false, fontWeight: FontWeight.w500)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0))),
          textStyle: WidgetStateProperty.all(TextStyle(inherit: false, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  /// Returns the total height needed for bottom navigation bar including safe area
  double getBottomNavigationHeight(BuildContext context) {
    final bottomNavHeight = MediaQuery.of(context).size.height * 0.08;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return bottomNavHeight + bottomPadding;
  }

  /// Gets the bottom padding for system navigation bar
  double getSystemBottomPadding(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom;
  }
}
