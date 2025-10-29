part of 'home_bloc.dart';

enum HomeStatus { initial, loading, changing, changed, loaded, error, success, statusUpdated, shopAccepted, acccessRevoked }

class HomeState extends Equatable {
  final String message;
  final HomeStatus status;
  final MenuItem selectedMenuItem;
  final List<MenuItem> bottomMenuItems;
  final MenuItem selectedBottomMenuItem;
  final Widget? body;
  final bool showBottomNav;
  final bool showDisclaimer;

  const HomeState({
    this.body,
    required this.status,
    required this.message,
    required this.selectedMenuItem,
    required this.bottomMenuItems,
    required this.selectedBottomMenuItem,
    required this.showBottomNav,
    required this.showDisclaimer,
  });

  static HomeState initial = HomeState(
    message: "",
    status: HomeStatus.initial,
    bottomMenuItems: const [],
    selectedMenuItem: MenuItem.getInstance(),
    selectedBottomMenuItem: MenuItem.getInstance(),
    showBottomNav: true,
    showDisclaimer: false,
  );

  HomeState copyWith({
    Widget Function()? body,
    HomeStatus Function()? status,
    String Function()? message,
    List<MenuItem> Function()? bottomMenuItems,
    MenuItem Function()? selectedMenuItem,
    MenuItem Function()? selectedBottomMenuItem,
    bool Function()? showBottomNav,
    bool Function()? showDisclaimer,
  }) {
    return HomeState(
      body: body != null ? body() : this.body,
      status: status != null ? status() : this.status,
      message: message != null ? message() : this.message,
      showBottomNav: showBottomNav != null ? showBottomNav() : this.showBottomNav,
      bottomMenuItems: bottomMenuItems != null ? bottomMenuItems() : this.bottomMenuItems,
      selectedMenuItem: selectedMenuItem != null ? selectedMenuItem() : this.selectedMenuItem,
      selectedBottomMenuItem: selectedBottomMenuItem != null ? selectedBottomMenuItem() : this.selectedBottomMenuItem,
      showDisclaimer: showDisclaimer != null ? showDisclaimer() : this.showDisclaimer,
    );
  }

  @override
  List<Object?> get props => [body, status, message, showBottomNav, selectedMenuItem, bottomMenuItems, selectedBottomMenuItem, showDisclaimer];
}
