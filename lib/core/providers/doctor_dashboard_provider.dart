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
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs
        .map((doc) => AppointmentModel.fromJson(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  });
});

// Doctor's Today Appointments Provider
final doctorTodayAppointmentsProvider = Provider<AsyncValue<List<AppointmentModel>>>((ref) {
  final allAsync = ref.watch(doctorAllAppointmentsProvider);
  final now = DateTime.now();

  return allAsync.whenData((all) {
    return all.where((app) {
      return app.date.year == now.year &&
          app.date.month == now.month &&
          app.date.day == now.day;
    }).toList();
  });
});

// Doctor's Completed Appointments Provider
final doctorCompletedAppointmentsProvider = Provider<List<AppointmentModel>>((ref) {
  final allAsync = ref.watch(doctorAllAppointmentsProvider);
  final all = allAsync.value ?? [];
  return all.where((app) => app.status == AppointmentStatus.completed).toList();
});

// Doctor's Pending Appointments Provider
final doctorPendingAppointmentsProvider = Provider<List<AppointmentModel>>((ref) {
  final allAsync = ref.watch(doctorAllAppointmentsProvider);
  final all = allAsync.value ?? [];
  return all.where((app) => app.status == AppointmentStatus.upcoming).toList();
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
      .snapshots()
      .map((snapshot) {
    double todayEarnings = 0;
    double weeklyEarnings = 0;
    double monthlyEarnings = 0;
    double totalEarnings = 0;
    int totalPaidAppointments = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final fee = (data['consultationFee'] ?? data['fee'] ?? 0).toDouble();
      final appointmentDate = data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.tryParse(data['date']?.toString() ?? '');

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
  final int completedAppointments;
  final int pendingAppointments;
  final double todayEarnings;
  final int chambersCount;

  const DoctorDashboardStats({
    this.todayAppointments = 0,
    this.completedAppointments = 0,
    this.pendingAppointments = 0,
    this.todayEarnings = 0.0,
    this.chambersCount = 0,
  });
}

final doctorDashboardStatsProvider = Provider<DoctorDashboardStats>((ref) {
  final todayAppointments = ref.watch(doctorTodayAppointmentsProvider);
  final completedAppointments = ref.watch(doctorCompletedAppointmentsProvider);
  final pendingAppointments = ref.watch(doctorPendingAppointmentsProvider);
  final earnings = ref.watch(doctorEarningsProvider);
  final chambers = ref.watch(doctorChambersCountProvider);

  return DoctorDashboardStats(
    todayAppointments: todayAppointments.value?.length ?? 0,
    completedAppointments: completedAppointments.length,
    pendingAppointments: pendingAppointments.length,
    todayEarnings: earnings.value?.todayEarnings ?? 0.0,
    chambersCount: chambers.value ?? 0,
  );
});

// Doctor Appointment Controller
class DoctorAppointmentController extends StateNotifier<AsyncValue<void>> {
  // ignore: unused_field - kept for future use
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
