import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralModel {
  final String id;
  final String referringDoctorId;
  final String referringDoctorName;
  final String referredDoctorId;
  final String referredDoctorName;
  final String referredSpecialty;
  final String patientId;
  final String patientName;
  final String reason;
  final String? clinicalNotes;
  final String? urgency; // routine, urgent, emergency
  final List<String>? attachments;
  final String status; // pending, accepted, completed, cancelled
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? feedback;

  ReferralModel({
    required this.id,
    required this.referringDoctorId,
    required this.referringDoctorName,
    required this.referredDoctorId,
    required this.referredDoctorName,
    required this.referredSpecialty,
    required this.patientId,
    required this.patientName,
    required this.reason,
    this.clinicalNotes,
    this.urgency,
    this.attachments,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.feedback,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json, String id) {
    return ReferralModel(
      id: id,
      referringDoctorId: json['referringDoctorId'] ?? '',
      referringDoctorName: json['referringDoctorName'] ?? '',
      referredDoctorId: json['referredDoctorId'] ?? '',
      referredDoctorName: json['referredDoctorName'] ?? '',
      referredSpecialty: json['referredSpecialty'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      reason: json['reason'] ?? '',
      clinicalNotes: json['clinicalNotes'],
      urgency: json['urgency'],
      attachments: json['attachments'] != null 
          ? List<String>.from(json['attachments']) 
          : null,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      acceptedAt: json['acceptedAt'] != null
          ? (json['acceptedAt'] is Timestamp
              ? (json['acceptedAt'] as Timestamp).toDate()
              : DateTime.parse(json['acceptedAt']))
          : null,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] is Timestamp
              ? (json['completedAt'] as Timestamp).toDate()
              : DateTime.parse(json['completedAt']))
          : null,
      feedback: json['feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referringDoctorId': referringDoctorId,
      'referringDoctorName': referringDoctorName,
      'referredDoctorId': referredDoctorId,
      'referredDoctorName': referredDoctorName,
      'referredSpecialty': referredSpecialty,
      'patientId': patientId,
      'patientName': patientName,
      'reason': reason,
      'clinicalNotes': clinicalNotes,
      'urgency': urgency,
      'attachments': attachments,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'feedback': feedback,
    };
  }

  String get urgencyDisplay {
    switch (urgency) {
      case 'routine':
        return 'Routine';
      case 'urgent':
        return 'Urgent';
      case 'emergency':
        return 'Emergency';
      default:
        return 'Routine';
    }
  }

  String get urgencyEmoji {
    switch (urgency) {
      case 'routine':
        return '🟢';
      case 'urgent':
        return '🟡';
      case 'emergency':
        return '🔴';
      default:
        return '⚪';
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  ReferralModel copyWith({
    String? id,
    String? referringDoctorId,
    String? referringDoctorName,
    String? referredDoctorId,
    String? referredDoctorName,
    String? referredSpecialty,
    String? patientId,
    String? patientName,
    String? reason,
    String? clinicalNotes,
    String? urgency,
    List<String>? attachments,
    String? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    String? feedback,
  }) {
    return ReferralModel(
      id: id ?? this.id,
      referringDoctorId: referringDoctorId ?? this.referringDoctorId,
      referringDoctorName: referringDoctorName ?? this.referringDoctorName,
      referredDoctorId: referredDoctorId ?? this.referredDoctorId,
      referredDoctorName: referredDoctorName ?? this.referredDoctorName,
      referredSpecialty: referredSpecialty ?? this.referredSpecialty,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      reason: reason ?? this.reason,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      urgency: urgency ?? this.urgency,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      feedback: feedback ?? this.feedback,
    );
  }
}
