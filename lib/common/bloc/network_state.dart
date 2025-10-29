part of 'network_bloc.dart';

class NetworkState extends Equatable {
  final bool isConnected;
  final bool showBanner;

  const NetworkState({this.isConnected = true, this.showBanner = false});

  NetworkState copyWith({bool? isConnected, bool? showBanner}) {
    return NetworkState(isConnected: isConnected ?? this.isConnected, showBanner: showBanner ?? this.showBanner);
  }

  @override
  List<Object?> get props => [isConnected, showBanner];
}
