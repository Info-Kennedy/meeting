import 'dart:async';
import 'package:chime/common/common.dart';
import 'package:get_it/get_it.dart';
import "package:logger/logger.dart";

class UsersRepository {
  static const String _usersStoreName = 'users';
  static const String _usersCacheKey = 'users_list';
  static const String _usersTimestampKey = 'users_timestamp';
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  final log = Logger();
  GetIt getIt = GetIt.instance;
  final PreferencesRepository prefRepo;
  final NetworkAwareApiRepository apiRepo;
  final EncryptedDatabaseService? dbService;

  UsersRepository({required this.prefRepo, required this.apiRepo, this.dbService});

  /// Get users with offline-first approach:
  /// 1. Load from local encrypted DB first (if available)
  /// 2. Return cached data immediately if valid
  /// 3. Fetch from API in background
  /// 4. Update local DB with fresh data
  Future<List<Map<String, dynamic>>> getUsers({bool forceRefresh = false}) async {
    try {
      // If database service is available, try offline-first approach
      if (dbService != null && !forceRefresh) {
        // Try to load from local DB first
        final cachedUsers = await _getCachedUsers();
        if (cachedUsers != null && cachedUsers.isNotEmpty) {
          log.d("UsersRepository:::getUsers::Returning cached users (${cachedUsers.length} items)");

          // Fetch fresh data in background without blocking
          _refreshUsersInBackground();

          return cachedUsers;
        }
      }

      // If no cached data or force refresh, fetch from API
      log.d("UsersRepository:::getUsers::Fetching from API");
      return await _fetchAndCacheUsers();
    } catch (error) {
      log.e("UsersRepository:::getUsers::Error: $error");

      // If API fails, try to return cached data as fallback
      if (dbService != null) {
        final cachedUsers = await _getCachedUsers();
        if (cachedUsers != null && cachedUsers.isNotEmpty) {
          log.w("UsersRepository:::getUsers::API failed, returning cached data");
          return cachedUsers;
        }
      }

      throw Exception('$error');
    }
  }

  /// Get cached users from local encrypted database
  Future<List<Map<String, dynamic>>?> _getCachedUsers() async {
    try {
      if (dbService == null) return null;

      // Check if cache exists
      final exists = await dbService!.exists(_usersStoreName, _usersCacheKey);
      if (!exists) {
        log.d("UsersRepository:::getCachedUsers::No cache found");
        return null;
      }

      // Check cache validity
      final timestampStr = await dbService!.get(_usersStoreName, _usersTimestampKey);
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr as String);
        final now = DateTime.now();
        final diff = now.difference(timestamp);

        if (diff > _cacheValidityDuration) {
          log.d("UsersRepository:::getCachedUsers::Cache expired (age: ${diff.inHours}h)");
          return null;
        }
      }

      // Get cached data
      final cachedData = await dbService!.get(_usersStoreName, _usersCacheKey);
      if (cachedData is List) {
        return cachedData.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
      return null;
    } catch (error) {
      log.e("UsersRepository:::getCachedUsers::Error: $error");
      return null;
    }
  }

  /// Fetch users from API and cache them
  Future<List<Map<String, dynamic>>> _fetchAndCacheUsers() async {
    try {
      dynamic response = await apiRepo.getRequest(url: Constants.API_MAP['users']!);
      if (response is List) {
        final users = response.map((datum) => Map<String, dynamic>.from(datum as Map)).toList();

        // Cache the data if database service is available
        if (dbService != null) {
          await _cacheUsers(users);
        }

        return users;
      } else {
        throw Exception("Expected 'data' to be a List but got ${response.runtimeType}");
      }
    } catch (error) {
      log.e("UsersRepository:::_fetchAndCacheUsers::Error: $error");
      rethrow;
    }
  }

  /// Cache users in encrypted database
  Future<void> _cacheUsers(List<Map<String, dynamic>> users) async {
    try {
      if (dbService == null) return;

      // Store users list
      await dbService!.put(_usersStoreName, _usersCacheKey, users);

      // Store timestamp
      await dbService!.put(_usersStoreName, _usersTimestampKey, DateTime.now().toIso8601String());

      log.d("UsersRepository:::_cacheUsers::Cached ${users.length} users");
    } catch (error) {
      log.e("UsersRepository:::_cacheUsers::Error caching: $error");
      // Don't throw - caching failure shouldn't break the main flow
    }
  }

  /// Refresh users in background without blocking
  Future<void> _refreshUsersInBackground() async {
    try {
      await _fetchAndCacheUsers();
      log.d("UsersRepository:::_refreshUsersInBackground::Background refresh completed");
    } catch (error) {
      log.w("UsersRepository:::_refreshUsersInBackground::Background refresh failed: $error");
      // Silently fail - we already have cached data
    }
  }

  /// Clear cached users
  Future<void> clearCache() async {
    try {
      if (dbService == null) return;
      await dbService!.clearStore(_usersStoreName);
      log.d("UsersRepository:::clearCache::Cache cleared");
    } catch (error) {
      log.e("UsersRepository:::clearCache::Error: $error");
    }
  }
}
