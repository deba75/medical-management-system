import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/doctor_model.dart';

// Doctor Service Provider
final doctorServiceProvider = Provider<DoctorServiceProvider>((ref) {
  return DoctorServiceProvider();
});

class DoctorServiceProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all active doctors
  Stream<List<DoctorModel>> getDoctorsStream() {
    return _firestore
        .collection('doctors')
        .where('active', isEqualTo: true)
        .where('verificationStatus', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DoctorModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get doctors by specialization
  Stream<List<DoctorModel>> getDoctorsBySpecialization(String specialization) {
    return _firestore
        .collection('doctors')
        .where('active', isEqualTo: true)
        .where('verificationStatus', isEqualTo: 'approved')
        .where('specialization', isEqualTo: specialization)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DoctorModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get a single doctor by ID
  Future<DoctorModel?> getDoctorById(String doctorId) async {
    final doc = await _firestore.collection('doctors').doc(doctorId).get();
    if (doc.exists) {
      return DoctorModel.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  // Search doctors by name or specialization
  Stream<List<DoctorModel>> searchDoctors(String query) {
    final lowercaseQuery = query.toLowerCase();

    return _firestore
        .collection('doctors')
        .where('active', isEqualTo: true)
        .where('verificationStatus', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DoctorModel.fromJson(doc.data(), doc.id))
            .where((doctor) =>
                doctor.name.toLowerCase().contains(lowercaseQuery) ||
                doctor.specialization.toLowerCase().contains(lowercaseQuery))
            .toList());
  }
}

// All Doctors Provider
final allDoctorsProvider = StreamProvider<List<DoctorModel>>((ref) {
  final service = ref.watch(doctorServiceProvider);
  return service.getDoctorsStream();
});

// Doctors by Specialization Provider
final doctorsBySpecializationProvider =
    StreamProvider.family<List<DoctorModel>, String>((ref, specialization) {
  final service = ref.watch(doctorServiceProvider);
  return service.getDoctorsBySpecialization(specialization);
});

// Doctor Search Provider
final doctorSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedDoctorsProvider = StreamProvider<List<DoctorModel>>((ref) {
  final query = ref.watch(doctorSearchQueryProvider);
  final service = ref.watch(doctorServiceProvider);

  if (query.isEmpty) {
    return service.getDoctorsStream();
  }

  return service.searchDoctors(query);
});

// Single Doctor Provider
final singleDoctorProvider =
    FutureProvider.family<DoctorModel?, String>((ref, doctorId) async {
  final service = ref.watch(doctorServiceProvider);
  return service.getDoctorById(doctorId);
});

// Available Specializations
final specializationsProvider = Provider<List<String>>((ref) {
  return [
    'Cardiologist',
    'Dermatologist',
    'Neurologist',
    'Orthopedic',
    'Pediatrician',
    'Psychiatrist',
    'General Physician',
    'Gynecologist',
    'Ophthalmologist',
    'ENT Specialist',
    'Dentist',
    'Urologist',
  ];
});
