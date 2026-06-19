import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper function to convert Firestore Timestamp or String to DateTime
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

/// Helper function to convert nullable Firestore Timestamp or String to DateTime?
DateTime? _parseDateTimeNullable(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return null;
}

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? photoURL;
  final bool profileCompleted;
  final DateTime createdAt;
  final DateTime? dateOfBirth;
  final String? patientId;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoURL,
    this.profileCompleted = false,
    required this.createdAt,
    this.dateOfBirth,
    this.patientId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.patient,
      ),
      photoURL: json['photoURL'],
      profileCompleted: json['profileCompleted'] ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      dateOfBirth: _parseDateTimeNullable(json['dateOfBirth']),
      patientId: json['patientId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'photoURL': photoURL,
      'profileCompleted': profileCompleted,
      'createdAt': createdAt.toIso8601String(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'patientId': patientId,
    };
  }
}

enum UserRole {
  patient,
  doctor,
  admin,
}
