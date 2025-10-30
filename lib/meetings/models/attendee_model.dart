class AttendeeModel {
  final String attendeeId; // Twilio participant identity (SID or identity string)
  final String? name; // Display name
  final bool isAudioEnabled;
  final bool isVideoEnabled;
  final bool isScreenShareEnabled;

  AttendeeModel({required this.attendeeId, this.name, this.isAudioEnabled = false, this.isVideoEnabled = false, this.isScreenShareEnabled = false});

  factory AttendeeModel.fromJson(Map<String, dynamic> json) {
    return AttendeeModel(
      attendeeId: json['attendeeId'] ?? json['identity'] ?? '',
      name: json['name'],
      isAudioEnabled: json['isAudioEnabled'] ?? false,
      isVideoEnabled: json['isVideoEnabled'] ?? false,
      isScreenShareEnabled: json['isScreenShareEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendeeId': attendeeId,
      'name': name,
      'isAudioEnabled': isAudioEnabled,
      'isVideoEnabled': isVideoEnabled,
      'isScreenShareEnabled': isScreenShareEnabled,
    };
  }

  bool get isScreenSharing => isScreenShareEnabled;
}
