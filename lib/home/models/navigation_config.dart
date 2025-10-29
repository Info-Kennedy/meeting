// ignore_for_file: non_constant_identifier_names

class NavigationConfig {
  const NavigationConfig();

  final List<Map<String, dynamic>> BOTTOM_NAVIGATION_CONFIG_USER = const [
    {"id": "meetings", "name": "Meetings", "icon": "ic_nav_meetings", "type": "item", "selected": true, "url": "meetings", "params": {}},

    {"id": "users", "name": "Users", "icon": "ic_nav_users", "type": "item", "selected": false, "url": "users", "params": {}},
  ];
}
