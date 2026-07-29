import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/health_metrics_model.dart';

enum SmartwatchFetchStatus {
  success,
  noData,
  permissionDenied,
  sdkUnavailable,
  error,
}

class SmartwatchFetchResult {
  final SmartwatchFetchStatus status;
  final HealthMetrics? metrics;
  final String? errorMessage;

  SmartwatchFetchResult({
    required this.status,
    this.metrics,
    this.errorMessage,
  });
}

class SmartwatchHealthService {
  static final SmartwatchHealthService _instance =
      SmartwatchHealthService._internal();
  factory SmartwatchHealthService() => _instance;
  SmartwatchHealthService._internal();

  final Health _health = Health();

  static const List<HealthDataType> _types = [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.STEPS,
    HealthDataType.TOTAL_CALORIES_BURNED,
  ];

  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  bool _isConfigured = false;

  Future<void> _ensureConfigured() async {
    if (!_isConfigured) {
      try {
        await _health.configure();
        _isConfigured = true;
      } catch (e) {
        debugPrint('Error configuring Health Connect: $e');
      }
    }
  }

  /// Get Google Health Connect SDK availability status on Android
  Future<HealthConnectSdkStatus?> getSdkStatus() async {
    await _ensureConfigured();
    try {
      return await _health.getHealthConnectSdkStatus();
    } catch (e) {
      debugPrint('Error checking Health Connect SDK status: $e');
      return null;
    }
  }

  /// Launch Google Play Store to install or update Google Health Connect
  Future<void> installHealthConnect() async {
    try {
      await _health.installHealthConnect();
    } catch (e) {
      debugPrint('Error launching Health Connect installation: $e');
    }
  }

  /// Check if the app has required Health Connect read permissions
  Future<bool> hasPermissions() async {
    await _ensureConfigured();
    try {
      final hasPerm = await _health.hasPermissions(
        _types,
        permissions: _permissions,
      );
      return hasPerm ?? false;
    } catch (e) {
      debugPrint('Error checking Health Connect permissions: $e');
      return false;
    }
  }

  /// Request Health Connect permissions from user
  Future<bool> requestPermissions() async {
    await _ensureConfigured();
    try {
      final authorized = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      return authorized;
    } catch (e) {
      debugPrint('Error requesting Health Connect permissions: $e');
      return false;
    }
  }

  /// Fetch the latest vitals (Heart Rate & Blood Pressure) from Health Connect
  /// Queries data logged within the past 24 hours (or optional custom duration)
  Future<SmartwatchFetchResult> fetchLatestVitals({
    Duration searchWindow = const Duration(hours: 24),
  }) async {
    await _ensureConfigured();

    try {
      // 1. Check SDK availability
      final sdkStatus = await getSdkStatus();
      if (sdkStatus != null &&
          sdkStatus != HealthConnectSdkStatus.sdkAvailable) {
        return SmartwatchFetchResult(
          status: SmartwatchFetchStatus.sdkUnavailable,
          errorMessage:
              'Google Health Connect is not installed or requires an update on your device.',
        );
      }

      // 2. Check permissions
      bool hasPerm = await hasPermissions();
      if (!hasPerm) {
        final granted = await requestPermissions();
        hasPerm = await hasPermissions();
        if (!granted && !hasPerm) {
          return SmartwatchFetchResult(
            status: SmartwatchFetchStatus.permissionDenied,
            errorMessage: 'Health Connect permissions were not granted.',
          );
        }
      }

      final now = DateTime.now();
      final startTime = now.subtract(searchWindow);

      final List<HealthDataPoint> healthData = await _health
          .getHealthDataFromTypes(
            types: _types,
            startTime: startTime,
            endTime: now,
          );

      if (healthData.isEmpty) {
        return SmartwatchFetchResult(
          status: SmartwatchFetchStatus.noData,
          errorMessage:
              'No smartwatch vitals logged in Health Connect for the last 24 hours.',
        );
      }

      // Filter and pick latest readings for each metric
      int? latestHeartRate;
      DateTime? hrTime;

      int? latestSystolic;
      DateTime? sysTime;

      int? latestDiastolic;
      DateTime? diaTime;

      int? latestSteps;
      int? latestCalories;

      for (final point in healthData) {
        final numValue = _extractNumericValue(point.value);
        if (numValue == null) continue;

        if (point.type == HealthDataType.HEART_RATE) {
          if (hrTime == null || point.dateFrom.isAfter(hrTime)) {
            latestHeartRate = numValue.round();
            hrTime = point.dateFrom;
          }
        } else if (point.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC) {
          if (sysTime == null || point.dateFrom.isAfter(sysTime)) {
            latestSystolic = numValue.round();
            sysTime = point.dateFrom;
          }
        } else if (point.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC) {
          if (diaTime == null || point.dateFrom.isAfter(diaTime)) {
            latestDiastolic = numValue.round();
            diaTime = point.dateFrom;
          }
        } else if (point.type == HealthDataType.STEPS) {
          latestSteps = (latestSteps ?? 0) + numValue.round();
        } else if (point.type == HealthDataType.TOTAL_CALORIES_BURNED) {
          latestCalories = (latestCalories ?? 0) + numValue.round();
        }
      }

      if (latestHeartRate == null &&
          latestSystolic == null &&
          latestDiastolic == null &&
          latestSteps == null &&
          latestCalories == null) {
        return SmartwatchFetchResult(
          status: SmartwatchFetchStatus.noData,
          errorMessage: 'No valid vitals, step or calorie readings found in Health Connect.',
        );
      }

      // Determine most recent timestamp
      final timestamps = [
        hrTime,
        sysTime,
        diaTime,
      ].whereType<DateTime>().toList();
      final latestTimestamp = timestamps.isNotEmpty
          ? timestamps.reduce((a, b) => a.isAfter(b) ? a : b)
          : DateTime.now();

      final systolic = latestSystolic ?? 120;
      final diastolic = latestDiastolic ?? 80;
      final heartRate = latestHeartRate ?? 72;

      // Determine overall status
      String calculatedStatus = 'normal';
      if (systolic > 140 || diastolic > 90 || heartRate > 100) {
        calculatedStatus = 'critical';
      } else if (systolic < 90 || diastolic < 60 || heartRate < 60) {
        calculatedStatus = 'warning';
      }

      final metrics = HealthMetrics(
        systolicBP: systolic,
        diastolicBP: diastolic,
        heartRate: heartRate,
        timestamp: latestTimestamp,
        status: calculatedStatus,
        steps: latestSteps ?? 0,
        stepGoal: 10000,
        totalCalories: latestCalories ?? 0,
        calorieGoal: 2000,
      );

      return SmartwatchFetchResult(
        status: SmartwatchFetchStatus.success,
        metrics: metrics,
      );
    } catch (e) {
      debugPrint('Error fetching vitals from Health Connect: $e');
      return SmartwatchFetchResult(
        status: SmartwatchFetchStatus.error,
        errorMessage: 'Failed to fetch Health Connect data: $e',
      );
    }
  }

  /// Sync vitals to Firebase Firestore at most once every hour (60 minutes)
  /// Returns `true` if saved to Firebase, `false` if skipped due to 1-hour rate limit.
  Future<bool> syncVitalsToFirebase(
    String userId,
    HealthMetrics metrics, {
    bool force = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'last_vitals_sync_$userId';
      final lastSyncMillis = prefs.getInt(key) ?? 0;
      final nowMillis = DateTime.now().millisecondsSinceEpoch;

      const oneHourMillis = 60 * 60 * 1000;
      final timeSinceLastSync = nowMillis - lastSyncMillis;

      if (!force && timeSinceLastSync < oneHourMillis) {
        final remainingMins =
            ((oneHourMillis - timeSinceLastSync) / (60 * 1000)).ceil();
        debugPrint(
          'Skipping Firebase vitals save: Next save allowed in $remainingMins mins.',
        );
        return false;
      }

      final vitalsData = {
        'systolicBP': metrics.systolicBP,
        'diastolicBP': metrics.diastolicBP,
        'heartRate': metrics.heartRate,
        'bloodPressure': metrics.bloodPressure,
        'status': metrics.status,
        'timestamp': Timestamp.fromDate(metrics.timestamp),
        'lastSyncedAt': FieldValue.serverTimestamp(),
      };

      // 1. Update latest vitals on user document
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'latestVitals': vitalsData,
        'lastVitalsSavedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Append to vitals_history subcollection for trend tracking
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('vitals_history')
          .add({...vitalsData, 'createdAt': FieldValue.serverTimestamp()});

      await prefs.setInt(key, nowMillis);
      debugPrint(
        'Successfully saved smartwatch vitals to Firebase for user: $userId',
      );
      return true;
    } catch (e) {
      debugPrint('Error syncing smartwatch vitals to Firebase: $e');
      return false;
    }
  }

  /// Get the last time smartwatch vitals were saved to Firebase
  Future<DateTime?> getLastFirebaseSyncTime(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'last_vitals_sync_$userId';
      final lastSyncMillis = prefs.getInt(key);
      if (lastSyncMillis != null && lastSyncMillis > 0) {
        return DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
      }
    } catch (e) {
      debugPrint('Error getting last sync time: $e');
    }
    return null;
  }

  num? _extractNumericValue(HealthValue value) {
    if (value is NumericHealthValue) {
      return value.numericValue;
    }
    return null;
  }
}
