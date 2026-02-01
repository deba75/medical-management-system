import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper function to convert Firestore Timestamp or String to DateTime
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

class HealthMetrics {
  final int systolicBP;
  final int diastolicBP;
  final int heartRate;
  final DateTime timestamp;
  final String status; // normal, warning, critical

  HealthMetrics({
    required this.systolicBP,
    required this.diastolicBP,
    required this.heartRate,
    required this.timestamp,
    required this.status,
  });

  factory HealthMetrics.fromJson(Map<String, dynamic> json) {
    return HealthMetrics(
      systolicBP: json['systolicBP'] ?? 120,
      diastolicBP: json['diastolicBP'] ?? 80,
      heartRate: json['heartRate'] ?? 72,
      timestamp: _parseDateTime(json['timestamp']),
      status: json['status'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'heartRate': heartRate,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  String get bloodPressure => '$systolicBP/$diastolicBP';

  String get bpStatus {
    if (systolicBP > 140 || diastolicBP > 90) {
      return 'High';
    } else if (systolicBP < 90 || diastolicBP < 60) {
      return 'Low';
    }
    return 'Normal';
  }

  String get heartRateStatus {
    if (heartRate > 100) {
      return 'High';
    } else if (heartRate < 60) {
      return 'Low';
    }
    return 'Normal';
  }

  bool get isNormal => bpStatus == 'Normal' && heartRateStatus == 'Normal';
}
