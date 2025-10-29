part of 'login_bloc.dart';

@immutable
sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

final class InitializeLogin extends LoginEvent {
  const InitializeLogin();
}

final class ChangeFormValue extends LoginEvent {
  final Map<String, dynamic> formValue;

  const ChangeFormValue({required this.formValue});

  @override
  List<Object> get props => [formValue];
}

final class LoggedIn extends LoginEvent {}

final class LoginSubmit extends LoginEvent {}

final class TogglePasswordVisibility extends LoginEvent {
  const TogglePasswordVisibility();
}

final class Logout extends LoginEvent {}
