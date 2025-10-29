import 'package:bloc/bloc.dart';
import 'package:chime/common/utils/error_handler.dart';
import 'package:chime/meetings/repository/meetings_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

part 'meetings_event.dart';
part 'meetings_state.dart';

class MeetingsBloc extends Bloc<MeetingsEvent, MeetingsState> {
  final log = Logger();
  final MeetingsRepository _repository;

  MeetingsBloc({required MeetingsRepository repository}) : _repository = repository, super(MeetingsState.initial) {
    on<InitializeMeetingsPage>(_onInitializeMeetingsPageToState);
  }

  Future<void> _onInitializeMeetingsPageToState(InitializeMeetingsPage event, Emitter<MeetingsState> emit) async {
    try {
      log.d("MeetingsBloc:::_onInitializeMeetingsPageToState::event: $event");
      emit(state.copyWith(status: () => MeetingsStatus.initial));
      List<Map<String, dynamic>> meetings = await _repository.getMeetings();
      emit(state.copyWith(status: () => MeetingsStatus.success, meetings: () => meetings));
    } catch (error) {
      log.e("MeetingsBloc::Error in _onInitializeMeetingsPageToState: $error");
      emit(state.copyWith(status: () => MeetingsStatus.error, message: () => ErrorHandler.handleException(error as Exception)));
    } finally {
      emit(state.copyWith(status: () => MeetingsStatus.loaded));
    }
  }
}
