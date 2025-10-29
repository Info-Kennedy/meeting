import 'package:chime/common/common.dart';
import 'package:chime/home/views/home_page.dart';
import 'package:chime/login/bloc/login_bloc.dart';
import 'package:chime/login/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';

class Routes {
  /// The route configuration.
  GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        name: RouteNames.login,
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          RouteHistory.push({'/login': state.extra});
          return const LoginPage();
        },
      ),

      GoRoute(
        name: RouteNames.home,
        path: '/home',
        builder: (BuildContext context, GoRouterState state) {
          return const HomePage();
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool signedIn = context.read<LoginBloc>().state.status == LoginStatus.loggedIn;
      if (signedIn) return '/home';
      return state.matchedLocation;
    },
    debugLogDiagnostics: true,
    // changes on the listenable will cause the router to refresh it's route
    // refreshListenable: GoRouterRefreshStream(_loginBloc.stream),
  );
}
