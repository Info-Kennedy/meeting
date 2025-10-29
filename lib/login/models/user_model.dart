// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:chime/login/models/user_role_model.dart';

class UserModel {
  final String id;
  final String appId;
  final String name;
  final String mobileNo;
  final String emailId;
  final bool mobileVerified;
  final bool emailVerified;
  final String lastLogin;
  final String token;
  final String refreshToken;
  final int expiresAt;
  final bool active;
  final UserRoleModel roleModel;

  UserModel({
    required this.id,
    required this.appId,
    required this.name,
    required this.mobileNo,
    required this.emailId,
    required this.mobileVerified,
    required this.emailVerified,
    required this.lastLogin,
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
    required this.active,
    required this.roleModel,
  });

  static UserModel getInstance() {
    return UserModel(
      id: "",
      appId: "",
      name: "",
      mobileNo: "",
      emailId: "",
      mobileVerified: false,
      emailVerified: false,
      lastLogin: "",
      token: "",
      refreshToken: "",
      expiresAt: 0,
      active: false,
      roleModel: UserRoleModel.getInstance(),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map.containsKey('id') && map['id'] != null) ? map['id'] as String : "",
      appId: (map.containsKey('user_id') && map['user_id'] != null) ? map['user_id'] as String : "",
      name: (map.containsKey('name') && map['name'] != null) ? map['name'] as String : "",
      mobileNo: (map.containsKey('mobile_number') && map['mobile_number'] != null) ? map['mobile_number'] as String : "",
      emailId: (map.containsKey('email_id') && map['email_id'] != null) ? map['email_id'] as String : "",
      lastLogin: (map.containsKey('last_login') && map['last_login'] != null) ? map['last_login'] as String : "",

      token: (map.containsKey('token') && map['token'] != null) ? map['token'] as String : "",
      refreshToken: (map.containsKey('refresh_token') && map['refresh_token'] != null) ? map['refresh_token'] as String : "",
      expiresAt: (map.containsKey('expires_at') && map['expires_at'] != null) ? map['expires_at'] as int : 0,
      active: (map.containsKey('active') && map['active'] != null) ? map['active'] as bool : false,
      roleModel: (map.containsKey('role') && map['role'] != null) ? UserRoleModel.fromMap(map['role']) : UserRoleModel.getInstance(),
      mobileVerified: (map.containsKey('mobile_verified') && map['mobile_verified'] != null) ? map['mobile_verified'] as bool : false,
      emailVerified: (map.containsKey('email_verified') && map['email_verified'] != null) ? map['email_verified'] as bool : false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': appId,
      'name': name,
      'mobile_number': mobileNo,
      'email_id': emailId,
      'email_verified': emailVerified,
      'mobile_verified': mobileVerified,
      'last_login': lastLogin,
      'token': token,
      'refresh_token': refreshToken,
      'expires_at': expiresAt,
      'active': active,
      'role': roleModel.toMap(),
      'role_id': roleModel.id,
    };
  }

  Map<String, dynamic> toTableList() {
    return <String, dynamic>{
      'id': id,
      'User Id': appId,
      'name': name,
      'role': roleModel.name,
      'mobile Number': mobileNo,
      'email Id': emailId,
      'email_verified': emailVerified,
      'mobile_verified': mobileVerified,
      'last_login': lastLogin,
      'refresh_token': refreshToken,
      'expires_at': expiresAt,
      'active': active,
    };
  }

  UserModel copyWith({
    String? id,
    String? appId,
    String? name,
    String? mobileNo,
    String? emailId,
    bool? emailVerified,
    bool? mobileVerified,
    String? lastLogin,
    String? token,
    String? refreshToken,
    int? expiresAt,
    bool? active,
    UserRoleModel? roleModel,
  }) {
    return UserModel(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      name: name ?? this.name,
      mobileNo: mobileNo ?? this.mobileNo,
      emailId: emailId ?? this.emailId,
      lastLogin: lastLogin ?? this.lastLogin,
      mobileVerified: mobileVerified ?? this.mobileVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      active: active ?? this.active,
      roleModel: roleModel ?? this.roleModel,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
