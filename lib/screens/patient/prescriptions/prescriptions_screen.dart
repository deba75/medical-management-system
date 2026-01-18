import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/providers/prescription_provider.dart';
import '../../../models/prescription_model.dart';

class PrescriptionsScreen extends ConsumerWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionsAsync = ref.watch(userPrescriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
      ),
      body: prescriptionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading prescriptions'),
              TextButton(
                onPressed: () => ref.invalidate(userPrescriptionsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (prescriptions) => prescriptions.isEmpty
            ? const EmptyStateWidget(
                icon: Icons.receipt_long_outlined,
                title: 'No prescriptions',
                subtitle: 'Prescriptions from your doctors will appear here',
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userPrescriptionsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = prescriptions[index];
                    return _PrescriptionCard(
                      prescription: prescription,
                      onView: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening prescription...'),
                          ),
                        );
                      },
                      onDownload: () {
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
