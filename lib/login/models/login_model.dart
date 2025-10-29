import 'package:logger/logger.dart';

class LoginModel {
  final String emailId;
  final String password;

  LoginModel({required this.emailId, required this.password});

  static LoginModel getInstance() {
    return LoginModel(emailId: "", password: "");
  }

  factory LoginModel.fromMap(Map<String, dynamic> map) {
    final log = Logger();
    try {
      return LoginModel(
        emailId: (map.containsKey('email') && map['email'] != null) ? map['email'] as String : "",
        password: (map.containsKey('password') && map['password'] != null) ? map['password'] as String : "",
      );
    } catch (error) {
      log.e("LoginModel:::fromMap::Error: $error");
      throw Exception(error);
    }
  }

  Map<String, dynamic> toMap() {
    return {'email': emailId, 'password': password};
  }
}
