import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/chamber_model.dart';

class ProductivityDashboardScreen extends StatefulWidget {
  const ProductivityDashboardScreen({super.key});

  @override
  State<ProductivityDashboardScreen> createState() => _ProductivityDashboardScreenState();
}

class _ProductivityDashboardScreenState extends State<ProductivityDashboardScreen> {
  DoctorStats? _stats;
  bool _isLoading = false;
  String _selectedPeriod = 'week'; // week, month, year

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    // TODO: Fetch from Firebase
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data
    _stats = DoctorStats(
      totalPatients: 156,
      avgConsultationTime: 18.5,
      satisfactionScore: 4.7,
      todayPatients: 12,
      upcomingAppointments: 8,
    );
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Dashboard'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              _loadStats();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'year', child: Text('This Year')),
            ],
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodHeader(),
                    const SizedBox(height: 24),
                    _buildKeyMetrics(),
                    const SizedBox(height: 24),
                    _buildConsultationBreakdown(),
                    const SizedBox(height: 24),
                    _buildPerformanceMetrics(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodHeader() {
    String periodText;
    switch (_selectedPeriod) {
      case 'week':
        periodText = 'This Week';
        break;
      case 'month':
        periodText = DateFormat('MMMM yyyy').format(DateTime.now());
        break;
      case 'year':
        periodText = DateTime.now().year.toString();
        break;
      default:
        periodText = 'This Week';
    }

    return Card(
      color: AppTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Productivity Index',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  periodText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetrics() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.people,
                label: 'Patients Seen',
                value: _stats!.totalPatients.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.access_time,
                label: 'Avg. Time',
                value: '${_stats!.avgConsultationTime.toStringAsFixed(1)} min',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.star,
                label: 'Rating',
                value: _stats!.satisfactionScore.toStringAsFixed(1),
                color: Colors.amber,
                suffix: '★',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.event,
                label: 'Today',
                value: _stats!.todayPatients.toString(),
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConsultationBreakdown() {
    if (_stats == null) return const SizedBox.shrink();

    // Mock data for consultation breakdown
    final onlineConsultations = 92;
    final offlineConsultations = 64;
    final totalConsultations = onlineConsultations + offlineConsultations;
    final onlinePercent = (onlineConsultations / totalConsultations * 100);
    final offlinePercent = (offlineConsultations / totalConsultations * 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consultation Breakdown',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Consultations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      totalConsultations.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ConsultationBar(
                  label: 'Online',
                  count: onlineConsultations,
                  percentage: onlinePercent,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 12),
                _ConsultationBar(
                  label: 'Offline',
                  count: offlineConsultations,
                  percentage: offlinePercent,
                  color: AppTheme.secondaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    if (_stats == null) return const SizedBox.shrink();

    // Calculate productivity score (0-100)
    final patientsScore = (_stats!.totalPatients / 200 * 100).clamp(0, 100).toDouble();
    final timeScore = (30 / _stats!.avgConsultationTime * 100).clamp(0, 100).toDouble();
    final ratingScore = (_stats!.satisfactionScore / 5 * 100);
    final overallScore = ((patientsScore + timeScore + ratingScore) / 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Score',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: CircularProgressIndicator(
                          value: overallScore / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getScoreColor(overallScore),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            overallScore.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(overallScore),
                                ),
                          ),
                          const Text(
                            'Score',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _ScoreIndicator(
                  label: 'Patient Volume',
                  score: patientsScore,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _ScoreIndicator(
                  label: 'Time Efficiency',
                  score: timeScore,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                _ScoreIndicator(
                  label: 'Patient Satisfaction',
                  score: ratingScore,
                  color: Colors.amber,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? suffix;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                if (suffix != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 2),
                    child: Text(
                      suffix!,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsultationBar extends StatelessWidget {
  final String label;
  final int count;
  final double percentage;
  final Color color;

  const _ConsultationBar({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '$count (${percentage.toStringAsFixed(0)}%)',
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
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _ScoreIndicator extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _ScoreIndicator({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 35,
          child: Text(
            '${score.toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
