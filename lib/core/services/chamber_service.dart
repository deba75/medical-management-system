import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/chamber_model.dart';
import 'firebase_service.dart';

class ChamberService {
  final FirebaseService _firebase = FirebaseService();
  
  FirebaseFirestore get _firestore => _firebase.firestore;
  
  /// Get all chambers for a doctor
  Stream<List<Chamber>> getChambers(String doctorId) {
    return _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('chambers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Chamber.fromJson(doc.data(), doc.id))
            .toList());
  }
  
  /// Add a new chamber
  Future<String> addChamber(String doctorId, Chamber chamber) async {
    try {
      final docRef = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('chambers')
          .add(chamber.toJson());
      
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update chamber
  Future<void> updateChamber(String doctorId, Chamber chamber) async {
    try {
      await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('chambers')
          .doc(chamber.id)
          .update(chamber.toJson());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Delete chamber
  Future<void> deleteChamber(String doctorId, String chamberId) async {
    try {
      await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('chambers')
          .doc(chamberId)
          .update({'isActive': false});
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get availability for a specific date
  Stream<DoctorAvailability?> getAvailability({
    required String doctorId,
    required String chamberId,
    required DateTime date,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _firestore
        .collection('doctor_availability')
        .where('doctorId', isEqualTo: doctorId)
        .where('chamberId', isEqualTo: chamberId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return DoctorAvailability.fromJson(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    });
  }
  
  /// Set availability for a date
  Future<void> setAvailability(DoctorAvailability availability) async {
    try {
      await _firestore
          .collection('doctor_availability')
          .add(availability.toJson());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Mark leave
  Future<void> markLeave({
    required String doctorId,
    required DateTime date,
    String? reason,
    String? chamberId,
  }) async {
    try {
      final availability = DoctorAvailability(
        id: '',
        doctorId: doctorId,
        chamberId: chamberId ?? 'all',
        date: date,
        slots: [],
        isLeave: true,
        leaveReason: reason,
      );
      
      await _firestore
          .collection('doctor_availability')
          .add(availability.toJson());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get monthly availability (for calendar)
  Stream<List<DoctorAvailability>> getMonthlyAvailability({
    required String doctorId,
    required DateTime month,
  }) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    return _firestore
        .collection('doctor_availability')
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DoctorAvailability.fromJson(doc.data(), doc.id))
            .toList());
  }
}
