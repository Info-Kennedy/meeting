import 'dart:async';
import 'package:chime/common/common.dart';
import 'package:get_it/get_it.dart';
import "package:logger/logger.dart";

class MeetingsRepository {
  final log = Logger();
  GetIt getIt = GetIt.instance;
  final PreferencesRepository prefRepo;
  final NetworkAwareApiRepository apiRepo;

  MeetingsRepository({required this.prefRepo, required this.apiRepo});

  Future<List<Map<String, dynamic>>> getMeetings() async {
    try {
      // dynamic response = await apiRepo.getRequest(url: Constants.API_MAP['meetings']!);
      // if (response is List) {
      //   return response.map((datum) => Map<String, dynamic>.from(datum as Map)).toList();
      // } else {
      //   throw Exception("Expected 'meetings' to be a List but got ${response.runtimeType}");
      // }
      return [
        {'title': 'Meeting 1', 'description': 'Description 1'},
        {'title': 'Meeting 2', 'description': 'Description 2'},
      ];
    } catch (error) {
      log.e("MeetingsRepository:::getMeetings::Error:$error");
      throw Exception('$error');
    }
  }
}
