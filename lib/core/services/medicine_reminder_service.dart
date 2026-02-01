import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medicine_reminder_model.dart';

class MedicineReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'medicine_reminders';

  // Create a new medicine reminder
  Future<String> createReminder(MedicineReminderModel reminder) async {
    try {
      final docRef = await _firestore.collection(_collection).add(reminder.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create medicine reminder: $e');
    }
  }

  // Get all reminders for a patient
  Stream<List<MedicineReminderModel>> getRemindersForPatient(String patientId) {
    return _firestore
        .collection(_collection)
        .where('patientId', isEqualTo: patientId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicineReminderModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get active reminders for today
  Stream<List<MedicineReminderModel>> getTodayReminders(String patientId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _firestore
        .collection(_collection)
        .where('patientId', isEqualTo: patientId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicineReminderModel.fromJson(doc.data(), doc.id))
            .where((reminder) {
              final startDate = DateTime(
                reminder.startDate.year,
                reminder.startDate.month,
                reminder.startDate.day,
              );
              final endDate = reminder.endDate != null
                  ? DateTime(
                      reminder.endDate!.year,
                      reminder.endDate!.month,
                      reminder.endDate!.day,
                    )
                  : null;
              
              return !startDate.isAfter(today) && 
                     (endDate == null || !today.isAfter(endDate));
            })
            .toList());
  }

  // Mark medicine as taken
  Future<void> markAsTaken(String reminderId, DateTime takenAt) async {
    try {
      final doc = await _firestore.collection(_collection).doc(reminderId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final takenHistory = List<String>.from(data['takenHistory'] ?? []);
        takenHistory.add(takenAt.toIso8601String());
        
        await _firestore.collection(_collection).doc(reminderId).update({
          'takenDoses': FieldValue.increment(1),
          'takenHistory': takenHistory,
        });
      }
    } catch (e) {
      throw Exception('Failed to mark medicine as taken: $e');
    }
  }

  // Update reminder
  Future<void> updateReminder(String reminderId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(reminderId).update(updates);
    } catch (e) {
      throw Exception('Failed to update medicine reminder: $e');
    }
  }

  // Delete/deactivate reminder
  Future<void> deactivateReminder(String reminderId) async {
    try {
      await _firestore.collection(_collection).doc(reminderId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to deactivate medicine reminder: $e');
    }
  }

  // Get adherence statistics
  Future<Map<String, dynamic>> getAdherenceStats(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('patientId', isEqualTo: patientId)
          .get();

      int totalDoses = 0;
      int takenDoses = 0;
      int activeReminders = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalDoses += (data['totalDoses'] as int?) ?? 0;
        takenDoses += (data['takenDoses'] as int?) ?? 0;
        if (data['isActive'] == true) activeReminders++;
      }

      return {
        'totalDoses': totalDoses,
        'takenDoses': takenDoses,
        'adherenceRate': totalDoses > 0 ? (takenDoses / totalDoses) * 100 : 0,
        'activeReminders': activeReminders,
        'totalReminders': snapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get adherence stats: $e');
    }
  }

  // Get reminders by prescription
  Future<List<MedicineReminderModel>> getRemindersByPrescription(String prescriptionId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('prescriptionId', isEqualTo: prescriptionId)
          .get();

      return snapshot.docs
          .map((doc) => MedicineReminderModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reminders by prescription: $e');
    }
  }
}
