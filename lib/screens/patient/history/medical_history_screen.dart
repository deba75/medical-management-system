import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/medical_history_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/medical_history_model.dart';

class MedicalHistoryScreen extends ConsumerWidget {
  const MedicalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(userMedicalHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showUploadDialog(context);
            },
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userMedicalHistoryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (history) => history.isEmpty
            ? EmptyStateWidget(
                icon: Icons.medical_information_outlined,
                title: 'No medical history',
                subtitle: 'Your medical records will appear here',
                actionText: 'Upload Report',
                onAction: () => _showUploadDialog(context),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userMedicalHistoryProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final record = history[index];
                    return _MedicalHistoryCard(record: record);
                  },
                ),
              ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Medical Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement camera
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement gallery picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Choose Document'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement file picker
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalHistoryCard extends StatelessWidget {
  final MedicalHistoryModel record;

  const _MedicalHistoryCard({required this.record});

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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medical_information,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.doctorName ?? 'Self Uploaded',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(record.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (record.diagnosis != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment,
                      size: 16,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Diagnosis: ${record.diagnosis}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              record.notes,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (record.medicines.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Medicines',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              ...record.medicines.map((medicine) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.medication,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          medicine,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )),
            ],
            if (record.reportsURLs.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${record.reportsURLs.length} report(s) attached',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // TODO: View reports
                    },
                    child: const Text('View'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
