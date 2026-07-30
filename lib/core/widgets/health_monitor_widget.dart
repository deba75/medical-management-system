import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../../models/health_metrics_model.dart';
import '../services/smartwatch_health_service.dart';

class HealthMonitorWidget extends StatefulWidget {
  final String? userId;
  final bool isCompact;

  const HealthMonitorWidget({
    super.key,
    this.userId,
    this.isCompact = false,
  });

  @override
  State<HealthMonitorWidget> createState() => _HealthMonitorWidgetState();
}

class _HealthMonitorWidgetState extends State<HealthMonitorWidget> {
  final SmartwatchHealthService _healthService = SmartwatchHealthService();

  HealthMetrics? _currentMetrics;
  bool _isLoadingVitals = true;
  SmartwatchFetchStatus _fetchStatus = SmartwatchFetchStatus.noData;
  String? _vitalsErrorMessage;
  DateTime? _lastFirebaseSyncTime;
  bool _isFirebaseSavedThisFetch = false;
  Timer? _periodicTimer;
  
  // Blood donation data
  String? _bloodGroup;
  DateTime? _lastDonationDate;
  bool _isLoadingBloodData = true;

  @override
  void initState() {
    super.initState();
    _fetchWatchData();
    _loadBloodDonationData();

    // Auto-check & auto-save smartwatch vitals to Firebase every 10 minutes
    _periodicTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _fetchWatchData();
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  /// Fetch latest Heart Rate & Blood Pressure data from Google Health Connect
  Future<void> _fetchWatchData({bool requestPermissionIfDenied = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoadingVitals = true;
      _vitalsErrorMessage = null;
    });

    if (requestPermissionIfDenied) {
      await _healthService.requestPermissions();
    }

    final result = await _healthService.fetchLatestVitals();

    bool newlySavedToFirebase = false;
    DateTime? lastSync;
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

    if (result.status == SmartwatchFetchStatus.success && result.metrics != null && userId != null) {
      newlySavedToFirebase = await _healthService.syncVitalsToFirebase(userId, result.metrics!);
      lastSync = await _healthService.getLastFirebaseSyncTime(userId);
    }

    if (mounted) {
      setState(() {
        _fetchStatus = result.status;
        _currentMetrics = result.metrics;
        _vitalsErrorMessage = result.errorMessage;
        _lastFirebaseSyncTime = lastSync;
        _isFirebaseSavedThisFetch = newlySavedToFirebase;
        _isLoadingVitals = false;
      });
    }
  }

  Future<void> _loadBloodDonationData() async {
    try {
      final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoadingBloodData = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data()!;
        setState(() {
          _bloodGroup = data['bloodGroup'];
          if (data['lastDonationDate'] != null) {
            _lastDonationDate = data['lastDonationDate'] is Timestamp
                ? (data['lastDonationDate'] as Timestamp).toDate()
                : DateTime.tryParse(data['lastDonationDate'].toString());
          }
          _isLoadingBloodData = false;
        });
      } else {
        setState(() => _isLoadingBloodData = false);
      }
    } catch (e) {
      debugPrint('Error loading blood data: $e');
      setState(() => _isLoadingBloodData = false);
    }
  }

  bool get _isEligibleToDonate {
    if (_lastDonationDate == null) return true;
    final daysSinceLastDonation = DateTime.now().difference(_lastDonationDate!).inDays;
    return daysSinceLastDonation >= 120;
  }

  String get _lastDonationText {
    if (_lastDonationDate == null) return 'Not recorded';
    final daysSince = DateTime.now().difference(_lastDonationDate!).inDays;
    if (daysSince == 0) return 'Today';
    if (daysSince == 1) return 'Yesterday';
    if (daysSince < 30) return '$daysSince days ago';
    if (daysSince < 60) return '1 month ago';
    return '${(daysSince / 30).floor()} months ago';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  Widget _buildCompactView() {
    if (_isLoadingVitals) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_fetchStatus == SmartwatchFetchStatus.success && _currentMetrics != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.secondaryColor.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.favorite,
                    label: 'Heart Rate',
                    value: '${_currentMetrics!.heartRate}',
                    unit: 'bpm',
                    color: Colors.red,
                    status: _currentMetrics!.heartRateStatus,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.monitor_heart,
                    label: 'Blood Pressure',
                    value: _currentMetrics!.bloodPressure,
                    unit: 'mmHg',
                    color: Colors.blue,
                    status: _currentMetrics!.bpStatus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.directions_walk,
                    label: 'Walk (Steps)',
                    value: '${_currentMetrics!.steps}',
                    unit: '/ ${_currentMetrics!.stepGoal}',
                    color: Colors.orange,
                    status: '${(_currentMetrics!.stepProgress * 100).toInt()}% Target',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    value: '${_currentMetrics!.totalCalories}',
                    unit: '/ ${_currentMetrics!.calorieGoal} kcal',
                    color: Colors.purple,
                    status: '${(_currentMetrics!.calorieProgress * 100).toInt()}% Target',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Empty / permission / error state compact card
    return InkWell(
      onTap: () => _fetchWatchData(
        requestPermissionIfDenied: _fetchStatus == SmartwatchFetchStatus.permissionDenied,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _fetchStatus == SmartwatchFetchStatus.permissionDenied
                  ? Icons.lock_outline
                  : Icons.watch_outlined,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fetchStatus == SmartwatchFetchStatus.permissionDenied
                        ? 'Health Connect Permission Needed'
                        : 'Smartwatch Vitals',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fetchStatus == SmartwatchFetchStatus.permissionDenied
                        ? 'Tap to grant permission'
                        : 'No vitals recorded • Tap to sync watch',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.refresh, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFullView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.05),
            AppTheme.secondaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildVitalsContent(),
          const SizedBox(height: 16),
          // Blood Donation Section
          _buildBloodDonationSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final (statusColor, statusText) = switch (_fetchStatus) {
      SmartwatchFetchStatus.success => (
          Colors.green,
          _currentMetrics != null
              ? 'Connected • Health Connect (${_formatTime(_currentMetrics!.timestamp)})'
              : 'Connected • Live'
        ),
      SmartwatchFetchStatus.noData => (Colors.orange, 'Health Connect • No recent vitals'),
      SmartwatchFetchStatus.permissionDenied => (Colors.red, 'Health Connect • Permission required'),
      SmartwatchFetchStatus.sdkUnavailable => (Colors.purple, 'Health Connect • App required'),
      SmartwatchFetchStatus.error => (Colors.red, 'Health Connect • Connection error'),
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.watch_rounded,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smartwatch Vitals',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _isLoadingVitals
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton.icon(
                onPressed: () => _fetchWatchData(
                  requestPermissionIfDenied: _fetchStatus == SmartwatchFetchStatus.permissionDenied,
                ),
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Sync Watch', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildVitalsContent() {
    if (_isLoadingVitals) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'Fetching vitals from Health Connect...',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_fetchStatus == SmartwatchFetchStatus.sdkUnavailable) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.download_for_offline_outlined, color: Colors.purple, size: 36),
            const SizedBox(height: 8),
            const Text(
              'Health Connect App Required',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Google Health Connect is not installed or requires an update on your Android device to sync smartwatch vitals.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _healthService.installHealthConnect(),
              icon: const Icon(Icons.get_app, size: 18),
              label: const Text('Install / Update Health Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_fetchStatus == SmartwatchFetchStatus.permissionDenied) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            const Text(
              'Permission Required',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Google Health Connect read permissions are required to display your smartwatch Heart Rate and Blood Pressure.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _fetchWatchData(requestPermissionIfDenied: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Grant Health Connect Access'),
            ),
          ],
        ),
      );
    }

    if (_fetchStatus == SmartwatchFetchStatus.noData) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.watch_off_outlined, color: Colors.orange, size: 36),
            const SizedBox(height: 8),
            const Text(
              'No Smartwatch Data Found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'No Heart Rate or Blood Pressure readings recorded in Health Connect in the last 24 hours. Ensure your smartwatch app (Samsung Health, Fitbit, Garmin, Pixel Watch) has Health Connect sync enabled.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _fetchWatchData(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh / Sync from Watch'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_fetchStatus == SmartwatchFetchStatus.error) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            Text(
              _vitalsErrorMessage ?? 'Unable to connect to Health Connect',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _fetchWatchData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry Sync'),
            ),
          ],
        ),
      );
    }

    // Success state with metrics available
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.favorite,
                label: 'Heart Rate',
                value: '${_currentMetrics!.heartRate}',
                unit: 'bpm',
                color: Colors.red,
                status: _currentMetrics!.heartRateStatus,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.monitor_heart,
                label: 'Blood Pressure',
                value: _currentMetrics!.bloodPressure,
                unit: 'mmHg',
                color: Colors.blue,
                status: _currentMetrics!.bpStatus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildProgressMetricCard(
                icon: Icons.directions_walk,
                label: 'Walk (Steps)',
                current: _currentMetrics!.steps,
                target: _currentMetrics!.stepGoal,
                unit: 'steps',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildProgressMetricCard(
                icon: Icons.local_fire_department,
                label: 'Calories Burned',
                current: _currentMetrics!.totalCalories,
                target: _currentMetrics!.calorieGoal,
                unit: 'kcal',
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_done_outlined, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  _lastFirebaseSyncTime != null
                      ? 'Firebase auto-saved: ${_formatTime(_lastFirebaseSyncTime!)}'
                      : 'Firebase Sync: Hourly',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (_isFirebaseSavedThisFetch)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Saved (Hourly)',
                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildBloodDonationSection() {
    if (_isLoadingBloodData) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _showBloodDonationDialog,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.bloodtype,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _bloodGroup ?? 'Set Blood Group',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEligibleToDonate ? '• Eligible to donate now' : '• Not eligible yet',
                        style: TextStyle(
                          color: _isEligibleToDonate ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last donation: $_lastDonationText',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              color: Colors.green.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showBloodDonationDialog() {
    String? selectedBloodGroup = _bloodGroup;
    DateTime? selectedDate = _lastDonationDate;

    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bloodtype, color: Colors.red),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Blood Donation Info',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your Blood Group',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: bloodGroups.map((group) {
                    final isSelected = selectedBloodGroup == group;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedBloodGroup = group),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.red : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          group,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Last Donation Date',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setModalState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Select date (optional)',
                          style: TextStyle(
                            color: selectedDate != null ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _saveBloodDonationData(selectedBloodGroup, selectedDate);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveBloodDonationData(String? bloodGroup, DateTime? lastDonation) async {
    try {
      final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final updateData = <String, dynamic>{};
      if (bloodGroup != null) updateData['bloodGroup'] = bloodGroup;
      if (lastDonation != null) updateData['lastDonationDate'] = Timestamp.fromDate(lastDonation);

      if (updateData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(updateData, SetOptions(merge: true));

        setState(() {
          _bloodGroup = bloodGroup;
          _lastDonationDate = lastDonation;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Blood donation info updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving blood data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status == 'Normal').withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: _getStatusColor(status == 'Normal'),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetricCard({
    required IconData icon,
    required String label,
    required int current,
    required int target,
    required String unit,
    required Color color,
  }) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$current',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ $target $unit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required String status,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getStatusColor(status == 'Normal').withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: _getStatusColor(status == 'Normal'),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(bool isNormal) {
    return isNormal ? Colors.green : Colors.orange;
  }
}
