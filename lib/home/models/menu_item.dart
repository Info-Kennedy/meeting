import 'package:logger/logger.dart';

class MenuItem {
  final String id;
  final String? parentId;
  final String name;
  final String icon;
  final String type;
  final String url;
  final Map<String, dynamic> params;
  final bool selected;
  final int level;
  final List<MenuItem> children;

  MenuItem({
    required this.id,
    this.parentId,
    required this.name,
    required this.type,
    required this.icon,
    required this.url,
    required this.params,
    required this.selected,
    required this.level,
    required this.children,
  });

  static MenuItem getInstance() {
    return MenuItem(
      id: "",
      parentId: null,
      name: "",
      icon: "",
      url: "",
      type: "",
      params: {},
      selected: false,
      level: 0,
      children: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "parent_id": parentId,
      "name": name,
      "type": type,
      "icon": icon,
      "url": url,
      "params": params,
      "selected": selected,
      "children": children.toString(),
    };
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final log = Logger();
    //log.d("MenuItems::In FromJson:: $json");
    try {
      List<dynamic> menuItems = json['children'] ?? [];
      return MenuItem(
        id: (json.containsKey('id') && json['id'] != null) ? json['id'] : "",
        parentId: (json.containsKey('parent_id') && json['parent_id'] != null) ? json['parent_id'] : null,
        name: (json.containsKey('name') && json['name'] != null) ? json['name'] : "",
        type: (json.containsKey('type') && json['type'] != null) ? json['type'] : "",
        icon: (json.containsKey('icon') && json['icon'] != null) ? json['icon'] : "",
        url: (json.containsKey('url') && json['url'] != null) ? json['url'] : "",
        params: (json.containsKey('params') && json['params'] != null) ? Map<String, dynamic>.from(json['params']) : {},
        selected: (json.containsKey('selected') && json['selected'] != null) ? json['selected'] as bool : false,
        level: (json.containsKey('level') && json['level'] != null) ? json['level'] as int : 0,
        children: menuItems.map((menuItem) => MenuItem.fromJson(menuItem)).toList(),
      );
    } catch (error) {
      log.e("MenuItem::In FromJson::Error:: $error");
      return MenuItem.getInstance();
    }
  }

  MenuItem copyWith({
    String? id,
    String? parentId,
    String? name,
    String? type,
    String? icon,
    String? url,
    Map<String, dynamic>? params,
    bool? selected,
    int? level,
    List<MenuItem>? children,
  }) {
    return MenuItem(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      url: url ?? this.url,
      params: params ?? this.params,
      selected: selected ?? this.selected,
      level: level ?? this.level,
      children: children ?? this.children,
    );
  }
}
