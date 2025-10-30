import 'dart:convert';

import 'package:chime/common/common.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class CommonHelper {
  final log = Logger();
  String? _cachedLanguage;

  CommonHelper();

  /// Synchronous version that uses cached language or defaults to "en"
  /// Use this in build methods and synchronous contexts
  String getIntlLabelSync(dynamic labels) {
    labels = labels is Map<String, dynamic> ? labels : Map<String, String>.from(jsonDecode(labels));
    String userLanguage = _cachedLanguage ?? "en";
    return labels[userLanguage] ?? '-';
  }

  /// Synchronous version that uses cached language or defaults to "en"
  /// Use this in build methods and synchronous contexts
  String getStringLabelSync(String label) {
    String userLanguage = _cachedLanguage ?? "en";
    return AppStrings.string[userLanguage]?[label] ?? "-";
  }

  /// Initialize language cache - call this at app startup
  Future<void> initializeLanguage() async {
    try {
      PreferencesRepository pref = getIt<PreferencesRepository>();
      _cachedLanguage = await pref.getPreference(Constants.PREF_KEY_USER_LANGUAGE);
    } catch (e) {
      log.e("CommonHelper::initializeLanguage::Error: $e");
      _cachedLanguage = "en";
    }
  }

  /// Update language cache when language changes
  Future<void> updateLanguageCache(String language) async {
    _cachedLanguage = language;
  }

  Future<String> getIntlLabel(dynamic labels) async {
    labels = labels is Map<String, dynamic> ? labels : Map<String, String>.from(jsonDecode(labels));
    PreferencesRepository pref = getIt<PreferencesRepository>();
    String userLanguage = await pref.getPreference(Constants.PREF_KEY_USER_LANGUAGE) ?? "en";
    _cachedLanguage = userLanguage;
    return labels[userLanguage] ?? '-';
  }

  Future<String> getStringLabel(String label) async {
    PreferencesRepository pref = getIt<PreferencesRepository>();
    String userLanguage = await pref.getPreference(Constants.PREF_KEY_USER_LANGUAGE) ?? "en";
    _cachedLanguage = userLanguage;
    return AppStrings.string[userLanguage]?[label] ?? "-";
  }

  String getIconPath(String iconName) {
    return "assets/icons/$iconName";
  }

  String capitalize(String input) {
    if (input.isEmpty) return input;
    return input.substring(0, 1).toUpperCase() + input.substring(1);
  }

  String capitalizeUnderscore(String input) {
    if (input.isEmpty) return input;
    String formattedName = input.replaceAll('_', ' ');
    formattedName = formattedName
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
    return formattedName;
  }

  String convertDateToAppDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    DateTime localDate = parsedDate.toLocal();
    return DateFormat('dd.MM.yy | hh:mm a').format(localDate);
  }

  Future<void> alertDialog(
    BuildContext context,
    String? title,
    String message,
    String? negativeText,
    Function? negative,
    String postiveText,
    Function postive,
  ) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          title: Text(
            title ?? Constants.APP_NAME,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          actions: [
            negativeText?.isNotEmpty == true ? OutlinedButton(onPressed: () => negative!(), child: Text(negativeText!)) : const SizedBox.shrink(),
            postiveText.isNotEmpty ? FilledButton(onPressed: () => postive(), child: Text(postiveText)) : const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}
