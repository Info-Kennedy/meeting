part of 'meetings_bloc.dart';

enum MeetingsStatus { initial, loading, loaded, success, error, meetingCreated, meetingJoined }

class MeetingsState extends Equatable {
  final String message;
  final MeetingsStatus status;
  final List<Map<String, dynamic>> meetings;
  final MeetingModel? currentMeeting;

  const MeetingsState({required this.status, required this.meetings, required this.message, this.currentMeeting});

  static MeetingsState initial = const MeetingsState(status: MeetingsStatus.initial, meetings: [], message: "");

  MeetingsState copyWith({
    MeetingsStatus Function()? status,
    List<Map<String, dynamic>> Function()? meetings,
    String Function()? message,
    MeetingModel? currentMeeting,
  }) {
    return MeetingsState(
      status: status != null ? status() : this.status,
      meetings: meetings != null ? meetings() : this.meetings,
      message: message != null ? message() : this.message,
      currentMeeting: currentMeeting ?? this.currentMeeting,
    );
  }

  @override
  List<Object?> get props => [status, meetings, message, currentMeeting];
}
