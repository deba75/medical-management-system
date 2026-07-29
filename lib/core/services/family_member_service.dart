import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/family_member_model.dart';
import 'firebase_service.dart';

class FamilyMemberService {
  final FirebaseService _firebase = FirebaseService();

  FirebaseFirestore get _firestore => _firebase.firestore;

  /// Stream list of family members for a patient user
  Stream<List<FamilyMemberModel>> getFamilyMembers(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('family_members')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyMemberModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Fetch family members as a future list
  Future<List<FamilyMemberModel>> fetchFamilyMembers(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('family_members')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => FamilyMemberModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a new family member profile
  Future<String> addFamilyMember(FamilyMemberModel member) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(member.userId)
          .collection('family_members')
          .add(member.toJson());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing family member profile
  Future<void> updateFamilyMember(FamilyMemberModel member) async {
    try {
      await _firestore
          .collection('users')
          .doc(member.userId)
          .collection('family_members')
          .doc(member.id)
          .update(member.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a family member profile
  Future<void> deleteFamilyMember(String userId, String memberId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('family_members')
          .doc(memberId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
