import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionTemplateModel {
  final String id;
  final String doctorId;
  final String templateName;
  final String? condition;
  final List<TemplateMedicine> medicines;
  final String? advice;
  final String? notes;
  final bool isActive;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrescriptionTemplateModel({
    required this.id,
    required this.doctorId,
    required this.templateName,
    this.condition,
    required this.medicines,
    this.advice,
    this.notes,
    required this.isActive,
    required this.usageCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrescriptionTemplateModel.fromJson(Map<String, dynamic> json, String id) {
    return PrescriptionTemplateModel(
      id: id,
      doctorId: json['doctorId'] ?? '',
      templateName: json['templateName'] ?? '',
      condition: json['condition'],
      medicines: (json['medicines'] as List<dynamic>?)
              ?.map((e) => TemplateMedicine.fromJson(e))
              .toList() ??
          [],
      advice: json['advice'],
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
      usageCount: json['usageCount'] ?? 0,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'templateName': templateName,
      'condition': condition,
      'medicines': medicines.map((e) => e.toJson()).toList(),
      'advice': advice,
      'notes': notes,
      'isActive': isActive,
      'usageCount': usageCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PrescriptionTemplateModel copyWith({
    String? id,
    String? doctorId,
    String? templateName,
    String? condition,
    List<TemplateMedicine>? medicines,
    String? advice,
    String? notes,
    bool? isActive,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrescriptionTemplateModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      templateName: templateName ?? this.templateName,
      condition: condition ?? this.condition,
      medicines: medicines ?? this.medicines,
      advice: advice ?? this.advice,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TemplateMedicine {
  final String medicineName;
  final String dosage;
  final String frequency; // e.g., "1-0-1", "Once daily"
  final String duration; // e.g., "7 days", "2 weeks"
  final String? timing; // "Before meal", "After meal"
  final String? instructions;

  TemplateMedicine({
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.timing,
    this.instructions,
  });

  factory TemplateMedicine.fromJson(Map<String, dynamic> json) {
    return TemplateMedicine(
      medicineName: json['medicineName'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      duration: json['duration'] ?? '',
      timing: json['timing'],
      instructions: json['instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicineName': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'timing': timing,
      'instructions': instructions,
    };
  }
}

class QuickResponseTemplateModel {
  final String id;
  final String doctorId;
  final String title;
  final String content;
  final String category; // greeting, diagnosis, advice, followup, other
  final List<String> tags;
  final int usageCount;
  final bool isActive;
  final DateTime createdAt;

  QuickResponseTemplateModel({
    required this.id,
    required this.doctorId,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.usageCount,
    required this.isActive,
    required this.createdAt,
  });

  factory QuickResponseTemplateModel.fromJson(Map<String, dynamic> json, String id) {
    return QuickResponseTemplateModel(
      id: id,
      doctorId: json['doctorId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'other',
      tags: List<String>.from(json['tags'] ?? []),
      usageCount: json['usageCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'usageCount': usageCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get categoryIcon {
    switch (category) {
      case 'greeting':
        return '👋';
      case 'diagnosis':
        return '🔍';
      case 'advice':
        return '💡';
      case 'followup':
        return '📅';
      default:
        return '💬';
    }
  }

  QuickResponseTemplateModel copyWith({
    String? id,
    String? doctorId,
    String? title,
    String? content,
    String? category,
    List<String>? tags,
    int? usageCount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return QuickResponseTemplateModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      usageCount: usageCount ?? this.usageCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Predefined response categories
class ResponseCategories {
  static const List<Map<String, String>> categories = [
    {'value': 'greeting', 'label': 'Greeting'},
    {'value': 'diagnosis', 'label': 'Diagnosis'},
    {'value': 'advice', 'label': 'Medical Advice'},
    {'value': 'followup', 'label': 'Follow-up'},
    {'value': 'prescription', 'label': 'Prescription Info'},
    {'value': 'lab', 'label': 'Lab Test'},
    {'value': 'other', 'label': 'Other'},
  ];
}
