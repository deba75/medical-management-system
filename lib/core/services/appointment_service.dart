import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/appointment_model.dart';
import 'firebase_service.dart';

class AppointmentService {
  final FirebaseService _firebase = FirebaseService();
  
  FirebaseFirestore get _firestore => _firebase.firestore;
  
  /// Create a new appointment
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      final docRef = await _firestore
          .collection('appointments')
          .add(appointment.toJson());
      
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get appointments for a user (patient or doctor)
  Stream<List<AppointmentModel>> getAppointments({
    required String userId,
    required bool isDoctor,
  }) {
    try {
      final field = isDoctor ? 'doctorId' : 'patientId';
      
      return _firestore
          .collection('appointments')
          .where(field, isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AppointmentModel.fromJson(
                    doc.data(),
                    doc.id,
                  ))
              .toList());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get today's appointments for a doctor
  Stream<List<AppointmentModel>> getTodayAppointments(String doctorId) {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      return _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .orderBy('date')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AppointmentModel.fromJson(
                    doc.data(),
                    doc.id,
                  ))
              .toList());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update appointment status
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required AppointmentStatus status,
  }) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
  
  /// Cancel appointment
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': AppointmentStatus.cancelled.toString().split('.').last,
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get appointment by ID
  Future<AppointmentModel?> getAppointmentById(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      
      if (doc.exists) {
        return AppointmentModel.fromJson(
          doc.data()!,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
