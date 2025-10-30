import 'package:chime/common/common.dart';
import 'package:chime/common/services/token_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class ApiRepository {
  final log = Logger();
  final Dio _dio;
  final PreferencesRepository prefRepo;
  final TokenService? _tokenService;
  VoidCallback? onUnauthorized;

  ApiRepository(this._dio, this.prefRepo, {TokenService? tokenService}) : _tokenService = tokenService {
    // Token initialization will be done lazily when needed
    // since getPreference is now async
  }

  /// Set callback to be called when 401 Unauthorized error occurs
  void setUnauthorizedCallback(VoidCallback callback) {
    onUnauthorized = callback;
  }

  /// Update the authorization header with a new token
  void _updateAuthorizationHeader(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Get a valid access token, refreshing if necessary
  Future<String?> _getValidToken() async {
    if (_tokenService != null) {
      return await _tokenService.getValidAccessToken();
    }
    return await prefRepo.getPreference(Constants.PREF_KEY_AUTH_TOKEN);
  }

  /// Check if the API endpoint requires authentication
  bool _requiresAuth(String url) {
    return !Constants.NO_AUTH_REQUIRED_APIS.contains(url);
  }

  Future<Map<String, dynamic>> postRequest({required String url, required Map<String, dynamic> data}) async {
    try {
      log.d("ApiRepository:::In postRequest - Request Parameters: $url::: $data");

      // Check if this API requires authentication
      if (_requiresAuth(url)) {
        // Get valid token (refresh if necessary)
        String? authToken = await _getValidToken();
        if (authToken?.isNotEmpty == true) {
          _updateAuthorizationHeader(authToken!);
        } else {
          // Check if user is already logged in before triggering logout
          final userData = await prefRepo.getPreference(Constants.PREF_KEY_USER);
          if (userData != null && userData.isNotEmpty) {
            // User is logged in but token is invalid, trigger logout
            log.w("ApiRepository:::postRequest::User logged in but no valid token available, triggering logout");
            onUnauthorized?.call();
            throw UnauthorizedException("Session expired. Please login again.");
          } else {
            // User is not logged in, just remove auth header
            log.d("ApiRepository:::postRequest::User not logged in, removing auth header");
            _dio.options.headers.remove('Authorization');
          }
        }
      } else {
        // Remove authorization header for non-auth APIs
        _dio.options.headers.remove('Authorization');
      }

      String requestUrl = Constants.API_BASE_URL + url;
      final response = await _dio.post(requestUrl, data: data);
      log.d("ApiRepository:::In postRequest - Response from Post: $url::: $response");
      return response.data as Map<String, dynamic>;
    } on DioException catch (exception, error) {
      log.e("APIHelper:::Error in postRequest: $error");
      throw _handleError(exception);
    }
  }

  Future<Map<String, dynamic>> formDataPostRequest({required String url, required FormData data}) async {
    try {
      log.d("ApiRepository:::In formDataRequest - Request Parameters: $url::: ${data.fields.map((x) => x).toString()}");

      // Check if this API requires authentication
      if (_requiresAuth(url)) {
        // Get valid token (refresh if necessary)
        String? authToken = await _getValidToken();
        if (authToken?.isNotEmpty == true) {
          _updateAuthorizationHeader(authToken!);
        } else {
          // Check if user is already logged in before triggering logout
          final userData = await prefRepo.getPreference(Constants.PREF_KEY_USER);
          if (userData != null && userData.isNotEmpty) {
            // User is logged in but token is invalid, trigger logout
            log.w("ApiRepository:::formDataPostRequest::User logged in but no valid token available, triggering logout");
            onUnauthorized?.call();
            throw UnauthorizedException("Session expired. Please login again.");
          } else {
            // User is not logged in, just remove auth header
            log.d("ApiRepository:::formDataPostRequest::User not logged in, removing auth header");
            _dio.options.headers.remove('Authorization');
          }
        }
      } else {
        // Remove authorization header for non-auth APIs
        _dio.options.headers.remove('Authorization');
      }

      String requestUrl = Constants.API_BASE_URL + url;
      final response = await _dio.post(requestUrl, data: data);
      log.d("ApiRepository:::In formDataRequest - Response from Post: $url::: $response");
      return response.data as Map<String, dynamic>;
    } on DioException catch (exception, error) {
      log.e("APIHelper:::Error in formDataRequest: $error");
      throw _handleError(exception);
    }
  }

  Future<dynamic> getRequest({required String url}) async {
    try {
      log.d("ApiRepository:::In getRequest - Request Parameters: $url");

      // Check if this API requires authentication
      if (_requiresAuth(url)) {
        // Get valid token (refresh if necessary)
        String? authToken = await _getValidToken();
        if (authToken?.isNotEmpty == true) {
          _updateAuthorizationHeader(authToken!);
        } else {
          // Check if user is already logged in before triggering logout
          final userData = await prefRepo.getPreference(Constants.PREF_KEY_USER);
          if (userData != null && userData.isNotEmpty) {
            // User is logged in but token is invalid, trigger logout
            log.w("ApiRepository:::getRequest::User logged in but no valid token available, triggering logout");
            onUnauthorized?.call();
            throw UnauthorizedException("Session expired. Please login again.");
          } else {
            // User is not logged in, just remove auth header
            log.d("ApiRepository:::getRequest::User not logged in, removing auth header");
            _dio.options.headers.remove('Authorization');
          }
        }
      } else {
        // Remove authorization header for non-auth APIs
        _dio.options.headers.remove('Authorization');
      }

      String requestUrl = Constants.API_BASE_URL + url;
      final response = await _dio.get(requestUrl);
      log.d("ApiRepository:::In getRequest - Response from Get: $url::: $response");
      return response.data;
    } on DioException catch (exception, error) {
      log.e("APIHelper:::Error in getRequest: $error");
      throw _handleError(exception);
    }
  }

  Future<dynamic> getOpenUrlRequest({required String requestUrl}) async {
    try {
      _dio.options.headers.remove('Authorization');
      final response = await _dio.get(requestUrl);
      log.d("ApiRepository:::In getRequest - Response from Get: $requestUrl::: $response");
      return response.data;
    } on DioException catch (exception, error) {
      log.e("APIHelper:::Error in getRequest: $error");
      throw _handleError(exception);
    }
  }

  Future<dynamic> getRequestWithoutMenu({required String url}) async {
    try {
      log.d("ApiRepository:::In getRequest - Request Parameters: $url");

      // Check if this API requires authentication
      if (_requiresAuth(url)) {
        // Get valid token (refresh if necessary)
        String? authToken = await _getValidToken();
        if (authToken?.isNotEmpty == true) {
          _updateAuthorizationHeader(authToken!);
        } else {
          // Check if user is already logged in before triggering logout
          final userData = await prefRepo.getPreference(Constants.PREF_KEY_USER);
          if (userData != null && userData.isNotEmpty) {
            // User is logged in but token is invalid, trigger logout
            log.w("ApiRepository:::getRequestWithoutMenu::User logged in but no valid token available, triggering logout");
            onUnauthorized?.call();
            throw UnauthorizedException("Session expired. Please login again.");
          } else {
            // User is not logged in, just remove auth header
            log.d("ApiRepository:::getRequestWithoutMenu::User not logged in, removing auth header");
            _dio.options.headers.remove('Authorization');
          }
        }
      } else {
        // Remove authorization header for non-auth APIs
        _dio.options.headers.remove('Authorization');
      }

      String requestUrl = Constants.API_BASE_URL + url;
      final response = await _dio.get(requestUrl);
      log.d("ApiRepository:::In getRequest - Response from Get: $url::: $response");
      return response.data;
    } on DioException catch (exception, error) {
      log.e("APIHelper:::Error in getRequest: $error");
      throw _handleError(exception);
    }
  }

  Future<dynamic> putRequest({required String url, required Map<String, dynamic> data}) async {
    try {
      log.d("ApiRepository:::In putRequest - Request Parameters: $url :: data :: $data");

      // Check if this API requires authentication
      if (_requiresAuth(url)) {
        // Get valid token (refresh if necessary)
        String? authToken = await _getValidToken();
        if (authToken?.isNotEmpty == true) {
          _updateAuthorizationHeader(authToken!);
        } else {
          // Check if user is already logged in before triggering logout
          final userData = await prefRepo.getPreference(Constants.PREF_KEY_USER);
          if (userData != null && userData.isNotEmpty) {
            // User is logged in but token is invalid, trigger logout
            log.w("ApiRepository:::putRequest::User logged in but no valid token available, triggering logout");
            onUnauthorized?.call();
            throw UnauthorizedException("Session expired. Please login again.");
          } else {
            // User is not logged in, just remove auth header
            log.d("ApiRepository:::putRequest::User not logged in, removing auth header");
            _dio.options.headers.remove('Authorization');
          }
        }
      } else {
        // Remove authorization header for non-auth APIs
        _dio.options.headers.remove('Authorization');
      }

      String requestUrl = Constants.API_BASE_URL + url;
      final response = await _dio.put(requestUrl, data: data);
      log.d("ApiRepository:::In putRequest - Response from Put: $url::: $response");
      return response.data;
    } on DioException catch (exception, error) {
      log.e("APIHelper:::Error in putRequest: $error");
      throw _handleError(exception);
    }
  }

  Future<dynamic> deleteRequest({required String url}) async {
    try {
      log.d("ApiRepository:::In deleteRequest - Request Parameters: $url::");

      // Check if this API requires authentication
      if (_requiresAuth(url)) {
        // Get valid token (refresh if necessary)
        String? authToken = await _getValidToken();
        if (authToken?.isNotEmpty == true) {
          _updateAuthorizationHeader(authToken!);
        } else {
          // Check if user is already logged in before triggering logout
          final userData = await prefRepo.getPreference(Constants.PREF_KEY_USER);
          if (userData != null && userData.isNotEmpty) {
            // User is logged in but token is invalid, trigger logout
            log.w("ApiRepository:::deleteRequest::User logged in but no valid token available, triggering logout");
            onUnauthorized?.call();
            throw UnauthorizedException("Session expired. Please login again.");
          } else {
            // User is not logged in, just remove auth header
            log.d("ApiRepository:::deleteRequest::User not logged in, removing auth header");
            _dio.options.headers.remove('Authorization');
          }
        }
      } else {
        // Remove authorization header for non-auth APIs
        _dio.options.headers.remove('Authorization');
      }

      String requestUrl = "${Constants.API_BASE_URL}$url";
      final response = await _dio.delete(requestUrl);
      log.d("ApiRepository:::In deleteRequest - Response from Delete: $url::: $response");
      return response.data;
    } on DioException catch (exception, error) {
      log.e("APIHelper:::Error in deleteRequest: $error");
      throw _handleError(exception);
    }
  }

  // Future<Response> putRequest(String url, Map<String, dynamic> data) {
  //   return request('PUT', url, data: data);
  // }

  Exception _handleError(DioException error) {
    String errorMessage;
    switch (error.type) {
      case DioExceptionType.connectionError:
        errorMessage = "Connection Error.";
        break;
      case DioExceptionType.connectionTimeout:
        errorMessage = "Connection timed out.";
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = "Receive timeout.";
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = "Send timeout.";
        break;
      case DioExceptionType.cancel:
        errorMessage = "Request cancelled.";
        break;
      case DioExceptionType.badResponse:
        // Handle 401 Unauthorized specifically
        if (error.response?.statusCode == 401) {
          log.w("ApiRepository:::401 Unauthorized - triggering logout");
          onUnauthorized?.call();
          return UnauthorizedException("Session expired. Please login again.");
        }
        errorMessage = "${error.response?.data['message'] ?? error.response?.statusMessage}";
        break;
      case DioExceptionType.unknown:
      default:
        errorMessage = "Connection error: ${error.message}";
    }
    return Exception(errorMessage);
  }
}
