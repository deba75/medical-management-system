import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper function to convert Firestore Timestamp or String to DateTime
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

class MedicalHistoryModel {
  final String historyId;
  final String patientId;
  final String? doctorId;
  final String? doctorName;
  final String notes;
  final String? diagnosis;
  final List<String> medicines;
  final List<String> reportsURLs;
  final DateTime createdAt;

  MedicalHistoryModel({
    required this.historyId,
    required this.patientId,
    this.doctorId,
    this.doctorName,
    required this.notes,
    this.diagnosis,
    this.medicines = const [],
    this.reportsURLs = const [],
    required this.createdAt,
  });

  factory MedicalHistoryModel.fromJson(Map<String, dynamic> json, String id) {
    return MedicalHistoryModel(
      historyId: id,
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'],
      doctorName: json['doctorName'],
      notes: json['notes'] ?? '',
      diagnosis: json['diagnosis'],
      medicines: List<String>.from(json['medicines'] ?? []),
      reportsURLs: List<String>.from(json['reportsURLs'] ?? []),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'notes': notes,
      'diagnosis': diagnosis,
      'medicines': medicines,
      'reportsURLs': reportsURLs,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
