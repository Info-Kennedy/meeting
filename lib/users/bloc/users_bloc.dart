import 'package:bloc/bloc.dart';
import 'package:chime/common/utils/error_handler.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:chime/users/repository/users_repository.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final log = Logger();
  final UsersRepository _repository;

  UsersBloc({required UsersRepository repository}) : _repository = repository, super(UsersState.initial) {
    on<InitializeUsersPage>(_onInitializeUsersPageToState);
  }

  Future<void> _onInitializeUsersPageToState(InitializeUsersPage event, Emitter<UsersState> emit) async {
    try {
      log.d("UsersBloc:::_onInitializeUsersPageToState::event: $event");
      emit(state.copyWith(status: () => UsersStatus.initial));
      List<Map<String, dynamic>> users = await _repository.getUsers();
      emit(state.copyWith(status: () => UsersStatus.success, users: () => users));
    } catch (error) {
      log.e("UsersBloc::Error in _onInitializeUsersPageToState: $error");
      emit(state.copyWith(status: () => UsersStatus.error, message: () => ErrorHandler.handleException(error as Exception)));
    } finally {
      emit(state.copyWith(status: () => UsersStatus.loaded));
    }
  }
}
