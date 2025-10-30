import 'dart:async';

import 'package:chime/common/common.dart';
import 'package:chime/login/models/user_model.dart';
import 'package:get_it/get_it.dart';
import "package:logger/logger.dart";

class LoginRepository {
  final log = Logger();
  GetIt getIt = GetIt.instance;
  final PreferencesRepository prefRepo;
  final NetworkAwareApiRepository apiRepo;

  LoginRepository({required this.prefRepo, required this.apiRepo});

  Future<bool> isUserLoggedIn() async {
    try {
      var user = await prefRepo.getPreference(Constants.PREF_KEY_USER);
      return user?.isNotEmpty == true;
    } catch (error) {
      log.e("LoginRepository:::isUserLoggedIn::Error: $error");
      return false;
    }
  }

  Future<Map<String, dynamic>?> login(Map<String, dynamic> data) async {
    try {
      // Mock login with default values
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      if ((data["email"] == "task@exmaple.com" || data["email"] == "task@example.com") && data["password"] == "Qwerty@123!") {
        Map<String, dynamic> response = {
          "success": true,
          "data": {
            "id": "12345",
            "name": "Test User",
            "email": data["email"],
            "active": true,
            "token": "mock_token_12345",
            "refresh_token": "mock_refresh_token_12345",
            "expires_at": DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          },
          "message": "Login successful (mock)",
        };
        UserModel user = UserModel.fromMap(response['data']);
        user = user.copyWith(
          token: response['data']['token'],
          refreshToken: response['data']['refresh_token'],
          expiresAt: response['data']['expires_at'],
        );
        await prefRepo.savePreference(Constants.PREF_KEY_AUTH_TOKEN, user.token);
        await prefRepo.savePreference(Constants.PREF_KEY_REFRESH_TOKEN, user.refreshToken);
        await prefRepo.savePreference(Constants.PREF_KEY_USER, user.toJson());
        await prefRepo.savePreference(Constants.PREF_KEY_USER_ID, user.id);
        return response;
      } else {
        Map<String, dynamic> response = {"success": false, "data": {}, "message": "Invalid email or password"};
        return response;
      }
    } catch (error) {
      log.e("LoginRepository:::login::Error: $error");
      throw Exception('$error');
    }
  }
}
