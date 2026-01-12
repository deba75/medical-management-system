class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? photoURL;
  final bool profileCompleted;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoURL,
    this.profileCompleted = false,
    required this.createdAt,
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
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
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
    };
  }
}

enum UserRole {
  patient,
  doctor,
  admin,
}
