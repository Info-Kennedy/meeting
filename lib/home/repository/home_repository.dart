import 'dart:async';
import 'package:chime/common/common.dart';
import 'package:chime/home/models/menu_item.dart';
import 'package:get_it/get_it.dart';
import "package:logger/logger.dart";

class HomeRepository {
  final log = Logger();
  GetIt getIt = GetIt.instance;
  final PreferencesRepository prefRepo;
  final NetworkAwareApiRepository apiRepo;

  HomeRepository({required this.prefRepo, required this.apiRepo});

  Future<List<MenuItem>> getBottomNavigationConfig() async {
    List<MenuItem> menuItems = [];
    try {
      List<Map<String, dynamic>> data = [];
      final userData = await prefRepo.getPreference(Constants.PREF_KEY_USER);
      if (userData?.isNotEmpty == true) {
        data = List<Map<String, dynamic>>.from(Constants.navConfig.BOTTOM_NAVIGATION_CONFIG_USER);
        menuItems = data.map((datum) => MenuItem.fromJson(datum)).toList();
      }
    } catch (error) {
      log.e("HomeRepository:::getNavigationConfig::Error:$error");
    }
    return menuItems;
  }
}
