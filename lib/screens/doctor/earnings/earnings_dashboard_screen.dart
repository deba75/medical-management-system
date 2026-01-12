import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/chamber_model.dart';

class EarningsDashboardScreen extends StatefulWidget {
  const EarningsDashboardScreen({super.key});

  @override
  State<EarningsDashboardScreen> createState() => _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState extends State<EarningsDashboardScreen> {
  DoctorEarnings? _todayEarnings;
  List<DoctorEarnings> _monthlyEarnings = [];
  bool _isLoading = false;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);
    
    // TODO: Fetch from Firebase
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data
    _todayEarnings = DoctorEarnings(
      id: '1',
      doctorId: 'doc1',
      date: DateTime.now(),
      onlineEarnings: 4500,
      offlineEarnings: 6000,
      onlineConsultations: 3,
      offlineConsultations: 4,
    );
    
    _monthlyEarnings = List.generate(30, (index) {
      final date = DateTime.now().subtract(Duration(days: 30 - index));
      return DoctorEarnings(
        id: index.toString(),
        doctorId: 'doc1',
        date: date,
        onlineEarnings: (index * 100 + 500).toDouble(),
        offlineEarnings: (index * 150 + 700).toDouble(),
        onlineConsultations: index % 5 + 1,
        offlineConsultations: index % 4 + 2,
      );
    });
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodayEarnings(),
                    const SizedBox(height: 24),
                    _buildMonthlyOverview(),
                    const SizedBox(height: 24),
                    _buildEarningsChart(),
                    const SizedBox(height: 24),
                    _buildMonthlyList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTodayEarnings() {
    if (_todayEarnings == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Earnings',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _EarningCard(
                        icon: Icons.computer,
                        label: 'Online',
                        amount: _todayEarnings!.onlineEarnings,
                        consultations: _todayEarnings!.onlineConsultations,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _EarningCard(
                        icon: Icons.person,
                        label: 'Offline',
                        amount: _todayEarnings!.offlineEarnings,
                        consultations: _todayEarnings!.offlineConsultations,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Today',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '৳${_todayEarnings!.totalEarnings.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${_todayEarnings!.totalConsultations} consultations',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyOverview() {
    if (_monthlyEarnings.isEmpty) return const SizedBox.shrink();

    final totalOnline = _monthlyEarnings.fold<double>(
      0,
      (sum, item) => sum + item.onlineEarnings,
    );
    final totalOffline = _monthlyEarnings.fold<double>(
      0,
      (sum, item) => sum + item.offlineEarnings,
    );
    final totalConsultations = _monthlyEarnings.fold<int>(
      0,
      (sum, item) => sum + item.totalConsultations,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: AppTheme.primaryColor,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Total Revenue',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '৳${(totalOnline + totalOffline).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '৳${totalOnline.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Offline',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '৳${totalOffline.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Patients',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalConsultations.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: _SimpleBarChart(earnings: _monthlyEarnings.take(7).toList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Breakdown',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _monthlyEarnings.length,
          itemBuilder: (context, index) {
            final earning = _monthlyEarnings[_monthlyEarnings.length - 1 - index];
            return _DailyEarningTile(earning: earning);
          },
        ),
      ],
    );
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedMonth = picked);
      _loadEarnings();
    }
  }
}

class _EarningCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final int consultations;
  final Color color;

  const _EarningCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.consultations,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '৳${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            '$consultations consultations',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _DailyEarningTile extends StatelessWidget {
  final DoctorEarnings earning;

  const _DailyEarningTile({required this.earning});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                earning.date.day.toString(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                DateFormat('MMM').format(earning.date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
              ),
            ],
          ),
        ),
        title: Text('৳${earning.totalEarnings.toStringAsFixed(0)}'),
        subtitle: Text(
          'Online: ৳${earning.onlineEarnings.toStringAsFixed(0)} | Offline: ৳${earning.offlineEarnings.toStringAsFixed(0)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${earning.totalConsultations}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'patients',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<DoctorEarnings> earnings;

  const _SimpleBarChart({required this.earnings});

  @override
  Widget build(BuildContext context) {
    if (earnings.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxEarning = earnings
        .map((e) => e.totalEarnings)
        .reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: earnings.map((earning) {
        final heightRatio = earning.totalEarnings / maxEarning;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 160 * heightRatio,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('E').format(earning.date).substring(0, 1),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
