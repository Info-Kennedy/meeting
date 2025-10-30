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
    on<RefreshUsers>(_onRefreshUsersToState);
  }

  Future<void> _onInitializeUsersPageToState(InitializeUsersPage event, Emitter<UsersState> emit) async {
    try {
      log.d("UsersBloc:::_onInitializeUsersPageToState::event: $event");
      emit(state.copyWith(status: () => UsersStatus.loading));

      // Load users (offline-first: will return cached if available, then refresh in background)
      List<Map<String, dynamic>> users = await _repository.getUsers();
      emit(state.copyWith(status: () => UsersStatus.success, users: () => users));
    } catch (error) {
      log.e("UsersBloc::Error in _onInitializeUsersPageToState: $error");
      emit(state.copyWith(status: () => UsersStatus.error, message: () => ErrorHandler.handleException(error as Exception)));
    } finally {
      emit(state.copyWith(status: () => UsersStatus.loaded));
    }
  }

  Future<void> _onRefreshUsersToState(RefreshUsers event, Emitter<UsersState> emit) async {
    try {
      log.d("UsersBloc:::_onRefreshUsersToState::event: $event");
      emit(state.copyWith(status: () => UsersStatus.loading));

      // Force refresh from API
      List<Map<String, dynamic>> users = await _repository.getUsers(forceRefresh: true);
      emit(state.copyWith(status: () => UsersStatus.success, users: () => users, message: () => ""));
    } catch (error) {
      log.e("UsersBloc::Error in _onRefreshUsersToState: $error");
      emit(state.copyWith(status: () => UsersStatus.error, message: () => ErrorHandler.handleException(error as Exception)));
    } finally {
      emit(state.copyWith(status: () => UsersStatus.loaded));
    }
  }
}
