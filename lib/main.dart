import 'package:chime/app/app.dart';
import 'package:chime/app/app_bloc_observer.dart';
import 'package:chime/home/bloc/home_bloc.dart';
import 'package:chime/login/bloc/login_bloc.dart';
import 'package:chime/login/repository/login_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'common/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EquatableConfig.stringify = kDebugMode;
  Bloc.observer = const AppBlocObserver();
  await setupLocator();

  // Initialize network service
  await getIt<NetworkService>().initialize();

  // Initialize language cache for CommonHelper
  await CommonHelper().initializeLanguage();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => getIt<PreferencesRepository>()),
        RepositoryProvider<ApiRepository>(create: (context) => getIt<ApiRepository>()),
        RepositoryProvider<NetworkAwareApiRepository>(create: (context) => getIt<NetworkAwareApiRepository>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (BuildContext context) {
              final loginBloc = LoginBloc(
                repository: LoginRepository(prefRepo: getIt<PreferencesRepository>(), apiRepo: getIt<NetworkAwareApiRepository>()),
              )..add(const InitializeLogin());
              // Set up 401 callback to trigger logout
              getIt<NetworkAwareApiRepository>().setUnauthorizedCallback(() {
                loginBloc.add(Logout());
              });
              return loginBloc;
            },
          ),
          BlocProvider(create: (BuildContext context) => getIt<HomeBloc>()),
          BlocProvider(create: (BuildContext context) => getIt<NetworkBloc>()),
        ],
        child: const App(),
      ),
    ),
  );
}
