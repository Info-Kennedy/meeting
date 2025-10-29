import 'package:chime/common/common.dart';
import 'package:chime/meetings/bloc/meetings_bloc.dart';
import 'package:chime/meetings/repository/meetings_repository.dart';
import 'package:chime/meetings/views/meetings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MeetingsPage extends StatelessWidget {
  const MeetingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MeetingsBloc(
        repository: MeetingsRepository(prefRepo: getIt<PreferencesRepository>(), apiRepo: getIt<NetworkAwareApiRepository>()),
      )..add(InitializeMeetingsPage()),
      child: const MeetingsScreen(),
    );
  }
}
