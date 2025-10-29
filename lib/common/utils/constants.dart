// ignore_for_file: constant_identifier_names

import 'package:chime/home/models/navigation_config.dart';

import 'theme_config.dart';

class Constants {
  static const APP_NAME = "Chime";
  static const API_BASE_URL = "https://6901d409b208b24affe3df1d.mockapi.io/api/v1/";

  // Constants file
  static const navConfig = NavigationConfig();
  static const themeConfig = ThemeConfig();

  // Shared Preferences Keys
  static const PREF_KEY_AUTH_TOKEN = "authToken";
  static const PREF_KEY_REFRESH_TOKEN = "refreshToken";
  static const PREF_KEY_USER_ID = "userId";
  static const PREF_KEY_USER = "user";
  static const PREF_KEY_USER_LANGUAGE = "userLanguage";
  static const PREF_KEY_MENU_ITEM = "menuItem";

  // Constants Map
  static const LANGUAGES = {'English': 'en'};

  // Loader Type
  static const LOADER_LINER = "linear";
  static const LOADER_CIRCULAR = "circular";

  // Message Type
  static const MESSAGE_ERROR = "error";
  static const MESSAGE_NO_DATA = "no_data";

  //************** APIS ****************
  static const API_MAP = {"users": "users"};

  // APIs that don't require authentication tokens
  static const NO_AUTH_REQUIRED_APIS = ["users"];
}
