class Hospital {
  final String id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final String email;
  final String imageUrl;
  final double rating;
  final int totalReviews;
  final List<String> specialties;
  final bool isEmergencyAvailable;
  final String description;
  final Map<String, String> workingHours; // day -> hours
  final double? latitude;
  final double? longitude;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.email,
    required this.imageUrl,
    required this.rating,
    required this.totalReviews,
    required this.specialties,
    this.isEmergencyAvailable = false,
    this.description = '',
    this.workingHours = const {},
    this.latitude,
    this.longitude,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      specialties: List<String>.from(json['specialties'] ?? []),
      isEmergencyAvailable: json['isEmergencyAvailable'] ?? false,
      description: json['description'] ?? '',
      workingHours: Map<String, String>.from(json['workingHours'] ?? {}),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'phone': phone,
      'email': email,
      'imageUrl': imageUrl,
      'rating': rating,
      'totalReviews': totalReviews,
      'specialties': specialties,
      'isEmergencyAvailable': isEmergencyAvailable,
      'description': description,
      'workingHours': workingHours,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
