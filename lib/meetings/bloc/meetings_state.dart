part of 'meetings_bloc.dart';

enum MeetingsStatus { initial, loading, loaded, success, error }

class MeetingsState extends Equatable {
  final String message;
  final MeetingsStatus status;
  final List<Map<String, dynamic>> meetings;

  const MeetingsState({required this.status, required this.meetings, required this.message});

  static MeetingsState initial = MeetingsState(status: MeetingsStatus.initial, meetings: const [], message: "");

  MeetingsState copyWith({MeetingsStatus Function()? status, List<Map<String, dynamic>> Function()? meetings, String Function()? message}) {
    return MeetingsState(
      status: status != null ? status() : this.status,
      meetings: meetings != null ? meetings() : this.meetings,
      message: message != null ? message() : this.message,
    );
  }

  @override
  List<Object?> get props => [status, meetings, message];
}
