import 'package:chime/common/common.dart';
import 'package:chime/common/services/token_service.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:chime/home/bloc/home_bloc.dart';
import 'package:chime/home/repository/home_repository.dart';
import 'package:chime/login/repository/login_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupLocator() async {
  // Register FlutterSecureStorage
  const secureStorage = FlutterSecureStorage();
  getIt.registerSingleton<FlutterSecureStorage>(secureStorage);

  // Register PreferencesRepository
  getIt.registerSingleton<PreferencesRepository>(PreferencesRepository(secureStorage));

  // Initialize and configure Encrypted Sembast DB
  final dbService = EncryptedDatabaseService(secureStorage);
  await dbService.initialize();
  getIt.registerSingleton<EncryptedDatabaseService>(dbService);

  //Register DIO
  getIt.registerSingleton<Dio>(Dio());

  // Register TokenService first (needed by ApiRepository)
  getIt.registerSingleton<TokenService>(
    TokenService(prefRepo: getIt<PreferencesRepository>(), apiRepo: null), // Will be updated after ApiRepository is created
  );

  // Register ApiRepository
  getIt.registerSingleton<ApiRepository>(ApiRepository(getIt<Dio>(), getIt<PreferencesRepository>(), tokenService: getIt<TokenService>()));

  // Update TokenService with the ApiRepository
  getIt.get<TokenService>().apiRepo = getIt<ApiRepository>();

  // Register NetworkService first
  getIt.registerSingleton<NetworkService>(NetworkService());

  // Register NetworkBloc
  getIt.registerSingleton<NetworkBloc>(NetworkBloc());

  // Register NetworkAwareApiRepository after NetworkService
  getIt.registerSingleton<NetworkAwareApiRepository>(
    NetworkAwareApiRepository(apiRepository: getIt<ApiRepository>(), networkService: getIt<NetworkService>(), tokenService: getIt<TokenService>()),
  );

  getIt.registerSingleton<HomeBloc>(
    HomeBloc(
      repository: HomeRepository(prefRepo: getIt<PreferencesRepository>(), apiRepo: getIt<NetworkAwareApiRepository>()),
    ),
  );

  // Register LoginRepository with NetworkAwareApiRepository
  getIt.registerSingleton<LoginRepository>(LoginRepository(prefRepo: getIt<PreferencesRepository>(), apiRepo: getIt<NetworkAwareApiRepository>()));
}
