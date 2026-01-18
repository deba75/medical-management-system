import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import 'auth_provider.dart';

// Appointment Service Provider
final appointmentServiceProvider = Provider<AppointmentServiceProvider>((ref) {
  return AppointmentServiceProvider();
});

class AppointmentServiceProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get appointments stream for a user
  Stream<List<AppointmentModel>> getAppointmentsStream({
    required String userId,
    required bool isDoctor,
  }) {
    final field = isDoctor ? 'doctorId' : 'patientId';

    return _firestore
        .collection('appointments')
        .where(field, isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get upcoming appointments
  Stream<List<AppointmentModel>> getUpcomingAppointments({
    required String userId,
    required bool isDoctor,
  }) {
    final field = isDoctor ? 'doctorId' : 'patientId';
    final now = DateTime.now();

    return _firestore
        .collection('appointments')
        .where(field, isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: now.toIso8601String())
        .where('status', isEqualTo: 'upcoming')
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Create appointment
  Future<String> createAppointment(AppointmentModel appointment) async {
    final docRef = await _firestore
        .collection('appointments')
        .add(appointment.toJson());
    return docRef.id;
  }

  // Update appointment status
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required AppointmentStatus status,
  }) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cancel appointment
  Future<void> cancelAppointment(String appointmentId) async {
    await updateAppointmentStatus(
      appointmentId: appointmentId,
      status: AppointmentStatus.cancelled,
    );
  }
}

// Patient Appointments Provider
final patientAppointmentsProvider =
    StreamProvider.family<List<AppointmentModel>, String>((ref, patientId) {
  if (patientId.isEmpty) {
    return Stream.value([]);
  }

  final service = ref.watch(appointmentServiceProvider);
  return service.getAppointmentsStream(userId: patientId, isDoctor: false);
});

// Doctor Appointments Provider
final doctorAppointmentsProvider =
    StreamProvider.family<List<AppointmentModel>, String>((ref, doctorId) {
  if (doctorId.isEmpty) {
    return Stream.value([]);
  }

  final service = ref.watch(appointmentServiceProvider);
  return service.getAppointmentsStream(userId: doctorId, isDoctor: true);
});

// Current User Appointments Provider (auto-detects user type)
final userAppointmentsProvider =
    StreamProvider<List<AppointmentModel>>((ref) async* {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;

  if (user == null) {
    yield [];
    return;
  }

  final service = ref.read(appointmentServiceProvider);
  final isDoctor = user.role == UserRole.doctor;

  await for (final appointments
      in service.getAppointmentsStream(userId: user.userId, isDoctor: isDoctor)) {
    yield appointments;
  }
});

// Upcoming Appointments Provider
final upcomingAppointmentsProvider =
    Provider<List<AppointmentModel>>((ref) {
  final appointmentsAsync = ref.watch(userAppointmentsProvider);
  final appointments = appointmentsAsync.valueOrNull ?? [];
  final now = DateTime.now();

  return appointments
      .where((apt) =>
          apt.date.isAfter(now) && apt.status == AppointmentStatus.upcoming)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});

// Completed Appointments Provider
final completedAppointmentsProvider =
    Provider<List<AppointmentModel>>((ref) {
  final appointmentsAsync = ref.watch(userAppointmentsProvider);
  final appointments = appointmentsAsync.valueOrNull ?? [];

  return appointments
      .where((apt) => apt.status == AppointmentStatus.completed)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

// Appointment Controller State
class AppointmentControllerState {
  final bool isLoading;
  final bool isBooking;
  final String? error;
  final String? successMessage;

  const AppointmentControllerState({
    this.isLoading = false,
    this.isBooking = false,
    this.error,
    this.successMessage,
  });

  AppointmentControllerState copyWith({
    bool? isLoading,
    bool? isBooking,
    String? error,
    String? successMessage,
  }) {
    return AppointmentControllerState(
      isLoading: isLoading ?? this.isLoading,
      isBooking: isBooking ?? this.isBooking,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Appointment Controller Provider
final appointmentControllerProvider =
    StateNotifierProvider<AppointmentController, AppointmentControllerState>(
        (ref) {
  return AppointmentController(ref);
});

// Appointment Controller
class AppointmentController extends StateNotifier<AppointmentControllerState> {
  final Ref _ref;

  AppointmentController(this._ref)
      : super(const AppointmentControllerState());

  AppointmentServiceProvider get _service =>
      _ref.read(appointmentServiceProvider);

  /// Book an appointment
  Future<bool> bookAppointment(AppointmentModel appointment) async {
    state = state.copyWith(isBooking: true, error: null);

    try {
      await _service.createAppointment(appointment);
      state = state.copyWith(
        isBooking: false,
        successMessage: 'Appointment booked successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isBooking: false,
        error: 'Failed to book appointment: ${e.toString()}',
      );
      return false;
    }
  }

  /// Cancel an appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.cancelAppointment(appointmentId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Appointment cancelled successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel appointment',
      );
      return false;
    }
  }

  /// Complete an appointment (doctor action)
  Future<bool> completeAppointment(String appointmentId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: AppointmentStatus.completed,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Appointment marked as completed',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update appointment',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}
