import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';
import '../../models/doctor_model.dart';
import '../../models/appointment_model.dart';

// Doctor Profile Provider - Gets the logged-in doctor's profile
final doctorProfileProvider = StreamProvider<DoctorModel?>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('doctors')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (doc.exists) {
      return DoctorModel.fromJson(doc.data()!, doc.id);
    }
    return null;
  });
});

// Doctor's Today Appointments Provider
final doctorTodayAppointmentsProvider =
    StreamProvider<List<AppointmentModel>>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) {
    return Stream.value([]);
  }

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return FirebaseFirestore.instance
      .collection('appointments')
      .where('doctorId', isEqualTo: user.uid)
      .where('appointmentDate', isGreaterThanOrEqualTo: startOfDay)
      .where('appointmentDate', isLessThanOrEqualTo: endOfDay)
      .orderBy('appointmentDate')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => AppointmentModel.fromJson(doc.data(), doc.id))
          .toList());
});

// Doctor's All Appointments Provider
final doctorAllAppointmentsProvider =
    StreamProvider<List<AppointmentModel>>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('appointments')
      .where('doctorId', isEqualTo: user.uid)
      .orderBy('appointmentDate', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => AppointmentModel.fromJson(doc.data(), doc.id))
          .toList());
});

// Doctor's Pending Appointments Provider
final doctorPendingAppointmentsProvider =
    StreamProvider<List<AppointmentModel>>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('appointments')
      .where('doctorId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'pending')
      .orderBy('appointmentDate')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => AppointmentModel.fromJson(doc.data(), doc.id))
          .toList());
});

// Doctor's Earnings Provider
class DoctorEarnings {
  final double todayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double totalEarnings;
  final int totalPaidAppointments;

  const DoctorEarnings({
    this.todayEarnings = 0.0,
    this.weeklyEarnings = 0.0,
    this.monthlyEarnings = 0.0,
    this.totalEarnings = 0.0,
    this.totalPaidAppointments = 0,
  });
}

final doctorEarningsProvider = StreamProvider<DoctorEarnings>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) {
    return Stream.value(const DoctorEarnings());
  }

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfMonth = DateTime(now.year, now.month, 1);

  return FirebaseFirestore.instance
      .collection('appointments')
      .where('doctorId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'completed')
      .where('paymentStatus', isEqualTo: 'paid')
      .snapshots()
      .map((snapshot) {
    double todayEarnings = 0;
    double weeklyEarnings = 0;
    double monthlyEarnings = 0;
    double totalEarnings = 0;
    int totalPaidAppointments = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final fee = (data['fee'] ?? 0).toDouble();
      final appointmentDate = data['appointmentDate'] is Timestamp
          ? (data['appointmentDate'] as Timestamp).toDate()
          : DateTime.tryParse(data['appointmentDate']?.toString() ?? '');

      if (appointmentDate != null) {
        totalEarnings += fee;
        totalPaidAppointments++;

        if (appointmentDate.isAfter(startOfDay)) {
          todayEarnings += fee;
        }
        if (appointmentDate.isAfter(startOfWeek)) {
          weeklyEarnings += fee;
        }
        if (appointmentDate.isAfter(startOfMonth)) {
          monthlyEarnings += fee;
        }
      }
    }

    return DoctorEarnings(
      todayEarnings: todayEarnings,
      weeklyEarnings: weeklyEarnings,
      monthlyEarnings: monthlyEarnings,
      totalEarnings: totalEarnings,
      totalPaidAppointments: totalPaidAppointments,
    );
  });
});

// Doctor's Chambers Count Provider
final doctorChambersCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) {
    return Stream.value(0);
  }

  return FirebaseFirestore.instance
      .collection('chambers')
      .where('doctorId', isEqualTo: user.uid)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// Doctor Dashboard Stats
class DoctorDashboardStats {
  final int todayAppointments;
  final int pendingAppointments;
  final double todayEarnings;
  final int chambersCount;

  const DoctorDashboardStats({
    this.todayAppointments = 0,
    this.pendingAppointments = 0,
    this.todayEarnings = 0.0,
    this.chambersCount = 0,
  });
}

final doctorDashboardStatsProvider = Provider<DoctorDashboardStats>((ref) {
  final todayAppointments = ref.watch(doctorTodayAppointmentsProvider);
  final pendingAppointments = ref.watch(doctorPendingAppointmentsProvider);
  final earnings = ref.watch(doctorEarningsProvider);
  final chambers = ref.watch(doctorChambersCountProvider);

  return DoctorDashboardStats(
    todayAppointments: todayAppointments.value?.length ?? 0,
    pendingAppointments: pendingAppointments.value?.length ?? 0,
    todayEarnings: earnings.value?.todayEarnings ?? 0.0,
    chambersCount: chambers.value ?? 0,
  );
});

// Doctor Appointment Controller
class DoctorAppointmentController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DoctorAppointmentController(this._ref) : super(const AsyncData(null));

  Future<bool> updateAppointmentStatus(
      String appointmentId, String status) async {
    state = const AsyncLoading();

    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': status});

      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> cancelAppointment(String appointmentId, String reason) async {
    state = const AsyncLoading();

    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> completeAppointment(String appointmentId) async {
    state = const AsyncLoading();

    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

final doctorAppointmentControllerProvider =
    StateNotifierProvider<DoctorAppointmentController, AsyncValue<void>>((ref) {
  return DoctorAppointmentController(ref);
});
