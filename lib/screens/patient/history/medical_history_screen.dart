import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/family_member_selector.dart';
import '../../../core/providers/family_member_provider.dart';

class MedicalHistoryScreen extends ConsumerStatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  ConsumerState<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends ConsumerState<MedicalHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Auto History'),
            Tab(text: 'My Records'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAutoHistoryTab(),
          _buildManualHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHistoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add History'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  // Auto History - from appointments
  Widget _buildAutoHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointments = snapshot.data?.docs ?? [];
        
        if (appointments.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.history_outlined,
            title: 'No visit history',
            subtitle: 'Your completed appointments will appear here automatically',
          );
        }

        // Sort by date (newest first)
        appointments.sort((a, b) {
          final dateA = _parseDateTime(a.data() as Map<String, dynamic>);
          final dateB = _parseDateTime(b.data() as Map<String, dynamic>);
          return dateB.compareTo(dateA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final data = appointments[index].data() as Map<String, dynamic>;
            return _AutoHistoryCard(
              data: data,
              appointmentId: appointments[index].id,
              onTap: () => _showAutoHistoryDetails(context, data, appointments[index].id),
            );
          },
        );
      },
    );
  }

  DateTime _parseDateTime(Map<String, dynamic> data) {
    final date = data['date'];
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  // Manual History - added by patient
  Widget _buildManualHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medicalHistory')
          .where('patientId', isEqualTo: _currentUserId)
          .where('isManual', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data?.docs ?? [];
        
        if (records.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.note_add_outlined,
            title: 'No manual records',
            subtitle: 'Add your past medical records here',
            actionText: 'Add History',
            onAction: () => _showAddHistoryDialog(context),
          );
        }

        // Sort by date (newest first)
        records.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final dateA = _parseCreatedAt(dataA['createdAt']);
          final dateB = _parseCreatedAt(dataB['createdAt']);
          return dateB.compareTo(dateA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final data = records[index].data() as Map<String, dynamic>;
            return _ManualHistoryCard(
              data: data,
              recordId: records[index].id,
              onTap: () => _showManualHistoryDetails(context, data, records[index].id),
              onDelete: () => _deleteRecord(records[index].id),
            );
          },
        );
      },
    );
  }

  DateTime _parseCreatedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  void _showAddHistoryDialog(BuildContext context) {
    final doctorNameController = TextEditingController();
    final hospitalController = TextEditingController();
    final diagnosisController = TextEditingController();
    final notesController = TextEditingController();
    final medicinesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Add Medical History',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add details about your past medical visits',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // Family Member Selector
                const FamilyMemberSelector(showAddButton: false),
                const SizedBox(height: 16),

                // Date Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  ),
                  title: const Text('Visit Date'),
                  subtitle: Text(DateFormat('MMMM dd, yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setModalState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Doctor Name
                TextField(
                  controller: doctorNameController,
                  decoration: InputDecoration(
                    labelText: 'Doctor Name *',
                    hintText: 'e.g., Dr. John Smith',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Hospital/Clinic
                TextField(
                  controller: hospitalController,
                  decoration: InputDecoration(
                    labelText: 'Hospital/Clinic',
                    hintText: 'e.g., City Hospital',
                    prefixIcon: const Icon(Icons.local_hospital),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Diagnosis
                TextField(
                  controller: diagnosisController,
                  decoration: InputDecoration(
                    labelText: 'Diagnosis',
                    hintText: 'e.g., Common Cold, Fever',
                    prefixIcon: const Icon(Icons.medical_information),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Medicines
                TextField(
                  controller: medicinesController,
                  decoration: InputDecoration(
                    labelText: 'Medicines (comma separated)',
                    hintText: 'e.g., Paracetamol, Vitamin C',
                    prefixIcon: const Icon(Icons.medication),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Any additional notes...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Icon(Icons.notes),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (doctorNameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter doctor name'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        final medicines = medicinesController.text.isNotEmpty
                            ? medicinesController.text.split(',').map((e) => e.trim()).toList()
                            : <String>[];

                        final selectedFamilyMember = ref.read(selectedFamilyMemberProvider);

                        await FirebaseFirestore.instance.collection('medicalHistory').add({
                          'patientId': _currentUserId,
                          'familyMemberId': selectedFamilyMember?.id,
                          'familyMemberName': selectedFamilyMember?.name,
                          'doctorName': doctorNameController.text,
                          'hospital': hospitalController.text,
                          'diagnosis': diagnosisController.text,
                          'medicines': medicines,
                          'notes': notesController.text,
                          'visitDate': selectedDate.toIso8601String(),
                          'createdAt': FieldValue.serverTimestamp(),
                          'isManual': true,
                        });

                        ref.read(selectedFamilyMemberProvider.notifier).state = null;

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('History added successfully!'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                          // Switch to My Records tab
                          _tabController.animateTo(1);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save History',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAutoHistoryDetails(BuildContext context, Map<String, dynamic> data, String appointmentId) {
    final date = _parseDateTime(data);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.history, color: AppTheme.primaryColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visit Details',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          DateFormat('MMMM dd, yyyy').format(date),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Doctor Info
              _buildDetailRow(context, Icons.person, 'Doctor', data['doctorName'] ?? 'N/A'),
              _buildDetailRow(context, Icons.medical_services, 'Specialization', data['specialization'] ?? 'N/A'),
              _buildDetailRow(context, Icons.local_hospital, 'Hospital/Clinic', data['chamberName'] ?? data['location'] ?? 'N/A'),
              _buildDetailRow(context, Icons.access_time, 'Time Slot', data['timeSlot'] ?? 'N/A'),
              _buildDetailRow(context, Icons.medical_information, 'Type', 'In-Person Visit'),
              
              if (data['symptoms'] != null && (data['symptoms'] as String).isNotEmpty)
                _buildDetailRow(context, Icons.sick, 'Symptoms', data['symptoms']),
              
              if (data['notes'] != null && (data['notes'] as String).isNotEmpty)
                _buildDetailRow(context, Icons.notes, 'Notes', data['notes']),

              const SizedBox(height: 24),
              
              // Check if prescription exists
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('prescriptions')
                    .where('appointmentId', isEqualTo: appointmentId)
                    .snapshots(),
                builder: (context, snapshot) {
                  final prescriptions = snapshot.data?.docs ?? [];
                  if (prescriptions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('No prescription available for this visit'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Prescription available'),
                        ),
                        TextButton(
                          onPressed: () {
                            // View prescription
                          },
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualHistoryDetails(BuildContext context, Map<String, dynamic> data, String recordId) {
    final visitDate = _parseCreatedAt(data['visitDate'] ?? data['createdAt']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.note_alt, color: Colors.teal, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Record',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          DateFormat('MMMM dd, yyyy').format(visitDate),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteRecord(recordId);
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Details
              _buildDetailRow(context, Icons.person, 'Doctor', data['doctorName'] ?? 'N/A'),
              if (data['hospital'] != null && (data['hospital'] as String).isNotEmpty)
                _buildDetailRow(context, Icons.local_hospital, 'Hospital/Clinic', data['hospital']),
              if (data['diagnosis'] != null && (data['diagnosis'] as String).isNotEmpty)
                _buildDetailRow(context, Icons.medical_information, 'Diagnosis', data['diagnosis']),
              
              // Medicines
              if (data['medicines'] != null && (data['medicines'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Medicines',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (data['medicines'] as List).map((medicine) {
                    return Chip(
                      avatar: const Icon(Icons.medication, size: 16),
                      label: Text(medicine.toString()),
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    );
                  }).toList(),
                ),
              ],
              
              if (data['notes'] != null && (data['notes'] as String).isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDetailRow(context, Icons.notes, 'Notes', data['notes']),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecord(String recordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('medicalHistory').doc(recordId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Record deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// Auto History Card
class _AutoHistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String appointmentId;
  final VoidCallback onTap;

  const _AutoHistoryCard({
    required this.data,
    required this.appointmentId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = _parseDate(data['date']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.event_available, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['doctorName'] ?? 'Doctor',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['specialization'] ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(date),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

// Manual History Card
class _ManualHistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String recordId;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ManualHistoryCard({
    required this.data,
    required this.recordId,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final visitDate = _parseDate(data['visitDate'] ?? data['createdAt']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.note_alt, color: Colors.teal),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['doctorName'] ?? 'Doctor',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (data['familyMemberName'] != null && (data['familyMemberName'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'Patient: ${data['familyMemberName']}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (data['hospital'] != null && (data['hospital'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        data['hospital'],
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                    if (data['diagnosis'] != null && (data['diagnosis'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        data['diagnosis'],
                        style: TextStyle(color: Colors.teal[700], fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(visitDate),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Manual',
                  style: TextStyle(
                    color: Colors.teal[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
