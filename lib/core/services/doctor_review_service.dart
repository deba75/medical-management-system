import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/doctor_review_model.dart';

class DoctorReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'doctor_reviews';

  // Submit a review
  Future<String> submitReview(DoctorReviewModel review) async {
    try {
      final docRef = await _firestore.collection(_collection).add(review.toJson());
      
      // Update doctor's rating summary
      await _updateDoctorRating(review.doctorId);
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  // Get reviews for a doctor
  Stream<List<DoctorReviewModel>> getDoctorReviews(String doctorId) {
    return _firestore
        .collection(_collection)
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DoctorReviewModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get review by appointment ID (to check if already reviewed)
  Future<DoctorReviewModel?> getReviewByAppointment(String appointmentId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return DoctorReviewModel.fromJson(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch review: $e');
    }
  }

  // Get doctor's rating summary
  Future<DoctorRatingSummary> getDoctorRatingSummary(String doctorId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('doctorId', isEqualTo: doctorId)
          .get();

      if (snapshot.docs.isEmpty) {
        return DoctorRatingSummary(
          doctorId: doctorId,
          averageRating: 0,
          totalReviews: 0,
          ratingDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
          topTags: [],
        );
      }

      double totalRating = 0;
      Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      Map<String, int> tagCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final rating = (data['rating'] as num).toDouble();
        totalRating += rating;
        
        final ratingInt = rating.round();
        distribution[ratingInt] = (distribution[ratingInt] ?? 0) + 1;

        final tags = List<String>.from(data['tags'] ?? []);
        for (var tag in tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      // Sort tags by count and get top 5
      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topTags = sortedTags.take(5).map((e) => e.key).toList();

      return DoctorRatingSummary(
        doctorId: doctorId,
        averageRating: totalRating / snapshot.docs.length,
        totalReviews: snapshot.docs.length,
        ratingDistribution: distribution,
        topTags: topTags,
      );
    } catch (e) {
      throw Exception('Failed to get rating summary: $e');
    }
  }

  // Update doctor's overall rating in doctors collection
  Future<void> _updateDoctorRating(String doctorId) async {
    try {
      final summary = await getDoctorRatingSummary(doctorId);
      
      await _firestore.collection('doctors').doc(doctorId).update({
        'rating': summary.averageRating,
        'totalReviews': summary.totalReviews,
      });
    } catch (e) {
      // Silently fail - doctor collection might not exist
    }
  }

  // Add doctor's reply to review
  Future<void> addDoctorReply(String reviewId, String reply) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).update({
        'doctorReply': reply,
        'doctorReplyAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add reply: $e');
    }
  }

  // Mark review as helpful
  Future<void> toggleHelpful(String reviewId, String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(reviewId).get();
      if (doc.exists) {
        final helpfulBy = List<String>.from(doc.data()?['helpfulBy'] ?? []);
        
        if (helpfulBy.contains(userId)) {
          helpfulBy.remove(userId);
          await _firestore.collection(_collection).doc(reviewId).update({
            'helpfulBy': helpfulBy,
            'helpfulCount': FieldValue.increment(-1),
          });
        } else {
          helpfulBy.add(userId);
          await _firestore.collection(_collection).doc(reviewId).update({
            'helpfulBy': helpfulBy,
            'helpfulCount': FieldValue.increment(1),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to toggle helpful: $e');
    }
  }

  // Update review
  Future<void> updateReview(String reviewId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection(_collection).doc(reviewId).update(updates);
      
      // Get doctorId to update rating
      final doc = await _firestore.collection(_collection).doc(reviewId).get();
      if (doc.exists) {
        await _updateDoctorRating(doc.data()?['doctorId']);
      }
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete review
  Future<void> deleteReview(String reviewId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(reviewId).get();
      final doctorId = doc.data()?['doctorId'];
      
      await _firestore.collection(_collection).doc(reviewId).delete();
      
      if (doctorId != null) {
        await _updateDoctorRating(doctorId);
      }
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Get reviews by patient
  Stream<List<DoctorReviewModel>> getPatientReviews(String patientId) {
    return _firestore
        .collection(_collection)
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DoctorReviewModel.fromJson(doc.data(), doc.id))
            .toList());
  }
}
