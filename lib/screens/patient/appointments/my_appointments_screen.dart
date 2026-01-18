import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/providers/appointment_provider.dart';
import '../../../models/appointment_model.dart';
import 'appointment_detail_screen.dart';

class MyAppointmentsScreen extends ConsumerStatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  ConsumerState<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends ConsumerState<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AppointmentModel> _getFilteredAppointments(
      List<AppointmentModel> appointments, AppointmentStatus? status) {
    if (status == null) return appointments;
    return appointments.where((apt) => apt.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(userAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: appointmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading appointments'),
              TextButton(
                onPressed: () => ref.invalidate(userAppointmentsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (appointments) => TabBarView(
          controller: _tabController,
          children: [
            _AppointmentsList(
              appointments: _getFilteredAppointments(appointments, null),
              emptyMessage: 'No appointments yet',
            ),
            _AppointmentsList(
              appointments:
                  _getFilteredAppointments(appointments, AppointmentStatus.upcoming),
              emptyMessage: 'No upcoming appointments',
            ),
            _AppointmentsList(
              appointments:
                  _getFilteredAppointments(appointments, AppointmentStatus.completed),
              emptyMessage: 'No completed appointments',
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentsList extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final String emptyMessage;

  const _AppointmentsList({
    required this.appointments,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.calendar_month_outlined,
        title: emptyMessage,
        subtitle: 'Book an appointment with a doctor to get started',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh appointments
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _AppointmentCard(
            appointment: appointment,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentDetailScreen(
                    appointment: appointment,
                    isPatientView: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      appointment.doctorName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusChip(status: appointment.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                appointment.specialization,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(appointment.date),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 24),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appointment.timeSlot,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (appointment.reason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment.reason!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
