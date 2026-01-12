class DoctorModel {
  final String doctorId;
  final String userId;
  final String name;
  final String specialization;
  final List<String> hospitals; // Changed from single hospital to list
  final double consultationFee;
  final double rating;
  final String profileBio;
  final bool active;
  final String? photoURL;

  DoctorModel({
    required this.doctorId,
    required this.userId,
    required this.name,
    required this.specialization,
    required this.hospitals,
    required this.consultationFee,
    this.rating = 0.0,
    required this.profileBio,
    this.active = true,
    this.photoURL,
  });

  // Legacy support - get first hospital or empty string
  String get hospital => hospitals.isNotEmpty ? hospitals.first : '';

  factory DoctorModel.fromJson(Map<String, dynamic> json, String id) {
    // Support both old format (single hospital) and new format (list)
    List<String> hospitalsList;
    if (json['hospitals'] != null && json['hospitals'] is List) {
      hospitalsList = List<String>.from(json['hospitals']);
    } else if (json['hospital'] != null && json['hospital'] is String) {
      hospitalsList = [json['hospital']];
    } else {
      hospitalsList = [];
    }

    return DoctorModel(
      doctorId: id,
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
      hospitals: hospitalsList,
      consultationFee: (json['consultationFee'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      profileBio: json['profileBio'] ?? '',
      active: json['active'] ?? true,
      photoURL: json['photoURL'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'specialization': specialization,
      'hospitals': hospitals,
      'hospital': hospital, // Keep for backward compatibility
      'consultationFee': consultationFee,
      'rating': rating,
      'profileBio': profileBio,
      'active': active,
      'photoURL': photoURL,
    };
  }
}
