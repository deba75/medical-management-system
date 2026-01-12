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
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
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
