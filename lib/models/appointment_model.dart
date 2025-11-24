class AppointmentModel {
  final String appointmentId;
  final String doctorId;
  final String patientId;
  final String doctorName;
  final String patientName;
  final String specialization;
  final DateTime date;
  final String timeSlotId;
  final String timeSlot;
  final AppointmentStatus status;
  final String? reason;
  final String? notes;

  AppointmentModel({
    required this.appointmentId,
    required this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.patientName,
    required this.specialization,
    required this.date,
    required this.timeSlotId,
    required this.timeSlot,
    required this.status,
    this.reason,
    this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json, String id) {
    return AppointmentModel(
      appointmentId: id,
      doctorId: json['doctorId'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      patientName: json['patientName'] ?? '',
      specialization: json['specialization'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      timeSlotId: json['timeSlotId'] ?? '',
      timeSlot: json['timeSlot'] ?? '',
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString() == 'AppointmentStatus.${json['status']}',
        orElse: () => AppointmentStatus.upcoming,
      ),
      reason: json['reason'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'doctorName': doctorName,
      'patientName': patientName,
      'specialization': specialization,
      'date': date.toIso8601String(),
      'timeSlotId': timeSlotId,
      'timeSlot': timeSlot,
      'status': status.name,
      'reason': reason,
      'notes': notes,
    };
  }
}

enum AppointmentStatus {
  upcoming,
  completed,
  cancelled,
}
