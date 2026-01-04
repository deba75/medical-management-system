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
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
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
