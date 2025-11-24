import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/chamber_model.dart';
import 'firebase_service.dart';

class EarningsService {
  final FirebaseService _firebase = FirebaseService();
  
  FirebaseFirestore get _firestore => _firebase.firestore;
  
  /// Get daily earnings
  Future<DoctorEarnings?> getDailyEarnings({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('doctor_earnings')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      if (snapshot.docs.isEmpty) {
        return DoctorEarnings(
          id: '',
          doctorId: doctorId,
          date: date,
          onlineEarnings: 0,
          offlineEarnings: 0,
          onlineConsultations: 0,
          offlineConsultations: 0,
        );
      }
      
      return DoctorEarnings.fromJson(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get monthly earnings
  Future<List<DoctorEarnings>> getMonthlyEarnings({
    required String doctorId,
    required DateTime month,
  }) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('doctor_earnings')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('date')
          .get();
      
      return snapshot.docs
          .map((doc) => DoctorEarnings.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Record earning from appointment
  Future<void> recordEarning({
    required String doctorId,
    required DateTime date,
    required double amount,
    required bool isOnline,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      // Check if earnings record exists for this day
      final snapshot = await _firestore
          .collection('doctor_earnings')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      if (snapshot.docs.isEmpty) {
        // Create new record
        await _firestore.collection('doctor_earnings').add({
          'doctorId': doctorId,
          'date': Timestamp.fromDate(startOfDay),
          'onlineEarnings': isOnline ? amount : 0,
          'offlineEarnings': isOnline ? 0 : amount,
          'onlineConsultations': isOnline ? 1 : 0,
          'offlineConsultations': isOnline ? 0 : 1,
        });
      } else {
        // Update existing record
        final doc = snapshot.docs.first;
        final data = doc.data();
        
        await doc.reference.update({
          'onlineEarnings': (data['onlineEarnings'] ?? 0) + (isOnline ? amount : 0),
          'offlineEarnings': (data['offlineEarnings'] ?? 0) + (isOnline ? 0 : amount),
          'onlineConsultations': (data['onlineConsultations'] ?? 0) + (isOnline ? 1 : 0),
          'offlineConsultations': (data['offlineConsultations'] ?? 0) + (isOnline ? 0 : 1),
        });
      }
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get doctor statistics
  Future<DoctorStats> getDoctorStats(String doctorId) async {
    try {
      // Get total patients (completed appointments)
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'completed')
          .get();
      
      final totalPatients = appointmentsSnapshot.docs.length;
      
      // Get today's patients
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final todaySnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', isEqualTo: 'completed')
          .get();
      
      final todayPatients = todaySnapshot.docs.length;
      
      // Get upcoming appointments
      final upcomingSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'upcoming')
          .get();
      
      final upcomingAppointments = upcomingSnapshot.docs.length;
      
      // Calculate average consultation time (mock for now)
      final avgConsultationTime = 25.0; // minutes
      
      // Get satisfaction score (mock for now)
      final satisfactionScore = 4.5; // out of 5
      
      return DoctorStats(
        totalPatients: totalPatients,
        avgConsultationTime: avgConsultationTime,
        satisfactionScore: satisfactionScore,
        todayPatients: todayPatients,
        upcomingAppointments: upcomingAppointments,
      );
    } catch (e) {
      rethrow;
    }
  }
}
