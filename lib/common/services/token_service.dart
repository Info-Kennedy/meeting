import 'dart:ui';

import 'package:chime/common/common.dart';
import 'package:chime/login/models/user_model.dart';
import 'package:logger/logger.dart';

class TokenService {
  final log = Logger();
  final PreferencesRepository _prefRepo;
  ApiRepository? _apiRepo;
  VoidCallback? _onLogoutRequired;
  bool _isRefreshing = false;

  TokenService({required PreferencesRepository prefRepo, ApiRepository? apiRepo}) : _prefRepo = prefRepo, _apiRepo = apiRepo;

  /// Set the ApiRepository (used for circular dependency resolution)
  set apiRepo(ApiRepository apiRepo) {
    _apiRepo = apiRepo;
  }

  /// Set callback to be called when logout is required due to token issues
  void setLogoutCallback(VoidCallback callback) {
    _onLogoutRequired = callback;
  }

  /// Check if the current access token is expired or about to expire
  Future<bool> isTokenExpired() async {
    try {
      final userData = await _prefRepo.getPreference(Constants.PREF_KEY_USER);
      if (userData == null || userData.isEmpty) {
        log.w("TokenService::isTokenExpired::No user data found");
        return true;
      }

      final user = UserModel.fromJson(userData);
      log.d(
        "TokenService::isTokenExpired::User data - expiresAt: ${user.expiresAt}, refreshToken: ${user.refreshToken.isNotEmpty ? '${user.refreshToken.substring(0, 10)}...' : 'empty'}",
      );

      // If expiresAt is 0 or null, consider token expired
      if (user.expiresAt == 0) {
        log.w("TokenService::isTokenExpired::No expiry time set, considering expired");
        return true;
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final tokenExpiry = user.expiresAt * 1000; // Convert to milliseconds

      // Consider token expired if it expires within the next 5 minutes
      const bufferTime = 5 * 60 * 1000; // 5 minutes in milliseconds
      final isExpired = currentTime >= (tokenExpiry - bufferTime);

      log.d("TokenService::isTokenExpired::Current time: $currentTime, Token expiry: $tokenExpiry, Is expired: $isExpired");
      return isExpired;
    } catch (e) {
      log.e("TokenService::isTokenExpired::Error: $e");
      return true;
    }
  }

  /// Refresh the access token using the refresh token
  Future<bool> refreshAccessToken() async {
    // Prevent multiple simultaneous refresh attempts
    if (_isRefreshing) {
      log.d("TokenService::refreshAccessToken::Refresh already in progress, waiting...");
      // Wait for the current refresh to complete
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Check if refresh was successful by checking if we have a valid token
      final token = await _prefRepo.getPreference(Constants.PREF_KEY_AUTH_TOKEN);
      return token != null && token.isNotEmpty;
    }

    _isRefreshing = true;
    try {
      log.d("TokenService::refreshAccessToken::Starting token refresh");

      if (_apiRepo == null) {
        log.e("TokenService::refreshAccessToken::ApiRepository not available");
        return false;
      }

      final refreshToken = await _prefRepo.getPreference(Constants.PREF_KEY_REFRESH_TOKEN);
      if (refreshToken == null || refreshToken.isEmpty) {
        log.w("TokenService::refreshAccessToken::No refresh token available");
        return false;
      }

      final response = await _apiRepo!.postRequest(url: Constants.API_MAP['refresh_token']!, data: {"refresh_token": refreshToken});

      if (response['success'] == true) {
        final data = response['data'];
        final newAccessToken = data['access_token'] as String;
        final newRefreshToken = data['refresh_token'] as String;
        final expiresIn = data['expires_in'] as int;

        // Update stored tokens
        await _prefRepo.savePreference(Constants.PREF_KEY_AUTH_TOKEN, newAccessToken);
        await _prefRepo.savePreference(Constants.PREF_KEY_REFRESH_TOKEN, newRefreshToken);

        // Update user data with new token information
        final userData = await _prefRepo.getPreference(Constants.PREF_KEY_USER);
        if (userData != null && userData.isNotEmpty) {
          final user = UserModel.fromJson(userData);
          // Calculate expiry timestamp: current time + expiresIn seconds
          final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Convert to seconds
          final expiryTimestamp = currentTime + expiresIn;
          final updatedUser = user.copyWith(token: newAccessToken, refreshToken: newRefreshToken, expiresAt: expiryTimestamp);
          await _prefRepo.savePreference(Constants.PREF_KEY_USER, updatedUser.toJson());
          log.d("TokenService::refreshAccessToken::Updated user with expiry timestamp: $expiryTimestamp");
          log.d("TokenService::refreshAccessToken::Updated user data: ${updatedUser.toJson()}");
        } else {
          log.w("TokenService::refreshAccessToken::No user data found to update");
        }

        log.d("TokenService::refreshAccessToken::Token refreshed successfully");
        log.d("TokenService::refreshAccessToken::New access token: ${newAccessToken.substring(0, 20)}...");
        log.d("TokenService::refreshAccessToken::New refresh token: ${newRefreshToken.substring(0, 20)}...");
        log.d("TokenService::refreshAccessToken::Expires in: $expiresIn seconds");
        return true;
      } else {
        log.e("TokenService::refreshAccessToken::Failed to refresh token: ${response['message']}");
        // If refresh token is invalid/expired, trigger logout
        _onLogoutRequired?.call();
        return false;
      }
    } catch (e) {
      log.e("TokenService::refreshAccessToken::Error: $e");
      // If there's an error during refresh (network, server error, etc.), trigger logout
      _onLogoutRequired?.call();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Get the current access token, refreshing if necessary
  Future<String?> getValidAccessToken() async {
    try {
      // Check if we have any valid tokens at all
      if (!(await hasValidTokens())) {
        log.w("TokenService::getValidAccessToken::No valid tokens found");
        // Don't trigger logout here - let the calling API decide
        return null;
      }

      if (await isTokenExpired()) {
        log.d("TokenService::getValidAccessToken::Token expired, attempting refresh");
        final refreshSuccess = await refreshAccessToken();
        if (!refreshSuccess) {
          log.w("TokenService::getValidAccessToken::Failed to refresh token");
          // Don't trigger logout here - let the calling API decide
          return null;
        }
      }

      final token = await _prefRepo.getPreference(Constants.PREF_KEY_AUTH_TOKEN);
      if (token == null || token.isEmpty) {
        log.w("TokenService::getValidAccessToken::No access token available");
        // Don't trigger logout here - let the calling API decide
        return null;
      }

      return token;
    } catch (e) {
      log.e("TokenService::getValidAccessToken::Error: $e");
      // Don't trigger logout here - let the calling API decide
      return null;
    }
  }

  /// Clear all stored tokens
  Future<void> clearTokens() async {
    try {
      await _prefRepo.removePreference(Constants.PREF_KEY_AUTH_TOKEN);
      await _prefRepo.removePreference(Constants.PREF_KEY_REFRESH_TOKEN);
      log.d("TokenService::clearTokens::All tokens cleared");
    } catch (e) {
      log.e("TokenService::clearTokens::Error: $e");
    }
  }

  /// Check if user has valid tokens (access token or refresh token)
  Future<bool> hasValidTokens() async {
    try {
      final accessToken = await _prefRepo.getPreference(Constants.PREF_KEY_AUTH_TOKEN);
      final refreshToken = await _prefRepo.getPreference(Constants.PREF_KEY_REFRESH_TOKEN);

      return (accessToken != null && accessToken.isNotEmpty) || (refreshToken != null && refreshToken.isNotEmpty);
    } catch (e) {
      log.e("TokenService::hasValidTokens::Error: $e");
      return false;
    }
  }
}
