import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseService _firebase = FirebaseService();
  
  FirebaseAuth get _auth => _firebase.auth;
  FirebaseFirestore get _firestore => _firebase.firestore;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Current user
  User? get currentUser => _auth.currentUser;
  
  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String phone = '',
  }) async {
    try {
      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      final user = UserModel(
        userId: credential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        role: role,
        profileCompleted: false,
        createdAt: DateTime.now(),
      );
      
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toJson());
      
      // Update display name
      await credential.user!.updateDisplayName(name);
      
      return credential;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  /// Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Check if profile is complete
  Future<bool> isProfileComplete(String userId) async {
    final user = await getUserData(userId);
    return user?.profileCompleted ?? false;
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
}
