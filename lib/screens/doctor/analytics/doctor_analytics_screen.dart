import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DoctorAnalyticsScreen extends ConsumerStatefulWidget {
  const DoctorAnalyticsScreen({super.key});

  @override
  ConsumerState<DoctorAnalyticsScreen> createState() => _DoctorAnalyticsScreenState();
}

class _DoctorAnalyticsScreenState extends ConsumerState<DoctorAnalyticsScreen> {
  final _doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _selectedPeriod = 'This Month';
  bool _isLoading = true;
  
  // Analytics data
  int _totalPatients = 0;
  int _newPatients = 0;
  int _totalAppointments = 0;
  int _completedAppointments = 0;
  int _cancelledAppointments = 0;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  Map<String, int> _appointmentsByDay = {};
  Map<String, int> _appointmentTypes = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedPeriod) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'This Week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
      }

      // Get appointments
      final appointmentsQuery = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: _doctorId)
          .where('appointmentDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      final appointments = appointmentsQuery.docs;
      
      // Calculate metrics
      _totalAppointments = appointments.length;
      _completedAppointments = appointments.where((a) => a.data()['status'] == 'completed').length;
      _cancelledAppointments = appointments.where((a) => a.data()['status'] == 'cancelled').length;

      // Get unique patients
      final patientIds = appointments.map((a) => a.data()['patientId'] as String).toSet();
      _totalPatients = patientIds.length;

      // Get new patients (first appointment in period)
      _newPatients = 0;
      for (final patientId in patientIds) {
        final firstAppointment = await FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: _doctorId)
            .where('patientId', isEqualTo: patientId)
            .orderBy('appointmentDateTime')
            .limit(1)
            .get();
        
        if (firstAppointment.docs.isNotEmpty) {
          final firstDate = (firstAppointment.docs.first.data()['appointmentDateTime'] as Timestamp).toDate();
          if (firstDate.isAfter(startDate)) {
            _newPatients++;
          }
        }
      }

      // Get reviews
      final reviewsQuery = await FirebaseFirestore.instance
          .collection('doctor_reviews')
          .where('doctorId', isEqualTo: _doctorId)
          .get();

      _totalReviews = reviewsQuery.docs.length;
      if (_totalReviews > 0) {
        final totalRating = reviewsQuery.docs
            .map((r) => (r.data()['rating'] as num).toDouble())
            .reduce((a, b) => a + b);
        _averageRating = totalRating / _totalReviews;
      }

      // Appointments by day of week
      _appointmentsByDay = {'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0};
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (final apt in appointments) {
        final date = (apt.data()['appointmentDateTime'] as Timestamp).toDate();
        final dayName = days[date.weekday - 1];
        _appointmentsByDay[dayName] = (_appointmentsByDay[dayName] ?? 0) + 1;
      }

      // Appointment types
      _appointmentTypes = {'In-Clinic': 0, 'Follow-up': 0};
      for (final apt in appointments) {
        final type = apt.data()['appointmentType'] as String? ?? 'In-Clinic';
        _appointmentTypes[type] = (_appointmentTypes[type] ?? 0) + 1;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading analytics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadAnalytics(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildAppointmentChart(),
                    const SizedBox(height: 24),
                    _buildAppointmentTypesPieChart(),
                    const SizedBox(height: 24),
                    _buildPerformanceMetrics(),
                    const SizedBox(height: 24),
                    _buildPatientInsights(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Today', 'This Week', 'This Month', 'This Year'].map((period) {
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedPeriod = period);
                _loadAnalytics();
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'Total Patients',
          value: _totalPatients.toString(),
          subtitle: '+$_newPatients new',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Appointments',
          value: _totalAppointments.toString(),
          subtitle: '$_completedAppointments completed',
          icon: Icons.calendar_today,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Rating',
          value: _averageRating.toStringAsFixed(1),
          subtitle: '$_totalReviews reviews',
          icon: Icons.star,
          color: Colors.amber,
        ),
        _buildStatCard(
          title: 'Completion Rate',
          value: _totalAppointments > 0
              ? '${((_completedAppointments / _totalAppointments) * 100).toStringAsFixed(0)}%'
              : '0%',
          subtitle: '$_cancelledAppointments cancelled',
          icon: Icons.check_circle,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appointments by Day',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (_appointmentsByDay.values.isEmpty
                      ? 10
                      : (_appointmentsByDay.values.reduce((a, b) => a > b ? a : b) + 5)).toDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return BarTooltipItem(
                          '${days[group.x.toInt()]}: ${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[value.toInt()],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _appointmentsByDay.entries.toList().asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: AppTheme.primaryColor,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentTypesPieChart() {
    final total = _appointmentTypes.values.fold(0, (a, b) => a + b);
    final colors = [Colors.blue, Colors.purple, Colors.orange];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appointment Types',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _appointmentTypes.entries.toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final type = entry.value;
                        final percentage = total > 0 ? (type.value / total) * 100 : 0.0;
                        return PieChartSectionData(
                          value: type.value.toDouble(),
                          color: colors[index % colors.length],
                          radius: 30,
                          title: '${percentage.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _appointmentTypes.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final type = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(type.key)),
                            Text(
                              '${type.value}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Completion Rate',
              _totalAppointments > 0
                  ? (_completedAppointments / _totalAppointments)
                  : 0,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Patient Satisfaction',
              _averageRating / 5,
              Colors.amber,
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Return Patient Rate',
              _totalPatients > 0 && _newPatients < _totalPatients
                  ? ((_totalPatients - _newPatients) / _totalPatients)
                  : 0,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, double value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInsights() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Patient Insights',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightTile(
              icon: Icons.person_add,
              title: 'New Patients',
              value: '$_newPatients',
              subtitle: 'this period',
              color: Colors.green,
            ),
            const Divider(height: 24),
            _buildInsightTile(
              icon: Icons.repeat,
              title: 'Return Patients',
              value: '${_totalPatients - _newPatients}',
              subtitle: 'this period',
              color: Colors.blue,
            ),
            const Divider(height: 24),
            _buildInsightTile(
              icon: Icons.star,
              title: 'Average Rating',
              value: _averageRating.toStringAsFixed(1),
              subtitle: 'from $_totalReviews reviews',
              color: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTile({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600])),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  void _exportReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting PDF...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting Excel...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
