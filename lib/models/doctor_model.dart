class DoctorModel {
  final String doctorId;
  final String userId;
  final String name;
  final String specialization;
  final List<String> hospitals; // Changed from single hospital to list
  final double consultationFee;
  final double rating;
  final int totalReviews;
  final String profileBio;
  final bool active;
  final String? photoURL;

  // Fixed consultation fee for all doctors
  static const double fixedConsultationFee = 500.0;

  DoctorModel({
    required this.doctorId,
    required this.userId,
    required this.name,
    required this.specialization,
    required this.hospitals,
    this.consultationFee = fixedConsultationFee, // Default to fixed fee
    this.rating = 0.0,
    this.totalReviews = 0,
    required this.profileBio,
    this.active = true,
    this.photoURL,
  });

  // Legacy support - get first hospital or empty string
  String get hospital => hospitals.isNotEmpty ? hospitals.first : '';

  factory DoctorModel.fromJson(Map<String, dynamic> json, String id) {
    // Support both old format (single hospital) and new format (list) and chambers
    List<String> hospitalsList = [];
    if (json['hospitals'] != null && json['hospitals'] is List) {
      hospitalsList = List<String>.from(json['hospitals']);
    } else if (json['hospital'] != null && json['hospital'] is String) {
      hospitalsList = [json['hospital']];
    }

    if (json['chambers'] != null && json['chambers'] is List) {
      for (var c in json['chambers']) {
        if (c is Map && (c['name'] != null || c['chamberName'] != null)) {
          String cName = (c['name'] ?? c['chamberName']).toString();
          if (cName.isNotEmpty && !hospitalsList.contains(cName)) {
            hospitalsList.add(cName);
          }
        }
      }
    }

    final feeVal = json['consultationFee'] ?? json['fee'] ?? fixedConsultationFee;
    final feeDouble = (feeVal is num) ? feeVal.toDouble() : fixedConsultationFee;

    return DoctorModel(
      doctorId: id,
      userId: json['userId'] ?? id,
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
      hospitals: hospitalsList,
      consultationFee: feeDouble,
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      profileBio: json['profileBio'] ?? json['bio'] ?? '',
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
      'totalReviews': totalReviews,
      'profileBio': profileBio,
      'active': active,
      'photoURL': photoURL,
    };
  }
}
