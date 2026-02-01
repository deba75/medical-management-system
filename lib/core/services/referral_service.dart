import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/referral_model.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'referrals';

  // Create a referral
  Future<String> createReferral(ReferralModel referral) async {
    try {
      final docRef = await _firestore.collection(_collection).add(referral.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create referral: $e');
    }
  }

  // Get referrals sent by a doctor
  Stream<List<ReferralModel>> getSentReferrals(String doctorId) {
    return _firestore
        .collection(_collection)
        .where('referringDoctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReferralModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get referrals received by a doctor
  Stream<List<ReferralModel>> getReceivedReferrals(String doctorId) {
    return _firestore
        .collection(_collection)
        .where('referredDoctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReferralModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get pending referrals for a doctor
  Stream<List<ReferralModel>> getPendingReferrals(String doctorId) {
    return _firestore
        .collection(_collection)
        .where('referredDoctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReferralModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get completed referrals for a doctor (either sent or received)
  Stream<List<ReferralModel>> getCompletedReferrals(String doctorId) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReferralModel.fromJson(doc.data(), doc.id))
            .where((r) => r.referringDoctorId == doctorId || r.referredDoctorId == doctorId)
            .toList());
  }

  // Accept a referral
  Future<void> acceptReferral(String referralId) async {
    try {
      await _firestore.collection(_collection).doc(referralId).update({
        'status': 'accepted',
        'acceptedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to accept referral: $e');
    }
  }

  // Complete a referral
  Future<void> completeReferral(String referralId, String? feedback) async {
    try {
      await _firestore.collection(_collection).doc(referralId).update({
        'status': 'completed',
        'completedAt': DateTime.now().toIso8601String(),
        'feedback': feedback,
      });
    } catch (e) {
      throw Exception('Failed to complete referral: $e');
    }
  }

  // Cancel a referral
  Future<void> cancelReferral(String referralId) async {
    try {
      await _firestore.collection(_collection).doc(referralId).update({
        'status': 'cancelled',
      });
    } catch (e) {
      throw Exception('Failed to cancel referral: $e');
    }
  }

  // Decline a referral (alias for cancel)
  Future<void> declineReferral(String referralId) async {
    try {
      await _firestore.collection(_collection).doc(referralId).update({
        'status': 'declined',
      });
    } catch (e) {
      throw Exception('Failed to decline referral: $e');
    }
  }

  // Get referral by ID
  Future<ReferralModel?> getReferralById(String referralId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(referralId).get();
      if (doc.exists) {
        return ReferralModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch referral: $e');
    }
  }

  // Get referrals for a patient
  Stream<List<ReferralModel>> getPatientReferrals(String patientId) {
    return _firestore
        .collection(_collection)
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReferralModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get referral statistics for a doctor
  Future<Map<String, int>> getReferralStats(String doctorId) async {
    try {
      final sentSnapshot = await _firestore
          .collection(_collection)
          .where('referringDoctorId', isEqualTo: doctorId)
          .get();

      final receivedSnapshot = await _firestore
          .collection(_collection)
          .where('referredDoctorId', isEqualTo: doctorId)
          .get();

      int sentPending = 0, sentAccepted = 0, sentCompleted = 0;
      int receivedPending = 0, receivedAccepted = 0, receivedCompleted = 0;

      for (var doc in sentSnapshot.docs) {
        switch (doc.data()['status']) {
          case 'pending':
            sentPending++;
            break;
          case 'accepted':
            sentAccepted++;
            break;
          case 'completed':
            sentCompleted++;
            break;
        }
      }

      for (var doc in receivedSnapshot.docs) {
        switch (doc.data()['status']) {
          case 'pending':
            receivedPending++;
            break;
          case 'accepted':
            receivedAccepted++;
            break;
          case 'completed':
            receivedCompleted++;
            break;
        }
      }

      return {
        'totalSent': sentSnapshot.docs.length,
        'sentPending': sentPending,
        'sentAccepted': sentAccepted,
        'sentCompleted': sentCompleted,
        'totalReceived': receivedSnapshot.docs.length,
        'receivedPending': receivedPending,
        'receivedAccepted': receivedAccepted,
        'receivedCompleted': receivedCompleted,
      };
    } catch (e) {
      throw Exception('Failed to get referral stats: $e');
    }
  }

  // Update referral
  Future<void> updateReferral(String referralId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(referralId).update(updates);
    } catch (e) {
      throw Exception('Failed to update referral: $e');
    }
  }
}
