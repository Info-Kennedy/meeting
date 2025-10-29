import 'package:logger/logger.dart';

class UserRoleModel {
  final String id;
  final String name;
  final bool active;

  UserRoleModel({required this.id, required this.name, required this.active});

  static UserRoleModel getInstance() {
    return UserRoleModel(id: "", name: "", active: false);
  }

  factory UserRoleModel.fromMap(Map<String, dynamic> map) {
    final log = Logger();
    try {
      return UserRoleModel(
        id: (map.containsKey('id') && map['id'] != null) ? map['id'] as String : "",
        name: (map.containsKey('name') && map['name'] != null) ? map['name'] as String : "",
        active: (map.containsKey('active') && map['active'] != null) ? map['active'] as bool : false,
      );
    } catch (error) {
      log.e("RoleModel:::fromMap::Error: $error");
      throw Exception(error);
    }
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
