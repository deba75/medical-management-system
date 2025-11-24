import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/appointment_model.dart';
import '../../patient/appointments/appointment_detail_screen.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    _appointments = [
      AppointmentModel(
        appointmentId: '1',
        doctorId: 'current_doctor',
        patientId: '1',
        doctorName: 'Dr. Current',
        patientName: 'John Doe',
        specialization: 'Cardiologist',
        date: DateTime.now().add(const Duration(days: 1)),
        timeSlotId: '1',
        timeSlot: '09:00 - 09:30',
        status: AppointmentStatus.upcoming,
      ),
      AppointmentModel(
        appointmentId: '2',
        doctorId: 'current_doctor',
        patientId: '2',
        doctorName: 'Dr. Current',
        patientName: 'Jane Smith',
        specialization: 'Cardiologist',
        date: DateTime.now().subtract(const Duration(days: 7)),
        timeSlotId: '4',
        timeSlot: '10:30 - 11:00',
        status: AppointmentStatus.completed,
      ),
    ];

    setState(() => _isLoading = false);
  }

  List<AppointmentModel> _getFilteredAppointments(AppointmentStatus status) {
    return _appointments.where((apt) => apt.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _AppointmentsList(
                  appointments:
                      _getFilteredAppointments(AppointmentStatus.upcoming),
                  emptyMessage: 'No upcoming appointments',
                ),
                _AppointmentsList(
                  appointments:
                      _getFilteredAppointments(AppointmentStatus.completed),
                  emptyMessage: 'No completed appointments',
                ),
              ],
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
        subtitle: 'Appointments will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
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
                          appointment.patientName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      StatusChip(status: appointment.status),
                    ],
                  ),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
