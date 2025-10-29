class RouteHistory {
  static final List<Map<String, dynamic>> _history = [];

  static void push(Map<String, dynamic> route) {
    _history.add(route);
  }

  static Map<String, dynamic>? get previousRoute {
    if (_history.length >= 2) {
      return _history[_history.length - 2];
    }
    return null;
  }

  static void pop() {
    if (_history.isNotEmpty) _history.removeLast();
  }

  static void clear() {
    _history.clear();
  }
}
