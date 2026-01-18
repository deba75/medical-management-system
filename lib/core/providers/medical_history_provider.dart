import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medical_history_model.dart';
import '../../models/user_model.dart';
import 'auth_provider.dart';

// Medical History Service Provider
final medicalHistoryServiceProvider = Provider<MedicalHistoryServiceProvider>((ref) {
  return MedicalHistoryServiceProvider();
});

class MedicalHistoryServiceProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get medical history stream for a patient
  Stream<List<MedicalHistoryModel>> getMedicalHistoryStream(String patientId) {
    if (patientId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('medicalHistory')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicalHistoryModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Add medical history entry
  Future<String> addMedicalHistory(MedicalHistoryModel history) async {
    final docRef = await _firestore
        .collection('medicalHistory')
        .add(history.toJson());
    return docRef.id;
  }

  // Delete medical history entry
  Future<void> deleteMedicalHistory(String historyId) async {
    await _firestore.collection('medicalHistory').doc(historyId).delete();
  }

  // Update medical history entry
  Future<void> updateMedicalHistory(
      String historyId, Map<String, dynamic> data) async {
    await _firestore.collection('medicalHistory').doc(historyId).update(data);
  }
}

// Patient Medical History Provider
final patientMedicalHistoryProvider =
    StreamProvider.family<List<MedicalHistoryModel>, String>((ref, patientId) {
  if (patientId.isEmpty) {
    return Stream.value([]);
  }

  final service = ref.watch(medicalHistoryServiceProvider);
  return service.getMedicalHistoryStream(patientId);
});

// Current User Medical History Provider
final userMedicalHistoryProvider =
    StreamProvider<List<MedicalHistoryModel>>((ref) async* {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;

  if (user == null || user.role != UserRole.patient) {
    yield [];
    return;
  }

  final service = ref.read(medicalHistoryServiceProvider);
  await for (final history in service.getMedicalHistoryStream(user.userId)) {
    yield history;
  }
});

// Medical History Controller State
class MedicalHistoryControllerState {
  final bool isLoading;
  final bool isUploading;
  final String? error;
  final String? successMessage;

  const MedicalHistoryControllerState({
    this.isLoading = false,
    this.isUploading = false,
    this.error,
    this.successMessage,
  });

  MedicalHistoryControllerState copyWith({
    bool? isLoading,
    bool? isUploading,
    String? error,
    String? successMessage,
  }) {
    return MedicalHistoryControllerState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Medical History Controller Provider
final medicalHistoryControllerProvider = StateNotifierProvider<
    MedicalHistoryController, MedicalHistoryControllerState>((ref) {
  return MedicalHistoryController(ref);
});

// Medical History Controller
class MedicalHistoryController
    extends StateNotifier<MedicalHistoryControllerState> {
  final Ref _ref;

  MedicalHistoryController(this._ref)
      : super(const MedicalHistoryControllerState());

  MedicalHistoryServiceProvider get _service =>
      _ref.read(medicalHistoryServiceProvider);

  /// Add a medical history entry
  Future<bool> addMedicalHistory(MedicalHistoryModel history) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      await _service.addMedicalHistory(history);
      state = state.copyWith(
        isUploading: false,
        successMessage: 'Medical record added successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Failed to add medical record',
      );
      return false;
    }
  }

  /// Delete a medical history entry
  Future<bool> deleteMedicalHistory(String historyId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.deleteMedicalHistory(historyId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Medical record deleted',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete medical record',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}
