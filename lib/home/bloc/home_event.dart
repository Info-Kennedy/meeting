part of 'home_bloc.dart';

@immutable
sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class InitializeHomePage extends HomeEvent {
  const InitializeHomePage();
}

class UpdateBottomNavItem extends HomeEvent {
  final MenuItem menuItem;

  const UpdateBottomNavItem({required this.menuItem});

  @override
  List<Object> get props => [menuItem];
}

class BottomNavView extends HomeEvent {
  final bool view;

  const BottomNavView({required this.view});

  @override
  List<Object> get props => [view];
}
