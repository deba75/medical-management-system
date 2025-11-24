class DoctorModel {
  final String doctorId;
  final String userId;
  final String name;
  final String specialization;
  final String hospital;
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
    required this.hospital,
    required this.consultationFee,
    this.rating = 0.0,
    required this.profileBio,
    this.active = true,
    this.photoURL,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json, String id) {
    return DoctorModel(
      doctorId: id,
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
      hospital: json['hospital'] ?? '',
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
      'hospital': hospital,
      'consultationFee': consultationFee,
      'rating': rating,
      'profileBio': profileBio,
      'active': active,
      'photoURL': photoURL,
    };
  }
}
