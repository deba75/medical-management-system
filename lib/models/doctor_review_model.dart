import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorReviewModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String? patientImage;
  final String appointmentId;
  final double rating;
  final String? reviewText;
  final List<String> tags; // e.g., ["Professional", "Friendly", "Knowledgeable"]
  final bool isAnonymous;
  final bool isVerified; // Verified appointment
  final String? doctorReply;
  final DateTime? doctorReplyAt;
  final int helpfulCount;
  final List<String> helpfulBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DoctorReviewModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    this.patientImage,
    required this.appointmentId,
    required this.rating,
    this.reviewText,
    required this.tags,
    required this.isAnonymous,
    required this.isVerified,
    this.doctorReply,
    this.doctorReplyAt,
    required this.helpfulCount,
    required this.helpfulBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DoctorReviewModel.fromJson(Map<String, dynamic> json, String id) {
    return DoctorReviewModel(
      id: id,
      doctorId: json['doctorId'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      patientImage: json['patientImage'],
      appointmentId: json['appointmentId'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewText: json['reviewText'],
      tags: List<String>.from(json['tags'] ?? []),
      isAnonymous: json['isAnonymous'] ?? false,
      isVerified: json['isVerified'] ?? false,
      doctorReply: json['doctorReply'],
      doctorReplyAt: json['doctorReplyAt'] != null
          ? (json['doctorReplyAt'] is Timestamp
              ? (json['doctorReplyAt'] as Timestamp).toDate()
              : DateTime.parse(json['doctorReplyAt']))
          : null,
      helpfulCount: json['helpfulCount'] ?? 0,
      helpfulBy: List<String>.from(json['helpfulBy'] ?? []),
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
      'patientId': patientId,
      'patientName': patientName,
      'patientImage': patientImage,
      'appointmentId': appointmentId,
      'rating': rating,
      'reviewText': reviewText,
      'tags': tags,
      'isAnonymous': isAnonymous,
      'isVerified': isVerified,
      'doctorReply': doctorReply,
      'doctorReplyAt': doctorReplyAt?.toIso8601String(),
      'helpfulCount': helpfulCount,
      'helpfulBy': helpfulBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get displayName => isAnonymous ? 'Anonymous User' : patientName;

  String get ratingStars {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    
    return '⭐' * fullStars + (hasHalfStar ? '✨' : '') + '☆' * emptyStars;
  }

  DoctorReviewModel copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    String? patientName,
    String? patientImage,
    String? appointmentId,
    double? rating,
    String? reviewText,
    List<String>? tags,
    bool? isAnonymous,
    bool? isVerified,
    String? doctorReply,
    DateTime? doctorReplyAt,
    int? helpfulCount,
    List<String>? helpfulBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoctorReviewModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientImage: patientImage ?? this.patientImage,
      appointmentId: appointmentId ?? this.appointmentId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      tags: tags ?? this.tags,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isVerified: isVerified ?? this.isVerified,
      doctorReply: doctorReply ?? this.doctorReply,
      doctorReplyAt: doctorReplyAt ?? this.doctorReplyAt,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      helpfulBy: helpfulBy ?? this.helpfulBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DoctorRatingSummary {
  final String doctorId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // {5: 100, 4: 50, 3: 20, 2: 5, 1: 2}
  final List<String> topTags;

  DoctorRatingSummary({
    required this.doctorId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.topTags,
  });

  factory DoctorRatingSummary.fromJson(Map<String, dynamic> json) {
    return DoctorRatingSummary(
      doctorId: json['doctorId'] ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ratingDistribution: Map<int, int>.from(json['ratingDistribution'] ?? {}),
      topTags: List<String>.from(json['topTags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
      'topTags': topTags,
    };
  }

  double getPercentage(int stars) {
    if (totalReviews == 0) return 0;
    return ((ratingDistribution[stars] ?? 0) / totalReviews) * 100;
  }

  // Convenience getters for individual star counts
  int get fiveStarCount => ratingDistribution[5] ?? 0;
  int get fourStarCount => ratingDistribution[4] ?? 0;
  int get threeStarCount => ratingDistribution[3] ?? 0;
  int get twoStarCount => ratingDistribution[2] ?? 0;
  int get oneStarCount => ratingDistribution[1] ?? 0;
  
  // Additional convenience getters
  double get recommendationPercentage {
    if (totalReviews == 0) return 0;
    int positiveReviews = (ratingDistribution[5] ?? 0) + (ratingDistribution[4] ?? 0);
    return (positiveReviews / totalReviews) * 100;
  }
  
  int get verifiedReviewsCount => totalReviews; // Assume all are verified for now
}

// Predefined tags for reviews
class ReviewTags {
  static const List<String> positive = [
    'Professional',
    'Friendly',
    'Knowledgeable',
    'Patient',
    'Caring',
    'Thorough',
    'Good Listener',
    'Clear Explanation',
    'On Time',
    'Helpful Staff',
  ];

  static const List<String> negative = [
    'Long Wait',
    'Rushed',
    'Poor Communication',
    'Unprofessional',
    'Late',
  ];

  static const List<String> all = [...positive, ...negative];
  
  // Alias for all
  static List<String> get allTags => all;
}
