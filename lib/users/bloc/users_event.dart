part of 'users_bloc.dart';

sealed class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object> get props => [];
}

class InitializeUsersPage extends UsersEvent {
  const InitializeUsersPage();
}

class RefreshUsers extends UsersEvent {
  const RefreshUsers();
}
