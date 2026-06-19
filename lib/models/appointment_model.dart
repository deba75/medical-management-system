import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? hospitalId;
  final String? hospitalName;
  final AppointmentStatus status;
  final String? reason;
  final String? notes;
  // Payment fields
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final double? consultationFee;
  final String? transactionId;
  final DateTime? paymentDate;

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
    this.hospitalId,
    this.hospitalName,
    required this.status,
    this.reason,
    this.notes,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMethod = PaymentMethod.payInPerson,
    this.consultationFee,
    this.transactionId,
    this.paymentDate,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json, String id) {
    // Handle date parsing - can be Timestamp or String
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is String) return DateTime.parse(dateValue);
      // Firestore Timestamp
      if (dateValue.runtimeType.toString().contains('Timestamp')) {
        return (dateValue as dynamic).toDate();
      }
      return DateTime.now();
    }

    return AppointmentModel(
      appointmentId: id,
      doctorId: json['doctorId'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      patientName: json['patientName'] ?? '',
      specialization: json['specialization'] ?? '',
      date: parseDate(json['date']),
      timeSlotId: json['timeSlotId'] ?? '',
      timeSlot: json['timeSlot'] ?? '',
      hospitalId: json['hospitalId'],
      hospitalName: json['hospitalName'],
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString() == 'AppointmentStatus.${json['status']}',
        orElse: () => AppointmentStatus.upcoming,
      ),
      reason: json['reason'],
      notes: json['notes'],
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${json['paymentStatus']}',
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${json['paymentMethod']}',
        orElse: () => PaymentMethod.payInPerson,
      ),
      consultationFee: (json['consultationFee'] as num?)?.toDouble(),
      transactionId: json['transactionId'],
      paymentDate: json['paymentDate'] != null 
          ? parseDate(json['paymentDate']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'doctorName': doctorName,
      'patientName': patientName,
      'specialization': specialization,
      'date': Timestamp.fromDate(date), // Store as Firestore Timestamp
      'timeSlotId': timeSlotId,
      'timeSlot': timeSlot,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'status': status.name,
      'reason': reason,
      'notes': notes,
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod.name,
      'consultationFee': consultationFee,
      'transactionId': transactionId,
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'createdAt': FieldValue.serverTimestamp(), // Add server timestamp
    };
  }

  AppointmentModel copyWith({
    String? appointmentId,
    String? doctorId,
    String? patientId,
    String? doctorName,
    String? patientName,
    String? specialization,
    DateTime? date,
    String? timeSlotId,
    String? timeSlot,
    String? hospitalId,
    String? hospitalName,
    AppointmentStatus? status,
    String? reason,
    String? notes,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    double? consultationFee,
    String? transactionId,
    DateTime? paymentDate,
  }) {
    return AppointmentModel(
      appointmentId: appointmentId ?? this.appointmentId,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      doctorName: doctorName ?? this.doctorName,
      patientName: patientName ?? this.patientName,
      specialization: specialization ?? this.specialization,
      date: date ?? this.date,
      timeSlotId: timeSlotId ?? this.timeSlotId,
      timeSlot: timeSlot ?? this.timeSlot,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      consultationFee: consultationFee ?? this.consultationFee,
      transactionId: transactionId ?? this.transactionId,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }
}

enum AppointmentStatus {
  upcoming,
  completed,
  cancelled,
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
}

enum PaymentMethod {
  online,
  payInPerson,
}
