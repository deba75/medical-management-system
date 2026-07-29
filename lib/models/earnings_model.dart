import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { consultation, labReferral, prescription, refund }
enum PaymentStatus { pending, completed, failed, refunded }
enum PayoutStatus { pending, processed, failed }

class EarningsModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String? appointmentId;
  final TransactionType type;
  final double amount;
  final double platformFee;
  final double netAmount;
  final PaymentStatus paymentStatus;
  final String? transactionId;
  final String? description;
  final DateTime createdAt;

  EarningsModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    this.appointmentId,
    required this.type,
    required this.amount,
    required this.platformFee,
    required this.netAmount,
    required this.paymentStatus,
    this.transactionId,
    this.description,
    required this.createdAt,
  });

  factory EarningsModel.fromJson(Map<String, dynamic> json, String id) {
    return EarningsModel(
      id: id,
      doctorId: json['doctorId'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      appointmentId: json['appointmentId'],
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.consultation,
      ),
      amount: (json['amount'] ?? 0).toDouble(),
      platformFee: (json['platformFee'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? 0).toDouble(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      transactionId: json['transactionId'],
      description: json['description'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'appointmentId': appointmentId,
      'type': type.name,
      'amount': amount,
      'platformFee': platformFee,
      'netAmount': netAmount,
      'paymentStatus': paymentStatus.name,
      'transactionId': transactionId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get typeDisplay {
    switch (type) {
      case TransactionType.consultation:
        return 'Consultation';
      case TransactionType.labReferral:
        return 'Lab Referral';
      case TransactionType.prescription:
        return 'Prescription';
      case TransactionType.refund:
        return 'Refund';
    }
  }

  String get typeIcon {
    switch (type) {
      case TransactionType.consultation:
        return '👨‍⚕️';
      case TransactionType.labReferral:
        return '🧪';
      case TransactionType.prescription:
        return '💊';
      case TransactionType.refund:
        return '↩️';
    }
  }
}

class EarningsSummary {
  final String doctorId;
  final double totalEarnings;
  final double pendingAmount;
  final double thisMonthEarnings;
  final double lastMonthEarnings;
  final int totalConsultations;
  final int thisMonthConsultations;
  final Map<String, double> monthlyEarnings; // {"2024-01": 5000, "2024-02": 6000}
  final Map<String, int> monthlyConsultations;
  final DateTime lastUpdated;

  EarningsSummary({
    required this.doctorId,
    required this.totalEarnings,
    required this.pendingAmount,
    required this.thisMonthEarnings,
    required this.lastMonthEarnings,
    required this.totalConsultations,
    required this.thisMonthConsultations,
    required this.monthlyEarnings,
    required this.monthlyConsultations,
    required this.lastUpdated,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      doctorId: json['doctorId'] ?? '',
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      pendingAmount: (json['pendingAmount'] ?? 0).toDouble(),
      thisMonthEarnings: (json['thisMonthEarnings'] ?? 0).toDouble(),
      lastMonthEarnings: (json['lastMonthEarnings'] ?? 0).toDouble(),
      totalConsultations: json['totalConsultations'] ?? 0,
      thisMonthConsultations: json['thisMonthConsultations'] ?? 0,
      monthlyEarnings: Map<String, double>.from(
        (json['monthlyEarnings'] ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      monthlyConsultations: Map<String, int>.from(json['monthlyConsultations'] ?? {}),
      lastUpdated: json['lastUpdated'] is Timestamp
          ? (json['lastUpdated'] as Timestamp).toDate()
          : DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'totalEarnings': totalEarnings,
      'pendingAmount': pendingAmount,
      'thisMonthEarnings': thisMonthEarnings,
      'lastMonthEarnings': lastMonthEarnings,
      'totalConsultations': totalConsultations,
      'thisMonthConsultations': thisMonthConsultations,
      'monthlyEarnings': monthlyEarnings,
      'monthlyConsultations': monthlyConsultations,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  double get growthPercentage {
    if (lastMonthEarnings == 0) return thisMonthEarnings > 0 ? 100 : 0;
    return ((thisMonthEarnings - lastMonthEarnings) / lastMonthEarnings) * 100;
  }

  double get averagePerConsultation {
    if (totalConsultations == 0) return 0;
    return totalEarnings / totalConsultations;
  }
}

class PayoutModel {
  final String id;
  final String doctorId;
  final double amount;
  final PayoutStatus status;
  final String bankAccount;
  final String? transactionRef;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? notes;

  PayoutModel({
    required this.id,
    required this.doctorId,
    required this.amount,
    required this.status,
    required this.bankAccount,
    this.transactionRef,
    required this.requestedAt,
    this.processedAt,
    this.notes,
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json, String id) {
    return PayoutModel(
      id: id,
      doctorId: json['doctorId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: PayoutStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PayoutStatus.pending,
      ),
      bankAccount: json['bankAccount'] ?? '',
      transactionRef: json['transactionRef'],
      requestedAt: json['requestedAt'] is Timestamp
          ? (json['requestedAt'] as Timestamp).toDate()
          : DateTime.parse(json['requestedAt'] ?? DateTime.now().toIso8601String()),
      processedAt: json['processedAt'] != null
          ? (json['processedAt'] is Timestamp
              ? (json['processedAt'] as Timestamp).toDate()
              : DateTime.parse(json['processedAt']))
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'amount': amount,
      'status': status.name,
      'bankAccount': bankAccount,
      'transactionRef': transactionRef,
      'requestedAt': requestedAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  String get statusDisplay {
    switch (status) {
      case PayoutStatus.pending:
        return 'Pending';
      case PayoutStatus.processed:
        return 'Processed';
      case PayoutStatus.failed:
        return 'Failed';
    }
  }
}
