import 'package:cloud_firestore/cloud_firestore.dart';

enum CallType { video, audio }
enum CallStatus { pending, ongoing, completed, missed, cancelled }

class VideoCallModel {
  final String callId;
  final String appointmentId;
  final String doctorId;
  final String patientId;
  final String doctorName;
  final String patientName;
  final CallType callType;
  final CallStatus status;
  final DateTime scheduledTime;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? duration; // in seconds
  final String? channelName;
  final String? token;
  final String? notes;

  VideoCallModel({
    required this.callId,
    required this.appointmentId,
    required this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.patientName,
    required this.callType,
    required this.status,
    required this.scheduledTime,
    this.startedAt,
    this.endedAt,
    this.duration,
    this.channelName,
    this.token,
    this.notes,
  });

  factory VideoCallModel.fromJson(Map<String, dynamic> json, String id) {
    return VideoCallModel(
      callId: id,
      appointmentId: json['appointmentId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      patientName: json['patientName'] ?? '',
      callType: CallType.values.firstWhere(
        (e) => e.name == json['callType'],
        orElse: () => CallType.video,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CallStatus.pending,
      ),
      scheduledTime: json['scheduledTime'] is Timestamp
          ? (json['scheduledTime'] as Timestamp).toDate()
          : DateTime.parse(json['scheduledTime'] ?? DateTime.now().toIso8601String()),
      startedAt: json['startedAt'] != null
          ? (json['startedAt'] is Timestamp
              ? (json['startedAt'] as Timestamp).toDate()
              : DateTime.parse(json['startedAt']))
          : null,
      endedAt: json['endedAt'] != null
          ? (json['endedAt'] is Timestamp
              ? (json['endedAt'] as Timestamp).toDate()
              : DateTime.parse(json['endedAt']))
          : null,
      duration: json['duration'],
      channelName: json['channelName'],
      token: json['token'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'doctorId': doctorId,
      'patientId': patientId,
      'doctorName': doctorName,
      'patientName': patientName,
      'callType': callType.name,
      'status': status.name,
      'scheduledTime': scheduledTime.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'duration': duration,
      'channelName': channelName,
      'token': token,
      'notes': notes,
    };
  }

  VideoCallModel copyWith({
    String? callId,
    String? appointmentId,
    String? doctorId,
    String? patientId,
    String? doctorName,
    String? patientName,
    CallType? callType,
    CallStatus? status,
    DateTime? scheduledTime,
    DateTime? startedAt,
    DateTime? endedAt,
    int? duration,
    String? channelName,
    String? token,
    String? notes,
  }) {
    return VideoCallModel(
      callId: callId ?? this.callId,
      appointmentId: appointmentId ?? this.appointmentId,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      doctorName: doctorName ?? this.doctorName,
      patientName: patientName ?? this.patientName,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      channelName: channelName ?? this.channelName,
      token: token ?? this.token,
      notes: notes ?? this.notes,
    );
  }
}
