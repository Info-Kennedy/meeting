import 'package:chime/common/common.dart';
import 'package:chime/common/services/token_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class NetworkAwareApiRepository {
  final log = Logger();
  final ApiRepository _apiRepository;
  final NetworkService _networkService;
  final TokenService? _tokenService;

  NetworkAwareApiRepository({required ApiRepository apiRepository, required NetworkService networkService, TokenService? tokenService})
    : _apiRepository = apiRepository,
      _networkService = networkService,
      _tokenService = tokenService;

  /// Set callback to be called when 401 Unauthorized error occurs
  void setUnauthorizedCallback(VoidCallback callback) {
    _apiRepository.setUnauthorizedCallback(callback);
    // Also set the callback for TokenService if available
    _tokenService?.setLogoutCallback(callback);
  }

  /// Check network connectivity before making API calls
  Future<bool> _checkNetworkConnectivity() async {
    try {
      return await _networkService.isConnected();
    } catch (e) {
      log.e('NetworkAwareApiRepository::_checkNetworkConnectivity::Error: $e');
      return false;
    }
  }

  /// Throws NetworkException if no network connectivity
  Future<void> _ensureNetworkConnectivity() async {
    try {
      final isConnected = await _checkNetworkConnectivity();
      if (!isConnected) {
        throw NetworkException('No internet connection available. Please check your network settings and try again.');
      }
    } catch (e) {
      log.e('NetworkAwareApiRepository::_ensureNetworkConnectivity::Error: $e');
      throw NetworkException('Unable to check network connectivity. Please try again.');
    }
  }

  Future<dynamic> postRequest({required String url, required Map<String, dynamic> data}) async {
    await _ensureNetworkConnectivity();
    return await _apiRepository.postRequest(url: url, data: data);
  }

  Future<dynamic> formDataPostRequest({required String url, required FormData data}) async {
    await _ensureNetworkConnectivity();
    return await _apiRepository.formDataPostRequest(url: url, data: data);
  }

  Future<dynamic> getRequest({required String url}) async {
    await _ensureNetworkConnectivity();
    return await _apiRepository.getRequest(url: url);
  }

  Future<dynamic> getOpenUrlRequest({required String requestUrl}) async {
    await _ensureNetworkConnectivity();
    return await _apiRepository.getOpenUrlRequest(requestUrl: requestUrl);
  }

  Future<dynamic> getRequestWithoutMenu({required String url}) async {
    await _ensureNetworkConnectivity();
    return await _apiRepository.getRequestWithoutMenu(url: url);
  }

  Future<dynamic> putRequest({required String url, required Map<String, dynamic> data}) async {
    await _ensureNetworkConnectivity();
    return await _apiRepository.putRequest(url: url, data: data);
  }

  Future<dynamic> deleteRequest({required String url}) async {
    await _ensureNetworkConnectivity();
    return await _apiRepository.deleteRequest(url: url);
  }
}

/// Custom exception for network-related errors
class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Custom exception for 401 Unauthorized errors
class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}
