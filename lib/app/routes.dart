import 'package:chime/common/common.dart';
import 'package:chime/home/views/home_page.dart';
import 'package:chime/login/bloc/login_bloc.dart';
import 'package:chime/login/views/login_page.dart';
import 'package:chime/meetings/models/meeting_model.dart';
import 'package:chime/meetings/views/active_meeting_screen.dart';
import 'package:chime/meetings/views/meetings_page.dart';
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

      GoRoute(
        name: RouteNames.meetings,
        path: '/meetings',
        builder: (BuildContext context, GoRouterState state) {
          return const MeetingsPage();
        },
      ),

      GoRoute(
        name: RouteNames.activeMeeting,
        path: '/meetings/active',
        builder: (BuildContext context, GoRouterState state) {
          final meeting = state.extra as MeetingModel?;
          if (meeting == null) {
            // If no meeting data, show error and navigate back after a delay
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No meeting data available')));
                context.pop();
              }
            });
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return ActiveMeetingScreen(meeting: meeting);
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool signedIn = context.read<LoginBloc>().state.status == LoginStatus.loggedIn;
      final location = state.matchedLocation;

      // Don't redirect from meetings pages or active meeting
      if (location.startsWith('/meetings')) {
        // If not signed in and trying to access meetings, redirect to login
        if (!signedIn) {
          return '/login';
        }
        return null; // Allow access to meetings pages when signed in
      }

      // Redirect to home if signed in and trying to access login
      if (signedIn && location == '/login') {
        return '/home';
      }

      // Redirect to login if not signed in and not already on login
      if (!signedIn && location != '/login') {
        return '/login';
      }

      return null; // No redirect needed
    },
    debugLogDiagnostics: true,
    // changes on the listenable will cause the router to refresh it's route
    // refreshListenable: GoRouterRefreshStream(_loginBloc.stream),
  );
}
