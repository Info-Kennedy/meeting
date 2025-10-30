import 'package:bloc/bloc.dart';
import 'package:chime/common/utils/error_handler.dart';
import 'package:chime/meetings/models/meeting_model.dart';
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
    on<CreateMeeting>(_onCreateMeeting);
    on<JoinMeeting>(_onJoinMeeting);
    on<RefreshMeetings>(_onRefreshMeetings);
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

  Future<void> _onCreateMeeting(CreateMeeting event, Emitter<MeetingsState> emit) async {
    try {
      log.d("MeetingsBloc:::_onCreateMeeting::event: $event");
      emit(state.copyWith(status: () => MeetingsStatus.loading));

      final meeting = await _repository.createMeeting(title: event.title, description: event.description, mediaRegion: event.mediaRegion);
      log.d("MeetingsBloc:::_onCreateMeeting::Meeting created successfully: ${meeting.roomName}");

      // Refresh meetings list
      List<Map<String, dynamic>> meetings = await _repository.getMeetings();

      emit(
        state.copyWith(
          status: () => MeetingsStatus.meetingCreated,
          meetings: () => meetings,
          currentMeeting: meeting,
          message: () => 'Meeting created successfully',
        ),
      );
      log.d("MeetingsBloc:::_onCreateMeeting::Emitted meetingCreated status");
    } catch (error) {
      log.e("MeetingsBloc::Error in _onCreateMeeting: $error");
      emit(state.copyWith(status: () => MeetingsStatus.error, message: () => ErrorHandler.handleException(error as Exception)));
    }
    // Note: Removed finally block that was setting status to 'loaded' too early
    // The status should remain as 'meetingCreated' until navigation completes
  }

  Future<void> _onJoinMeeting(JoinMeeting event, Emitter<MeetingsState> emit) async {
    try {
      log.d("MeetingsBloc:::_onJoinMeeting::event: $event");
      emit(state.copyWith(status: () => MeetingsStatus.loading));

      final meeting = await _repository.joinMeeting(meetingId: event.meetingId, name: event.name);
      log.d("MeetingsBloc:::_onJoinMeeting::Meeting joined successfully: ${meeting.roomName}");

      emit(state.copyWith(status: () => MeetingsStatus.meetingJoined, currentMeeting: meeting, message: () => 'Joined meeting successfully'));
      log.d("MeetingsBloc:::_onJoinMeeting::Emitted meetingJoined status");
    } catch (error) {
      log.e("MeetingsBloc::Error in _onJoinMeeting: $error");
      emit(state.copyWith(status: () => MeetingsStatus.error, message: () => ErrorHandler.handleException(error as Exception)));
    }
    // Note: Removed finally block that was setting status to 'loaded' too early
    // The status should remain as 'meetingJoined' until navigation completes
  }

  Future<void> _onRefreshMeetings(RefreshMeetings event, Emitter<MeetingsState> emit) async {
    try {
      log.d("MeetingsBloc:::_onRefreshMeetings::event: $event");
      emit(state.copyWith(status: () => MeetingsStatus.loading));
      List<Map<String, dynamic>> meetings = await _repository.getMeetings();
      emit(state.copyWith(status: () => MeetingsStatus.success, meetings: () => meetings));
    } catch (error) {
      log.e("MeetingsBloc::Error in _onRefreshMeetings: $error");
      emit(state.copyWith(status: () => MeetingsStatus.error, message: () => ErrorHandler.handleException(error as Exception)));
    } finally {
      emit(state.copyWith(status: () => MeetingsStatus.loaded));
    }
  }
}
