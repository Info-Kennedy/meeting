part of 'network_bloc.dart';

abstract class NetworkEvent extends Equatable {
  const NetworkEvent();

  @override
  List<Object?> get props => [];
}

class InitializeNetwork extends NetworkEvent {
  const InitializeNetwork();
}

class UpdateNetworkStatus extends NetworkEvent {
  final bool isConnected;

  const UpdateNetworkStatus({required this.isConnected});

  @override
  List<Object?> get props => [isConnected];
}

class HideNetworkBanner extends NetworkEvent {
  const HideNetworkBanner();
}
