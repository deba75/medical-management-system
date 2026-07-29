import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/doctor_dashboard_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import 'package:printing/printing.dart';
import '../../core/services/pdf_generator_service.dart';
import 'appointments/write_prescription_dialog.dart';
import 'chambers/manage_chambers_screen.dart';
import 'availability/manage_availability_screen.dart';
import 'search/patient_search_screen.dart';
import 'settings/settings_screen.dart';
import 'appointments/doctor_appointments_screen.dart';
import 'patient_records/request_access_screen.dart';
import '../patient/appointments/appointment_detail_screen.dart';

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Availability',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  void _showNotifications(BuildContext context) {
    final pendingAppointments = ref.read(doctorPendingAppointmentsProvider);
    final todayAppointments = ref.read(doctorTodayAppointmentsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _NotificationsSheet(
          scrollController: scrollController,
          pendingAppointments: pendingAppointments,
          todayAppointments: todayAppointments.value ?? [],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _DoctorProfileSheet(),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final doctorProfile = ref.watch(doctorProfileProvider);
    final dashboardStats = ref.watch(doctorDashboardStatsProvider);
    final todayAppointments = ref.watch(doctorTodayAppointmentsProvider);
    final pendingCount = dashboardStats.pendingAppointments;

    final doctorName = doctorProfile.value?.name ?? 'Doctor';
    final specialization = doctorProfile.value?.specialization ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Professional AppBar with Gradient
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getGreeting()}, Doctor 👋',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dr. $doctorName',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (specialization.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        specialization,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildHeaderIconButton(
                                  context,
                                  Icons.notifications_outlined,
                                  pendingCount,
                                  () => _showNotifications(context),
                                ),
                                const SizedBox(width: 8),
                                _buildHeaderIconButton(
                                  context,
                                  Icons.person_outline,
                                  0,
                                  () => _showProfileMenu(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Date display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'EEEE, MMMM dd, yyyy',
                                ).format(DateTime.now()),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: AppTheme.primaryColor,
          ),

          // Body Content
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(doctorProfileProvider);
                ref.invalidate(doctorAllAppointmentsProvider);
                ref.invalidate(doctorEarningsProvider);
                ref.invalidate(doctorChambersCountProvider);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    _buildStatsSection(context, dashboardStats),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActions(context),
                    const SizedBox(height: 24),

                    // Today's Schedule
                    _buildTodaySchedule(context, todayAppointments),
                    const SizedBox(height: 24),

                    // Performance Overview
                    _buildPerformanceSection(context, dashboardStats),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(
    BuildContext context,
    IconData icon,
    int badgeCount,
    VoidCallback onPressed,
  ) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, DoctorDashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today,
                iconColor: Colors.blue,
                backgroundColor: Colors.blue.withOpacity(0.1),
                borderColor: Colors.blue.withOpacity(0.3),
                value: stats.todayAppointments.toString(),
                label: 'Today',
                onTap: () {
                  // Navigate to today's appointments
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                backgroundColor: Colors.green.withOpacity(0.1),
                borderColor: Colors.green.withOpacity(0.3),
                value: stats.completedAppointments.toString(),
                label: 'Completed',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.schedule,
                iconColor: Colors.orange,
                backgroundColor: Colors.orange.withOpacity(0.1),
                borderColor: Colors.orange.withOpacity(0.3),
                value: stats.pendingAppointments.toString(),
                label: 'Pending',
                onTap: () {},
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
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _QuickActionCard(
              label: 'Manage\nAvailability',
              icon: Icons.event_available,
              color: AppTheme.primaryColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageAvailabilityScreen(),
                ),
              ),
            ),
            _QuickActionCard(
              label: 'View\nAppointments',
              icon: Icons.list_alt,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DoctorAppointmentsScreen(),
                ),
              ),
            ),
            _QuickActionCard(
              label: 'Manage\nChambers',
              icon: Icons.business,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageChambersScreen()),
              ),
            ),
            _QuickActionCard(
              label: 'Request\nPatient Access',
              icon: Icons.person_search,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestAccessScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaySchedule(
    BuildContext context,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Schedule',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorAppointmentsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        appointmentsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Error loading appointments',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          data: (appointments) {
            if (appointments.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.event_available,
                            size: 48,
                            color: AppTheme.primaryColor.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No appointments today',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enjoy your free day!',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondaryColor),
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
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AppointmentCard(
                    appointment: appointment,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentDetailScreen(
                            appointment: appointment,
                            isPatientView: false,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(
    BuildContext context,
    DoctorDashboardStats stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _PerformanceCard(
                icon: Icons.account_balance_wallet,
                label: 'Today\'s Earnings',
                value: '৳${stats.todayEarnings.toStringAsFixed(0)}',
                trend: '+12%',
                trendUp: true,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PerformanceCard(
                icon: Icons.business,
                label: 'Active Chambers',
                value: stats.chambersCount.toString(),
                trend: '',
                trendUp: true,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// Performance Card Widget
class _PerformanceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final bool trendUp;
  final Color color;

  const _PerformanceCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (trend.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: trendUp
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendUp ? Icons.trending_up : Icons.trending_down,
                          color: trendUp ? Colors.green : Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trend,
                          style: TextStyle(
                            color: trendUp ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
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

// Appointment Card Widget
class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;

  const _AppointmentCard({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = appointment.status == AppointmentStatus.completed;
    final bool isUpcoming = appointment.status == AppointmentStatus.upcoming;

    Color statusColor = Colors.orange;
    if (isCompleted) statusColor = Colors.green;
    if (isUpcoming) statusColor = AppTheme.primaryColor;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Patient Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),
              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appointment.timeSlot,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                    if (appointment.reason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        appointment.reason!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCompleted ? 'Done' : 'Upcoming',
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        tooltip: 'Verify Patient Appointment PDF',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: Text(
                                  'Appointment Slip #${appointment.appointmentId.substring(0, appointment.appointmentId.length > 8 ? 8 : appointment.appointmentId.length)}',
                                ),
                              ),
                              body: PdfPreview(
                                build: (format) =>
                                    PdfGeneratorService.generateAppointmentPdf(
                                      appointment,
                                    ),
                                canChangeOrientation: false,
                                canChangePageFormat: false,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => WritePrescriptionDialog(
                              appointment: appointment,
                            ),
                          );
                        },
                        icon: const Icon(Icons.medication, size: 14),
                        label: const Text(
                          'Prescribe',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    );
  }
}

// Notifications Sheet
class _NotificationsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final List<AppointmentModel> pendingAppointments;
  final List<AppointmentModel> todayAppointments;

  const _NotificationsSheet({
    required this.scrollController,
    required this.pendingAppointments,
    required this.todayAppointments,
  });

  @override
  Widget build(BuildContext context) {
    final allNotifications = [...pendingAppointments];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${allNotifications.length} pending appointments',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Mark all as read
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Notifications List
          Expanded(
            child: allNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.textSecondaryColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re all caught up!',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: allNotifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final appointment = allNotifications[index];
                      return _NotificationTile(appointment: appointment);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppointmentModel appointment;

  const _NotificationTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.schedule, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Appointment',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${appointment.patientName} - ${appointment.timeSlot}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                if (appointment.reason != null)
                  Text(
                    appointment.reason!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            color: Colors.green,
            onPressed: () {
              // Accept appointment
            },
          ),
        ],
      ),
    );
  }
}

// Doctor Profile Sheet
class _DoctorProfileSheet extends ConsumerWidget {
  const _DoctorProfileSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorProfile = ref.watch(doctorProfileProvider);
    final themeNotifier = ref.watch(themeModeProvider.notifier);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Profile Header
          doctorProfile.when(
            data: (doctor) => Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    doctor?.name.substring(0, 1).toUpperCase() ?? 'D',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Dr. ${doctor?.name ?? 'Doctor'}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    doctor?.specialization ?? 'Specialist',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${doctor?.rating.toStringAsFixed(1) ?? '0.0'} Rating',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Icon(Icons.error),
          ),
          const SizedBox(height: 24),

          // Menu Options
          _ProfileMenuTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                themeNotifier.toggleTheme();
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),

          _ProfileMenuTile(
            icon: Icons.person,
            title: 'Edit Profile',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile coming soon')),
              );
            },
          ),
          const SizedBox(height: 8),

          _ProfileMenuTile(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 8),

          _ProfileMenuTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon')),
              );
            },
          ),
          const SizedBox(height: 16),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && context.mounted) {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).colorScheme.surface,
    );
  }
}
