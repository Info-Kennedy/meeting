class MeetingModel {
  final String id;
  final String title;
  final String? description;
  final String? roomName; // Twilio room name
  final String? accessToken; // Twilio access token for connecting to room
  final String? identity; // User identity (optional)
  final DateTime? createdAt;
  final DateTime? scheduledAt;
  final bool isActive;

  MeetingModel({
    required this.id,
    required this.title,
    this.description,
    this.roomName,
    this.accessToken,
    this.identity,
    this.createdAt,
    this.scheduledAt,
    this.isActive = false,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id']?.toString() ?? json['roomName']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      roomName: json['roomName'] ?? json['RoomName'] ?? json['meetingId'], // Fallback for legacy data
      accessToken: json['accessToken'] ?? json['AccessToken'],
      identity: json['identity'] ?? json['Identity'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'roomName': roomName,
      'accessToken': accessToken,
      'identity': identity,
      'createdAt': createdAt?.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'isActive': isActive,
    };
  }
}
