import 'dart:async';
import 'package:chime/common/common.dart';
import 'package:get_it/get_it.dart';
import "package:logger/logger.dart";

class UsersRepository {
  final log = Logger();
  GetIt getIt = GetIt.instance;
  final PreferencesRepository prefRepo;
  final NetworkAwareApiRepository apiRepo;

  UsersRepository({required this.prefRepo, required this.apiRepo});

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      dynamic response = await apiRepo.getRequest(url: Constants.API_MAP['users']!);
      if (response is List) {
        return response.map((datum) => Map<String, dynamic>.from(datum as Map)).toList();
      } else {
        throw Exception("Expected 'data' to be a List but got ${response.runtimeType}");
      }
    } catch (error) {
      log.e("UsersRepository:::getUsers::Error:$error");
      throw Exception('$error');
    }
  }
}
