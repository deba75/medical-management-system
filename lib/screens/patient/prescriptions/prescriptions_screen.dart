import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/prescription_model.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);

    // TODO: Fetch from Firestore
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    _prescriptions = [
      PrescriptionModel(
        prescriptionId: '1',
        appointmentId: '1',
        doctorId: '1',
        patientId: 'current_user',
        doctorName: 'Dr. Sarah Johnson',
        fileURL: 'mock_url',
        notes: 'Take medicines after meals. Complete the course.',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      PrescriptionModel(
        prescriptionId: '2',
        appointmentId: '2',
        doctorId: '2',
        patientId: 'current_user',
        doctorName: 'Dr. Michael Chen',
        fileURL: 'mock_url',
        notes: 'Apply cream twice daily for 2 weeks.',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.receipt_long_outlined,
                  title: 'No prescriptions',
                  subtitle: 'Prescriptions from your doctors will appear here',
                )
              : RefreshIndicator(
                  onRefresh: _loadPrescriptions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _prescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription = _prescriptions[index];
                      return _PrescriptionCard(
                        prescription: prescription,
                        onView: () {
                          // TODO: View prescription
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening prescription...'),
                            ),
                          );
                        },
                        onDownload: () {
                          // TODO: Download prescription
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Downloading prescription...'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final PrescriptionModel prescription;
  final VoidCallback onView;
  final VoidCallback onDownload;

  const _PrescriptionCard({
    required this.prescription,
    required this.onView,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prescription.doctorName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(prescription.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ) ?? const TextStyle(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (prescription.notes != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  prescription.notes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
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
