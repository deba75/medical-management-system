import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/providers/appointment_provider.dart';
import '../../../models/appointment_model.dart';
import 'appointment_detail_screen.dart';
import '../doctors/search_doctors_screen.dart';

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (status == null) {
      // All tab - show only current/future upcoming appointments (exclude past ones)
      final filtered = appointments.where((apt) {
        final aptDate = DateTime(apt.date.year, apt.date.month, apt.date.day);
        // Show if: upcoming and date is today or future, OR status is not completed/cancelled
        return apt.status == AppointmentStatus.upcoming && 
               (aptDate.isAtSameMomentAs(today) || aptDate.isAfter(today));
      }).toList();
      filtered.sort((a, b) => a.date.compareTo(b.date)); // Sort ascending
      return filtered;
    }
    
    if (status == AppointmentStatus.upcoming) {
      // Only show appointments that are today or in the future AND have upcoming status
      return appointments.where((apt) {
        final aptDate = DateTime(apt.date.year, apt.date.month, apt.date.day);
        return apt.status == AppointmentStatus.upcoming && 
               (aptDate.isAtSameMomentAs(today) || aptDate.isAfter(today));
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date)); // Sort ascending for upcoming
    }
    
    if (status == AppointmentStatus.completed) {
      // Show completed appointments AND past appointments that were "upcoming" but date passed
      return appointments.where((apt) {
        final aptDate = DateTime(apt.date.year, apt.date.month, apt.date.day);
        return apt.status == AppointmentStatus.completed ||
               (apt.status == AppointmentStatus.upcoming && aptDate.isBefore(today));
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Sort descending for completed
    }
    
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchDoctorsScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Book Appointment',
          style: TextStyle(color: Colors.white),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      appointment.specialization,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                    ),
                  ),
                  // Payment Status Badge
                  _buildPaymentBadge(context),
                ],
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
              // Consultation Fee Row
              if (appointment.consultationFee != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '৳${appointment.consultationFee!.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appointment.paymentMethod == PaymentMethod.online
                          ? '(Paid Online)'
                          : '(Pay at Clinic)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
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

  Widget _buildPaymentBadge(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    switch (appointment.paymentStatus) {
      case PaymentStatus.completed:
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        text = 'Paid';
        icon = Icons.check_circle;
        break;
      case PaymentStatus.pending:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        text = 'Unpaid';
        icon = Icons.schedule;
        break;
      case PaymentStatus.failed:
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        text = 'Failed';
        icon = Icons.error;
        break;
      case PaymentStatus.refunded:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        text = 'Refunded';
        icon = Icons.replay;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
