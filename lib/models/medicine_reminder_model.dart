import 'package:cloud_firestore/cloud_firestore.dart';

enum MedicineType { tablet, capsule, syrup, injection, drops, cream, inhaler, other }
enum FrequencyType { daily, weekly, monthly, asNeeded }
enum MealTiming { beforeMeal, afterMeal, withMeal, anytime }

class MedicineReminderModel {
  final String id;
  final String patientId;
  final String medicineName;
  final MedicineType medicineType;
  final String dosage;
  final FrequencyType frequency;
  final List<String> timings; // List of times like "08:00", "14:00", "20:00"
  final MealTiming mealTiming;
  final DateTime startDate;
  final DateTime? endDate;
  final String? prescriptionId;
  final String? doctorId;
  final String? doctorName;
  final String? notes;
  final bool isActive;
  final int totalDoses;
  final int takenDoses;
  final List<DateTime> takenHistory;
  final DateTime createdAt;

  MedicineReminderModel({
    required this.id,
    required this.patientId,
    required this.medicineName,
    required this.medicineType,
    required this.dosage,
    required this.frequency,
    required this.timings,
    required this.mealTiming,
    required this.startDate,
    this.endDate,
    this.prescriptionId,
    this.doctorId,
    this.doctorName,
    this.notes,
    required this.isActive,
    required this.totalDoses,
    required this.takenDoses,
    required this.takenHistory,
    required this.createdAt,
  });

  factory MedicineReminderModel.fromJson(Map<String, dynamic> json, String id) {
    return MedicineReminderModel(
      id: id,
      patientId: json['patientId'] ?? '',
      medicineName: json['medicineName'] ?? '',
      medicineType: MedicineType.values.firstWhere(
        (e) => e.name == json['medicineType'],
        orElse: () => MedicineType.tablet,
      ),
      dosage: json['dosage'] ?? '',
      frequency: FrequencyType.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => FrequencyType.daily,
      ),
      timings: List<String>.from(json['timings'] ?? []),
      mealTiming: MealTiming.values.firstWhere(
        (e) => e.name == json['mealTiming'],
        orElse: () => MealTiming.afterMeal,
      ),
      startDate: json['startDate'] is Timestamp
          ? (json['startDate'] as Timestamp).toDate()
          : DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: json['endDate'] != null
          ? (json['endDate'] is Timestamp
              ? (json['endDate'] as Timestamp).toDate()
              : DateTime.parse(json['endDate']))
          : null,
      prescriptionId: json['prescriptionId'],
      doctorId: json['doctorId'],
      doctorName: json['doctorName'],
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
      totalDoses: json['totalDoses'] ?? 0,
      takenDoses: json['takenDoses'] ?? 0,
      takenHistory: (json['takenHistory'] as List<dynamic>?)
              ?.map((e) => e is Timestamp ? e.toDate() : DateTime.parse(e))
              .toList() ??
          [],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'medicineName': medicineName,
      'medicineType': medicineType.name,
      'dosage': dosage,
      'frequency': frequency.name,
      'timings': timings,
      'mealTiming': mealTiming.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'prescriptionId': prescriptionId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'notes': notes,
      'isActive': isActive,
      'totalDoses': totalDoses,
      'takenDoses': takenDoses,
      'takenHistory': takenHistory.map((e) => e.toIso8601String()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  double get adherenceRate => totalDoses > 0 ? (takenDoses / totalDoses) * 100 : 0;

  String get medicineTypeIcon {
    switch (medicineType) {
      case MedicineType.tablet:
        return '💊';
      case MedicineType.capsule:
        return '💊';
      case MedicineType.syrup:
        return '🍯';
      case MedicineType.injection:
        return '💉';
      case MedicineType.drops:
        return '💧';
      case MedicineType.cream:
        return '🧴';
      case MedicineType.inhaler:
        return '🌬️';
      case MedicineType.other:
        return '💊';
    }
  }

  MedicineReminderModel copyWith({
    String? id,
    String? patientId,
    String? medicineName,
    MedicineType? medicineType,
    String? dosage,
    FrequencyType? frequency,
    List<String>? timings,
    MealTiming? mealTiming,
    DateTime? startDate,
    DateTime? endDate,
    String? prescriptionId,
    String? doctorId,
    String? doctorName,
    String? notes,
    bool? isActive,
    int? totalDoses,
    int? takenDoses,
    List<DateTime>? takenHistory,
    DateTime? createdAt,
  }) {
    return MedicineReminderModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      medicineName: medicineName ?? this.medicineName,
      medicineType: medicineType ?? this.medicineType,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      timings: timings ?? this.timings,
      mealTiming: mealTiming ?? this.mealTiming,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      totalDoses: totalDoses ?? this.totalDoses,
      takenDoses: takenDoses ?? this.takenDoses,
      takenHistory: takenHistory ?? this.takenHistory,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
