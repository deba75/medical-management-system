import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper function to convert Firestore Timestamp or String to DateTime
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

class PrescriptionModel {
  final String prescriptionId;
  final String appointmentId;
  final String doctorId;
  final String patientId;
  final String doctorName;
  final String fileURL;
  final String? notes;
  final DateTime createdAt;

  PrescriptionModel({
    required this.prescriptionId,
    required this.appointmentId,
    required this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.fileURL,
    this.notes,
    required this.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json, String id) {
    return PrescriptionModel(
      prescriptionId: id,
      appointmentId: json['appointmentId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      fileURL: json['fileURL'] ?? '',
      notes: json['notes'],
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'doctorId': doctorId,
      'patientId': patientId,
      'doctorName': doctorName,
      'fileURL': fileURL,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
