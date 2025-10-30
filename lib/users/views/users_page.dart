import 'package:chime/common/common.dart';
import 'package:chime/users/bloc/users_bloc.dart';
import 'package:chime/users/repository/users_repository.dart';
import 'package:chime/users/views/users_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UsersBloc(
        repository: UsersRepository(
          prefRepo: getIt<PreferencesRepository>(),
          apiRepo: getIt<NetworkAwareApiRepository>(),
          dbService: getIt<EncryptedDatabaseService>(),
        ),
      )..add(InitializeUsersPage()),
      child: const UsersScreen(),
    );
  }
}
