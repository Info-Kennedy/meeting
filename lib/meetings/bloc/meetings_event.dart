part of 'meetings_bloc.dart';

sealed class MeetingsEvent extends Equatable {
  const MeetingsEvent();

  @override
  List<Object> get props => [];
}

class InitializeMeetingsPage extends MeetingsEvent {
  const InitializeMeetingsPage();
}
