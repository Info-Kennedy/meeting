part of 'login_bloc.dart';

enum LoginStatus { initial, loaded, loading, changing, changed, loggedIn, loggedOut, success, error }

class LoginState extends Equatable {
  final String message;
  final LoginStatus status;
  final LoginModel? formValue;
  final String userLanguage;
  final String url;
  final bool isObscure;
  final UserModel? userModel;

  const LoginState({
    required this.status,
    required this.message,
    required this.userLanguage,
    required this.url,
    required this.isObscure,
    this.formValue,
    this.userModel,
  });

  static LoginState initial = LoginState(
    message: "",
    url: "",
    isObscure: true,
    userLanguage: Constants.LANGUAGES['English']!,
    status: LoginStatus.initial,
    formValue: null,
    userModel: null,
  );

  LoginState copyWith({
    LoginStatus Function()? status,
    String Function()? message,
    String Function()? url,
    bool Function()? isObscure,
    LoginModel Function()? formValue,
    UserModel Function()? userModel,
    String Function()? userLanguage,
  }) {
    return LoginState(
      status: status != null ? status() : this.status,
      message: message != null ? message() : this.message,
      url: url != null ? url() : this.url,
      isObscure: isObscure != null ? isObscure() : this.isObscure,
      userModel: userModel != null ? userModel() : this.userModel,
      formValue: formValue != null ? formValue() : this.formValue,
      userLanguage: userLanguage != null ? userLanguage() : this.userLanguage,
    );
  }

  @override
  List<Object?> get props => [status, message, isObscure, url, formValue, userModel, userLanguage];
}
