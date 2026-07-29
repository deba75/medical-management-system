import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/appointment_model.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../../../core/services/prescription_pdf_service.dart';
import '../../doctor/appointments/write_prescription_dialog.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;
  final bool isPatientView;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
    this.isPatientView = false,
  });

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  bool _isUpdatingStatus = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointment.appointmentId)
          .snapshots(),
      builder: (context, snapshot) {
        AppointmentModel appointment = widget.appointment;
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          try {
            appointment = AppointmentModel.fromJson(
              snapshot.data!.data() as Map<String, dynamic>,
              snapshot.data!.id,
            );
          } catch (_) {}
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Appointment Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Booking Slip PDF',
                onPressed: () => PdfGeneratorService.showPdfPreview(context, appointment),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status).withOpacity(0.1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getStatusIcon(appointment.status),
                        color: _getStatusColor(appointment.status),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getStatusText(appointment.status),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _getStatusColor(appointment.status),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),

                // Doctor/Patient Info
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isPatientView ? 'Doctor Information' : 'Patient Information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: Text(
                              (widget.isPatientView
                                      ? appointment.doctorName
                                      : appointment.patientName)
                                  .split(' ')
                                  .where((e) => e.isNotEmpty)
                                  .map((e) => e[0])
                                  .take(2)
                                  .join(),
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isPatientView
                                      ? appointment.doctorName
                                      : appointment.patientName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (widget.isPatientView) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    appointment.specialization,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.primaryColor,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Appointment Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment Details',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      if (appointment.familyMemberName != null && appointment.familyMemberName!.isNotEmpty) ...[
                        _DetailRow(
                          icon: Icons.family_restroom,
                          label: 'Patient (Family Member)',
                          value: appointment.familyMemberName!,
                          valueColor: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: 'Date',
                        value: DateFormat('EEEE, MMM dd, yyyy').format(appointment.date),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.access_time,
                        label: 'Time',
                        value: appointment.timeSlot,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.info_outline,
                        label: 'Status',
                        value: appointment.status.name.toUpperCase(),
                        valueColor: _getStatusColor(appointment.status),
                      ),
                    ],
                  ),
                ),

                if (appointment.reason != null && appointment.reason!.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reason for Visit',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            appointment.reason!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 1),

                // E-Prescription Section
                _buildPrescriptionSection(context, appointment),

                const Divider(height: 1),

                // Actions Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Doctor Actions
                      if (!widget.isPatientView) ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => WritePrescriptionDialog(appointment: appointment),
                            );
                          },
                          icon: const Icon(Icons.medication),
                          label: Text(
                            appointment.status == AppointmentStatus.completed
                                ? 'Update / Write E-Prescription'
                                : 'Write E-Prescription',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (appointment.status == AppointmentStatus.upcoming) ...[
                          OutlinedButton.icon(
                            onPressed: _isUpdatingStatus ? null : () => _markAsCompleted(context, appointment),
                            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                            label: const Text('Mark as Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],

                      // Shared PDF & Cancel Actions
                      OutlinedButton.icon(
                        onPressed: () => PdfGeneratorService.showPdfPreview(context, appointment),
                        icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor),
                        label: const Text('View Booking Slip (PDF)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      if (appointment.status == AppointmentStatus.upcoming) ...[
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Cancel Appointment',
                          onPressed: () => _showCancelDialog(context, appointment),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionSection(BuildContext context, AppointmentModel appointment) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prescriptions')
          .where('appointmentId', isEqualTo: appointment.appointmentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isPatientView
                          ? 'No e-prescription issued yet for this appointment.'
                          : 'No e-prescription issued yet. Click "Write E-Prescription" below to create one.',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final pData = docs.first.data() as Map<String, dynamic>;
        final String? notes = pData['notes'];
        final List medicines = pData['medicines'] as List? ?? [];
        final List diagnosticTests = pData['diagnosticTests'] as List? ?? [];
        final bool isManual = pData['isManualPhoto'] ?? false;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'E-Prescription Attached',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ISSUED',
                        style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Medicines List
                if (medicines.isNotEmpty) ...[
                  const Text(
                    'Rx / Prescribed Medicines:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...medicines.map((m) {
                    final medMap = Map<String, dynamic>.from(m as Map);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medication, size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medMap['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Dosage: ${medMap['dosage']} | ${medMap['instruction']} | ${medMap['duration']}',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                ],

                // Diagnostic Tests
                if (diagnosticTests.isNotEmpty) ...[
                  const Text(
                    'Diagnostic Tests:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: diagnosticTests
                        .map((t) => Chip(
                              label: Text(t.toString(), style: const TextStyle(fontSize: 12)),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.blue.shade200),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Notes
                if (notes != null && notes.isNotEmpty) ...[
                  Text(
                    'Advice / Notes: $notes',
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                ],

                // View PDF / Photo Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _viewPrescriptionPdf(context, pData, appointment),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: Text(isManual ? 'View Handwritten Prescription' : 'View / Print E-Prescription PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _viewPrescriptionPdf(BuildContext context, Map<String, dynamic> pData, AppointmentModel appointment) async {
    final bool isManual = pData['isManualPhoto'] ?? false;
    final String? fileUrl = pData['fileURL'];

    if (isManual && fileUrl != null && fileUrl.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Prescription Image'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              InteractiveViewer(
                child: Image.network(fileUrl, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Generate digital PDF preview
    final medicinesList = (pData['medicines'] as List? ?? [])
        .map((e) => PrescribedMedicineItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final testsList = (pData['diagnosticTests'] as List? ?? []).map((e) => e.toString()).toList();

    final pdfBytes = await PrescriptionPdfService.generatePrescriptionPdf(
      prescriptionId: pData['prescriptionId'] ?? 'PRE-${appointment.appointmentId}',
      doctorName: pData['doctorName'] ?? appointment.doctorName,
      doctorSpecialization: appointment.specialization,
      doctorQualifications: 'MBBS',
      bmdcNumber: '',
      hospitalName: pData['hospital'] ?? 'MediConnect Hospital',
      patientName: appointment.patientName,
      patientAgeGender: 'Patient',
      date: appointment.date,
      medicines: medicinesList,
      diagnosticTests: testsList,
      clinicalNotes: pData['notes'] ?? '',
    );

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red),
                  const SizedBox(width: 10),
                  const Text('E-Prescription PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PdfPreview(
                build: (format) => pdfBytes,
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                initialPageFormat: PdfPageFormat.a4,
                pdfFileName: 'Prescription_${appointment.patientName.replaceAll(' ', '_')}.pdf',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsCompleted(BuildContext context, AppointmentModel appointment) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointment.appointmentId)
          .update({'status': 'completed'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment marked as Completed!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  void _showCancelDialog(BuildContext context, AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('appointments')
                    .doc(appointment.appointmentId)
                    .update({'status': 'cancelled'});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment cancelled.'), backgroundColor: Colors.orange),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.upcoming:
        return AppTheme.upcomingColor;
      case AppointmentStatus.completed:
        return AppTheme.completedColor;
      case AppointmentStatus.cancelled:
        return AppTheme.cancelledColor;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.upcoming:
        return Icons.schedule;
      case AppointmentStatus.completed:
        return Icons.check_circle;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.upcoming:
        return 'Upcoming Appointment';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color.fromARGB(255, 135, 130, 148),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
