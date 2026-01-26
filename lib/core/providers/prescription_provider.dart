import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/prescription_model.dart';
import '../../models/user_model.dart';
import 'auth_provider.dart';

// Prescription Service Provider
final prescriptionServiceProvider = Provider<PrescriptionServiceProvider>((ref) {
  return PrescriptionServiceProvider();
});

class PrescriptionServiceProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get prescriptions stream for a patient
  Stream<List<PrescriptionModel>> getPrescriptionsStream(String patientId) {
    if (patientId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => PrescriptionModel.fromJson(doc.data(), doc.id))
              .toList();
          // Sort client-side to avoid composite index requirement
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Get prescriptions by doctor
  Stream<List<PrescriptionModel>> getDoctorPrescriptionsStream(String doctorId) {
    if (doctorId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('prescriptions')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => PrescriptionModel.fromJson(doc.data(), doc.id))
              .toList();
          // Sort client-side to avoid composite index requirement
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Create prescription
  Future<String> createPrescription(PrescriptionModel prescription) async {
    final docRef = await _firestore
        .collection('prescriptions')
        .add(prescription.toJson());
    return docRef.id;
  }

  // Delete prescription
  Future<void> deletePrescription(String prescriptionId) async {
    await _firestore.collection('prescriptions').doc(prescriptionId).delete();
  }
}

// Patient Prescriptions Provider
final patientPrescriptionsProvider =
    StreamProvider.family<List<PrescriptionModel>, String>((ref, patientId) {
  if (patientId.isEmpty) {
    return Stream.value([]);
  }

  final service = ref.watch(prescriptionServiceProvider);
  return service.getPrescriptionsStream(patientId);
});

// Current User Prescriptions Provider (for patients)
final userPrescriptionsProvider =
    StreamProvider<List<PrescriptionModel>>((ref) async* {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;

  if (user == null || user.role != UserRole.patient) {
    yield [];
    return;
  }

  final service = ref.read(prescriptionServiceProvider);
  await for (final prescriptions in service.getPrescriptionsStream(user.userId)) {
    yield prescriptions;
  }
});

// Prescription Controller State
class PrescriptionControllerState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const PrescriptionControllerState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  PrescriptionControllerState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return PrescriptionControllerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Prescription Controller Provider
final prescriptionControllerProvider =
    StateNotifierProvider<PrescriptionController, PrescriptionControllerState>(
        (ref) {
  return PrescriptionController(ref);
});

// Prescription Controller
class PrescriptionController
    extends StateNotifier<PrescriptionControllerState> {
  final Ref _ref;

  PrescriptionController(this._ref)
      : super(const PrescriptionControllerState());

  PrescriptionServiceProvider get _service =>
      _ref.read(prescriptionServiceProvider);

  /// Create a prescription (doctor action)
  Future<bool> createPrescription(PrescriptionModel prescription) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.createPrescription(prescription);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Prescription created successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create prescription',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}
