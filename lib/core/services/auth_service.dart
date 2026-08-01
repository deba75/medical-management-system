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
    DateTime? dateOfBirth,
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
        dateOfBirth: dateOfBirth,
        requiresEmailVerification: true,
      );
      
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toJson());
      
      // Update display name
      await credential.user!.updateDisplayName(name);
      
      // Send email verification link
      try {
        await credential.user!.sendEmailVerification();
      } catch (e) {
        // Allow signup to succeed even if email verification send fails (e.g., rate limits or mock environment)
      }
      
      return credential;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Sign in with email and password, tracking failed attempts and banning after 3 consecutive failures
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    
    // Check if user is already banned/restricted in Firestore
    QuerySnapshot userSnap;
    try {
      userSnap = await _firestore
          .collection('users')
          .where('email', '==', cleanEmail)
          .limit(1)
          .get();
    } catch (_) {
      userSnap = await _firestore
          .collection('users')
          .limit(0)
          .get();
    }

    DocumentSnapshot? userDoc = userSnap.docs.isNotEmpty ? userSnap.docs.first : null;
    
    if (userDoc != null && userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final isRestricted = data['isRestricted'] == true;
      final isBanned = data['isBanned'] == true;
      final status = data['status']?.toString().toLowerCase();
      
      if (isRestricted || isBanned || status == 'banned') {
        throw FirebaseAuthException(
          code: 'user-disabled',
          message: 'This account has been banned due to 3 consecutive failed login attempts. Please contact admin.',
        );
      }
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      
      // On successful sign in, reset failedLoginAttempts to 0
      if (userDoc != null && userDoc.exists) {
        await _firestore.collection('users').doc(userDoc.id).update({
          'failedLoginAttempts': 0,
        });
        
        final role = (userDoc.data() as Map<String, dynamic>)['role'];
        if (role == 'doctor') {
          final docRef = _firestore.collection('doctors').doc(userDoc.id);
          final dDoc = await docRef.get();
          if (dDoc.exists) {
            await docRef.update({'failedLoginAttempts': 0});
          }
        }
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        if (userDoc != null && userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final currentAttempts = (data['failedLoginAttempts'] as num?)?.toInt() ?? 0;
          final newAttempts = currentAttempts + 1;
          final userId = userDoc.id;
          final role = data['role']?.toString();
          
          if (newAttempts >= 3) {
            // Ban the user in users collection
            await _firestore.collection('users').doc(userId).update({
              'failedLoginAttempts': newAttempts,
              'isRestricted': true,
              'isBanned': true,
              'status': 'banned',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            // Sync to doctors or diagnostic_centres collection if applicable
            if (role == 'doctor') {
              final docRef = _firestore.collection('doctors').doc(userId);
              final dDoc = await docRef.get();
              if (dDoc.exists) {
                await docRef.update({
                  'failedLoginAttempts': newAttempts,
                  'isRestricted': true,
                  'isBanned': true,
                  'status': 'banned',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              }
            } else if (role == 'diagnostic_centre' || role == 'diagnostic') {
              final diagRef = _firestore.collection('diagnostic_centres').doc(userId);
              final dDoc = await diagRef.get();
              if (dDoc.exists) {
                await diagRef.update({
                  'failedLoginAttempts': newAttempts,
                  'isRestricted': true,
                  'isBanned': true,
                  'status': 'banned',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              }
            }
            
            throw FirebaseAuthException(
              code: 'user-disabled',
              message: 'This account has been banned due to 3 consecutive failed login attempts. Please contact admin.',
            );
          } else {
            await _firestore.collection('users').doc(userId).update({
              'failedLoginAttempts': newAttempts,
            });
            
            throw FirebaseAuthException(
              code: 'wrong-password',
              message: 'Incorrect password. Attempt $newAttempts of 3 before account is banned.',
            );
          }
        }
      }
      rethrow;
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
