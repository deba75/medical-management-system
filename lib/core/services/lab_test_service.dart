import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/lab_test_model.dart';

class LabTestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _bookingsCollection = 'lab_test_bookings';
  final String _testsCollection = 'available_lab_tests';

  // Get all available lab tests
  Future<List<AvailableLabTest>> getAvailableTests() async {
    try {
      final snapshot = await _firestore
          .collection(_testsCollection)
          .orderBy('category')
          .get();

      return snapshot.docs
          .map((doc) => AvailableLabTest.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch available lab tests: $e');
    }
  }

  // Get tests by category
  Future<List<AvailableLabTest>> getTestsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(_testsCollection)
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs
          .map((doc) => AvailableLabTest.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tests by category: $e');
    }
  }

  // Search tests
  Future<List<AvailableLabTest>> searchTests(String query) async {
    try {
      final snapshot = await _firestore.collection(_testsCollection).get();

      final tests = snapshot.docs
          .map((doc) => AvailableLabTest.fromJson(doc.data(), doc.id))
          .where((test) =>
              test.name.toLowerCase().contains(query.toLowerCase()) ||
              test.category.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return tests;
    } catch (e) {
      throw Exception('Failed to search tests: $e');
    }
  }

  // Book a lab test
  Future<String> bookLabTest(LabTestModel booking) async {
    try {
      final docRef = await _firestore.collection(_bookingsCollection).add(booking.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to book lab test: $e');
    }
  }

  // Get patient's lab test bookings
  Stream<List<LabTestModel>> getPatientBookings(String patientId) {
    return _firestore
        .collection(_bookingsCollection)
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LabTestModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get booking by ID
  Future<LabTestModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
      if (doc.exists) {
        return LabTestModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch booking: $e');
    }
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, LabTestStatus status) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': status.name,
      });
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Upload report URL
  Future<void> uploadReport(String bookingId, String reportUrl) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'reportUrl': reportUrl,
        'reportGeneratedAt': DateTime.now().toIso8601String(),
        'status': LabTestStatus.completed.name,
      });
    } catch (e) {
      throw Exception('Failed to upload report: $e');
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': LabTestStatus.cancelled.name,
      });
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Get popular tests
  Future<List<AvailableLabTest>> getPopularTests({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_testsCollection)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AvailableLabTest.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch popular tests: $e');
    }
  }

  // Get test categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(_testsCollection).get();
      final categories = snapshot.docs
          .map((doc) => doc.data()['category'] as String)
          .toSet()
          .toList();
      categories.sort();
      return categories;
    } catch (e) {
      return [
        'Blood Test',
        'Urine Test',
        'Imaging',
        'Cardiac',
        'Thyroid',
        'Diabetes',
        'Liver Function',
        'Kidney Function',
        'Vitamin',
        'Allergy',
        'Hormone',
        'Cancer Screening',
      ];
    }
  }

  // Seed sample lab tests (for initial setup)
  Future<void> seedSampleTests() async {
    final sampleTests = [
      {
        'name': 'Complete Blood Count (CBC)',
        'category': 'Blood Test',
        'price': 350,
        'description': 'Measures red blood cells, white blood cells, hemoglobin, and platelets',
        'parameters': ['RBC', 'WBC', 'Hemoglobin', 'Hematocrit', 'Platelets'],
        'preparationHours': 0,
        'reportTime': '24 hours',
      },
      {
        'name': 'Lipid Profile',
        'category': 'Blood Test',
        'price': 600,
        'description': 'Measures cholesterol levels including HDL, LDL, and triglycerides',
        'parameters': ['Total Cholesterol', 'HDL', 'LDL', 'Triglycerides', 'VLDL'],
        'preparationHours': 12,
        'reportTime': '24 hours',
      },
      {
        'name': 'Thyroid Profile (T3, T4, TSH)',
        'category': 'Thyroid',
        'price': 750,
        'description': 'Complete thyroid function assessment',
        'parameters': ['T3', 'T4', 'TSH'],
        'preparationHours': 0,
        'reportTime': '24 hours',
      },
      {
        'name': 'HbA1c (Glycated Hemoglobin)',
        'category': 'Diabetes',
        'price': 450,
        'description': 'Average blood sugar level over 2-3 months',
        'parameters': ['HbA1c Percentage', 'Estimated Average Glucose'],
        'preparationHours': 0,
        'reportTime': '24 hours',
      },
      {
        'name': 'Liver Function Test (LFT)',
        'category': 'Liver Function',
        'price': 550,
        'description': 'Comprehensive liver health assessment',
        'parameters': ['Bilirubin', 'SGOT', 'SGPT', 'Alkaline Phosphatase', 'Albumin'],
        'preparationHours': 10,
        'reportTime': '24 hours',
      },
      {
        'name': 'Kidney Function Test (KFT)',
        'category': 'Kidney Function',
        'price': 500,
        'description': 'Complete kidney health assessment',
        'parameters': ['Creatinine', 'BUN', 'Uric Acid', 'Electrolytes'],
        'preparationHours': 8,
        'reportTime': '24 hours',
      },
      {
        'name': 'Vitamin D (25-OH)',
        'category': 'Vitamin',
        'price': 800,
        'description': 'Measures vitamin D levels in blood',
        'parameters': ['25-Hydroxy Vitamin D'],
        'preparationHours': 0,
        'reportTime': '48 hours',
      },
      {
        'name': 'Vitamin B12',
        'category': 'Vitamin',
        'price': 650,
        'description': 'Measures vitamin B12 levels',
        'parameters': ['Vitamin B12'],
        'preparationHours': 8,
        'reportTime': '24 hours',
      },
      {
        'name': 'Chest X-Ray',
        'category': 'Imaging',
        'price': 400,
        'description': 'X-ray imaging of chest area',
        'parameters': ['Chest X-Ray PA View'],
        'preparationHours': 0,
        'reportTime': '4 hours',
      },
      {
        'name': 'ECG (Electrocardiogram)',
        'category': 'Cardiac',
        'price': 300,
        'description': 'Records electrical activity of the heart',
        'parameters': ['12-Lead ECG'],
        'preparationHours': 0,
        'reportTime': '1 hour',
      },
    ];

    for (var test in sampleTests) {
      await _firestore.collection(_testsCollection).add(test);
    }
  }
}
