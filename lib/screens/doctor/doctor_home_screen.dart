import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/doctor_dashboard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import 'chambers/manage_chambers_screen.dart';
import 'earnings/earnings_dashboard_screen.dart';
import 'availability/manage_availability_screen.dart';
import 'productivity/productivity_dashboard_screen.dart';
import 'search/patient_search_screen.dart';
import 'settings/settings_screen.dart';

class DoctorHomeScreen extends ConsumerStatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  ConsumerState<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const _HomeTab(),
    const ManageAvailabilityScreen(),
    const PatientSearchScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Availability',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorProfile = ref.watch(doctorProfileProvider);
    final dashboardStats = ref.watch(doctorDashboardStatsProvider);
    final todayAppointments = ref.watch(doctorTodayAppointmentsProvider);

    final doctorName = doctorProfile.value?.name ?? 'Doctor';
    final specialization = doctorProfile.value?.specialization ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dr. $doctorName',
              style: const TextStyle(fontSize: 18),
            ),
            if (specialization.isNotEmpty)
              Text(
                specialization,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(doctorProfileProvider);
          ref.refresh(doctorTodayAppointmentsProvider);
          ref.refresh(doctorPendingAppointmentsProvider);
          ref.refresh(doctorEarningsProvider);
          ref.refresh(doctorChambersCountProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(context, doctorName),
            const SizedBox(height: 20),
            _buildQuickStats(context, dashboardStats),
            const SizedBox(height: 20),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            _buildTodaySchedule(context, todayAppointments),
            const SizedBox(height: 20),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String doctorName) {
    return Card(
      color: AppTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctorName.split(' ').last,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, DoctorDashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickStatCard(
                icon: Icons.event,
                label: 'Appointments',
                value: stats.todayAppointments.toString(),
                color: Colors.blue,
                onTap: () {
                  // TODO: Navigate to appointments
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickStatCard(
                icon: Icons.schedule,
                label: 'Pending',
                value: stats.pendingAppointments.toString(),
                color: Colors.orange,
                onTap: () {
                  // TODO: Navigate to pending appointments
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickStatCard(
                icon: Icons.account_balance_wallet,
                label: 'Earnings',
                value: '৳${stats.todayEarnings.toStringAsFixed(0)}',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EarningsDashboardScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickStatCard(
                icon: Icons.business,
                label: 'Chambers',
                value: stats.chambersCount.toString(),
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageChambersScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.calendar_month,
                label: 'Manage\nAvailability',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageAvailabilityScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.trending_up,
                label: 'Productivity\nIndex',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductivityDashboardScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.search,
                label: 'Search\nPatient',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientSearchScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.business,
                label: 'Manage\nChambers',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageChambersScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaySchedule(
      BuildContext context, AsyncValue<List<AppointmentModel>> appointmentsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Schedule',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                // TODO: View full schedule
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        appointmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (appointments) {
            if (appointments.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 48,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No appointments today',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: appointments.take(3).map((appointment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AppointmentCard(
                    patientName: appointment.patientName,
                    time: DateFormat('hh:mm a').format(appointment.date),
                    type: 'Offline',
                    chamber: appointment.hospitalName ?? 'N/A',
                    status: appointment.status == AppointmentStatus.completed ? 'Completed' : 'Upcoming',
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Recent activities will appear here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final String patientName;
  final String time;
  final String type;
  final String chamber;
  final String status;

  const _AppointmentCard({
    required this.patientName,
    required this.time,
    required this.type,
    required this.chamber,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = status == 'Completed';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.access_time,
                color: isCompleted ? Colors.green : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        type == 'Online' ? Icons.computer : Icons.person,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$type · $chamber',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      color: isCompleted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
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

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
      ),
    );
  }
}
