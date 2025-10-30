part of 'meetings_bloc.dart';

sealed class MeetingsEvent extends Equatable {
  const MeetingsEvent();

  @override
  List<Object> get props => [];
}

class InitializeMeetingsPage extends MeetingsEvent {
  const InitializeMeetingsPage();
}

class CreateMeeting extends MeetingsEvent {
  final String title;
  final String? description;
  final String? mediaRegion;

  const CreateMeeting({required this.title, this.description, this.mediaRegion});

  @override
  List<Object> get props => [title, description ?? '', mediaRegion ?? ''];
}

class JoinMeeting extends MeetingsEvent {
  final String meetingId;
  final String? name;

  const JoinMeeting({required this.meetingId, this.name});

  @override
  List<Object> get props => [meetingId, name ?? ''];
}

class RefreshMeetings extends MeetingsEvent {
  const RefreshMeetings();
}
