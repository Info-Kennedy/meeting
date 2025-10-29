import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:chime/common/services/network_service.dart';
import 'package:logger/logger.dart';

part 'network_event.dart';
part 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  final log = Logger();
  final NetworkService _networkService = NetworkService();
  StreamSubscription? _networkSubscription;

  NetworkBloc() : super(const NetworkState()) {
    on<InitializeNetwork>(_onInitializeNetwork);
    on<UpdateNetworkStatus>(_onUpdateNetworkStatus);
    on<HideNetworkBanner>(_onHideNetworkBanner);
  }

  Future<void> _onInitializeNetwork(InitializeNetwork event, Emitter<NetworkState> emit) async {
    try {
      await _networkService.initialize();

      // Check initial connection status
      final isConnected = await _networkService.isConnected();
      emit(
        state.copyWith(
          isConnected: isConnected,
          showBanner: !isConnected, // Show banner only when disconnected initially
        ),
      );

      // Listen to connection changes
      _networkSubscription = _networkService.connectionStatusStream.listen((isConnected) {
        add(UpdateNetworkStatus(isConnected: isConnected));
      });
    } catch (e) {
      log.e('NetworkBloc::_onInitializeNetwork::Error: $e');
      emit(state.copyWith(isConnected: false, showBanner: true));
    }
  }

  void _onUpdateNetworkStatus(UpdateNetworkStatus event, Emitter<NetworkState> emit) {
    final isConnected = event.isConnected;

    emit(
      state.copyWith(
        isConnected: isConnected,
        showBanner: true, // Show banner for both connected and disconnected states
      ),
    );

    // If connected, hide the banner after 3 seconds
    if (isConnected) {
      Future.delayed(const Duration(seconds: 3), () {
        final currentState = state;
        if (currentState.isConnected && currentState.showBanner) {
          add(const HideNetworkBanner());
        }
      });
    }
  }

  void _onHideNetworkBanner(HideNetworkBanner event, Emitter<NetworkState> emit) {
    emit(state.copyWith(showBanner: false));
  }

  @override
  Future<void> close() {
    _networkSubscription?.cancel();
    return super.close();
  }
}
