import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

class NetworkService {
  final log = Logger();
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;

  final Connectivity _connectivity = Connectivity();
  late StreamController<bool> _connectionStatusController;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool _isDisposed = false;
  StreamSubscription? _connectivitySubscription;

  NetworkService._internal() {
    _connectionStatusController = StreamController<bool>.broadcast();
  }

  Future<void> initialize() async {
    if (_isDisposed) {
      _isDisposed = false;
      _connectionStatusController = StreamController<bool>.broadcast();
    }

    // Check initial connectivity status
    await _checkConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
      onError: (error) {
        log.e('NetworkService::initialize::Error: $error');
      },
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      log.e('NetworkService::_checkConnectivity::Error: $e');
      _emitConnectionStatus(false);
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    bool isConnected = false;
    
    for (ConnectivityResult result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.mobile:
        case ConnectivityResult.ethernet:
          isConnected = true;
          break;
        case ConnectivityResult.none:
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.vpn:
        case ConnectivityResult.other:
          // Continue checking other results
          break;
      }
      if (isConnected) break; // If we found a valid connection, we can stop
    }

    log.d('NetworkService::_handleConnectivityChange::Status: $results, Connected: $isConnected');
    _emitConnectionStatus(isConnected);
  }

  void _emitConnectionStatus(bool isConnected) {
    if (!_isDisposed && !_connectionStatusController.isClosed) {
      _connectionStatusController.add(isConnected);
    }
  }

  Future<bool> isConnected() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      for (ConnectivityResult result in results) {
        if (result == ConnectivityResult.wifi || 
            result == ConnectivityResult.mobile || 
            result == ConnectivityResult.ethernet) {
          return true;
        }
      }
      return false;
    } catch (e) {
      log.e('NetworkService::isConnected::Error: $e');
      return false;
    }
  }

  void dispose() {
    _isDisposed = true;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.close();
    }
  }
} 