import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

class FamilyMemberModel {
  final String id;
  final String userId;
  final String name;
  final String relationship; // Spouse, Child, Parent, Sibling, Other
  final String gender; // Male, Female, Other
  final DateTime dateOfBirth;
  final String bloodGroup;
  final String allergies;
  final String chronicConditions;
  final DateTime createdAt;

  FamilyMemberModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.relationship,
    required this.gender,
    required this.dateOfBirth,
    required this.bloodGroup,
    this.allergies = '',
    this.chronicConditions = '',
    required this.createdAt,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json, String docId) {
    return FamilyMemberModel(
      id: docId,
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? 'Other',
      gender: json['gender'] ?? 'Other',
      dateOfBirth: _parseDateTime(json['dateOfBirth']),
      bloodGroup: json['bloodGroup'] ?? 'Unknown',
      allergies: json['allergies'] ?? '',
      chronicConditions: json['chronicConditions'] ?? '',
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'relationship': relationship,
      'gender': gender,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FamilyMemberModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? relationship,
    String? gender,
    DateTime? dateOfBirth,
    String? bloodGroup,
    String? allergies,
    String? chronicConditions,
    DateTime? createdAt,
  }) {
    return FamilyMemberModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
