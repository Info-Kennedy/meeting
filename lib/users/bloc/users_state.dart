part of 'users_bloc.dart';

enum UsersStatus { initial, loading, loaded, success, error }

class UsersState extends Equatable {
  final String message;
  final UsersStatus status;
  final List<Map<String, dynamic>> users;

  const UsersState({required this.status, required this.users, required this.message});

  static UsersState initial = UsersState(status: UsersStatus.initial, users: const [], message: "");

  UsersState copyWith({UsersStatus Function()? status, List<Map<String, dynamic>> Function()? users, String Function()? message}) {
    return UsersState(
      status: status != null ? status() : this.status,
      users: users != null ? users() : this.users,
      message: message != null ? message() : this.message,
    );
  }

  @override
  List<Object?> get props => [status, users, message];
}
