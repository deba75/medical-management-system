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
    Query query = _firestore.collection(_bookingsCollection);
    if (patientId.isNotEmpty) {
      query = query.where('patientId', isEqualTo: patientId);
    }

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs
            .map((doc) => LabTestModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } else {
        // Return realistic demo bookings demonstrating the full 5-stage workflow
        return [
          LabTestModel(
            id: 'DEMO-101',
            patientId: patientId.isEmpty ? 'guest' : patientId,
            patientName: 'Patient User',
            familyMemberId: 'fam_1',
            familyMemberName: 'Sultana Begum',
            familyMemberRelationship: 'Mother',
            diagnosticCentreId: '1',
            diagnosticCentreName: 'Popular Diagnostic Centre',
            tests: [
              TestItem(
                testId: '1',
                testName: 'Complete Blood Count (CBC)',
                category: 'Blood Test',
                price: 450,
              ),
              TestItem(
                testId: '3',
                testName: 'Lipid Profile',
                category: 'Blood Test',
                price: 1200,
              ),
            ],
            status: LabTestStatus.collectorAssigned,
            collectionType: SampleCollectionType.homeSample,
            paymentMethod: LabPaymentMethod.manual,
            paymentStatus: LabPaymentStatus.pending,
            scheduledDate: DateTime.now().add(const Duration(days: 1)),
            timeSlot: '09:00 AM - 12:00 PM',
            address: 'House 24, Road 5, Dhanmondi, Dhaka',
            totalAmount: 1650,
            homeCollectionFee: 150,
            phlebotomistName: 'Mr. Tareq Hasan (Sr. Phlebotomist)',
            phlebotomistPhone: '+880 1711-223344',
            phlebotomistEquipment: 'Sterile Biohazard Transport Box & Digital Thermometer',
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          LabTestModel(
            id: 'DEMO-102',
            patientId: patientId.isEmpty ? 'guest' : patientId,
            patientName: 'Patient User',
            diagnosticCentreId: '2',
            diagnosticCentreName: 'Ibn Sina Diagnostic',
            tests: [
              TestItem(
                testId: '12',
                testName: 'Thyroid Profile (T3, T4, TSH)',
                category: 'Blood Test',
                price: 1800,
              ),
            ],
            status: LabTestStatus.completed,
            collectionType: SampleCollectionType.centerWalkIn,
            paymentMethod: LabPaymentMethod.online,
            paymentStatus: LabPaymentStatus.paid,
            scheduledDate: DateTime.now().subtract(const Duration(days: 2)),
            timeSlot: '10:00 AM - 01:00 PM',
            address: 'House 48, Road 9/A, Dhanmondi',
            totalAmount: 1800,
            homeCollectionFee: 0,
            reportUrl: 'https://mediconnect.health/reports/demo_thyroid_report.pdf',
            reportGeneratedAt: DateTime.now().subtract(const Duration(days: 1)),
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ];
      }
    });
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

  // Stream all lab test bookings for Diagnostic Centre Admin portal
  Stream<List<LabTestModel>> getAllBookingsStream() {
    return _firestore.collection(_bookingsCollection).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => LabTestModel.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Diagnostic Centre approves patient booking request
  Future<void> approveBooking(String bookingId) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': LabTestStatus.approved.name,
      });
    } catch (e) {
      throw Exception('Failed to approve booking: $e');
    }
  }

  // Diagnostic Centre assigns sample collector (Phlebotomist)
  Future<void> assignPhlebotomist(
    String bookingId, {
    required String name,
    required String phone,
    required String equipment,
  }) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': LabTestStatus.collectorAssigned.name,
        'phlebotomistName': name,
        'phlebotomistPhone': phone,
        'phlebotomistEquipment': equipment,
      });
    } catch (e) {
      throw Exception('Failed to assign phlebotomist: $e');
    }
  }

  // Upload report URL
  Future<void> uploadReport(String bookingId, String reportUrl) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'reportUrl': reportUrl,
        'reportGeneratedAt': Timestamp.fromDate(DateTime.now()),
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
