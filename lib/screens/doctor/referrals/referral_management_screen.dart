import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/referral_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/referral_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralManagementScreen extends ConsumerStatefulWidget {
  const ReferralManagementScreen({super.key});

  @override
  ConsumerState<ReferralManagementScreen> createState() => _ReferralManagementScreenState();
}

class _ReferralManagementScreenState extends ConsumerState<ReferralManagementScreen>
    with SingleTickerProviderStateMixin {
  final _referralService = ReferralService();
  final _doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Management'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Sent'),
            Tab(text: 'Received'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSentReferrals(),
          _buildReceivedReferrals(),
          _buildCompletedReferrals(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateReferralDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('New Referral'),
      ),
    );
  }

  Widget _buildSentReferrals() {
    return StreamBuilder<List<ReferralModel>>(
      stream: _referralService.getSentReferrals(_doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.send_outlined,
            title: 'No Sent Referrals',
            subtitle: 'Referrals you send to other doctors will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildReferralCard(snapshot.data![index], isSent: true);
          },
        );
      },
    );
  }

  Widget _buildReceivedReferrals() {
    return StreamBuilder<List<ReferralModel>>(
      stream: _referralService.getReceivedReferrals(_doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No Received Referrals',
            subtitle: 'Referrals from other doctors will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildReferralCard(snapshot.data![index], isSent: false);
          },
        );
      },
    );
  }

  Widget _buildCompletedReferrals() {
    return StreamBuilder<List<ReferralModel>>(
      stream: _referralService.getCompletedReferrals(_doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No Completed Referrals',
            subtitle: 'Completed referrals will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildReferralCard(snapshot.data![index], isCompleted: true);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard(
    ReferralModel referral, {
    bool isSent = false,
    bool isCompleted = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showReferralDetails(referral),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      referral.patientName.isNotEmpty
                          ? referral.patientName[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          referral.patientName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isSent
                              ? 'To: Dr. ${referral.referredDoctorName}'
                              : 'From: Dr. ${referral.referringDoctorName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildUrgencyBadge(referral.urgency ?? 'routine'),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason: ${referral.reason}',
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Specialty: ${referral.referredSpecialty}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusChip(referral.status),
                  const Spacer(),
                  Text(
                    _formatDate(referral.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (!isCompleted && !isSent && referral.status == 'pending') ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _declineReferral(referral),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptReferral(referral),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(String urgency) {
    Color color;
    switch (urgency.toLowerCase()) {
      case 'emergency':
        color = Colors.red;
        break;
      case 'urgent':
        color = Colors.orange;
        break;
      case 'routine':
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            urgency,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'declined':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'completed':
        color = Colors.blue;
        icon = Icons.done_all;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateReferralDialog() {
    final patientNameController = TextEditingController();
    final patientIdController = TextEditingController();
    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    String? selectedDoctorId;
    String? selectedDoctorName;
    String selectedSpecialty = 'General Medicine';
    String urgency = 'Routine';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Create Referral',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: patientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Patient Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: patientIdController,
                    decoration: const InputDecoration(
                      labelText: 'Patient ID (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedSpecialty,
                    decoration: const InputDecoration(
                      labelText: 'Specialty',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medical_services),
                    ),
                    items: [
                      'General Medicine',
                      'Cardiology',
                      'Dermatology',
                      'ENT',
                      'Gastroenterology',
                      'Neurology',
                      'Oncology',
                      'Ophthalmology',
                      'Orthopedics',
                      'Pediatrics',
                      'Psychiatry',
                      'Pulmonology',
                      'Surgery',
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (value) {
                      setModalState(() => selectedSpecialty = value!);
                    },
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('doctors')
                        .where('specialty', isEqualTo: selectedSpecialty)
                        .get(),
                    builder: (context, snapshot) {
                      final doctors = snapshot.data?.docs ?? [];
                      return DropdownButtonFormField<String>(
                        value: selectedDoctorId,
                        decoration: const InputDecoration(
                          labelText: 'Refer to Doctor',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_search),
                        ),
                        items: doctors.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text('Dr. ${data['name'] ?? 'Unknown'}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          final doc = doctors.firstWhere((d) => d.id == value);
                          final data = doc.data() as Map<String, dynamic>;
                          setModalState(() {
                            selectedDoctorId = value;
                            selectedDoctorName = data['name'];
                          });
                        },
                        hint: const Text('Select Doctor'),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Referral',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Urgency'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Routine', 'Urgent', 'Emergency'].map((u) {
                      return ChoiceChip(
                        label: Text(u),
                        selected: urgency == u,
                        onSelected: (selected) {
                          setModalState(() => urgency = u);
                        },
                        selectedColor: _getUrgencyColor(u).withValues(alpha: 0.2),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Notes (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (patientNameController.text.isEmpty ||
                            selectedDoctorId == null ||
                            reasonController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all required fields'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          // Get current doctor name
                          final doctorDoc = await FirebaseFirestore.instance
                              .collection('doctors')
                              .doc(_doctorId)
                              .get();
                          final fromDoctorName = doctorDoc.data()?['name'] ?? 'Unknown';

                          final referral = ReferralModel(
                            id: '',
                            referringDoctorId: _doctorId,
                            referringDoctorName: fromDoctorName,
                            referredDoctorId: selectedDoctorId!,
                            referredDoctorName: selectedDoctorName ?? '',
                            patientId: patientIdController.text.isNotEmpty
                                ? patientIdController.text
                                : 'unknown',
                            patientName: patientNameController.text,
                            reason: reasonController.text,
                            referredSpecialty: selectedSpecialty,
                            urgency: urgency,
                            status: 'pending',
                            clinicalNotes: notesController.text.isNotEmpty
                                ? notesController.text
                                : null,
                            createdAt: DateTime.now(),
                          );

                          await _referralService.createReferral(referral);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Referral sent successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Send Referral'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showReferralDetails(ReferralModel referral) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Referral Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Patient', referral.patientName),
              _buildDetailRow('From', 'Dr. ${referral.referringDoctorName}'),
              _buildDetailRow('To', 'Dr. ${referral.referredDoctorName}'),
              _buildDetailRow('Specialty', referral.referredSpecialty),
              _buildDetailRow('Reason', referral.reason),
              _buildDetailRow('Urgency', referral.urgency ?? 'routine'),
              _buildDetailRow('Status', referral.status),
              if (referral.clinicalNotes != null)
                _buildDetailRow('Notes', referral.clinicalNotes!),
              _buildDetailRow('Created', _formatDate(referral.createdAt)),
              if (referral.acceptedAt != null)
                _buildDetailRow('Accepted', _formatDate(referral.acceptedAt!)),
              if (referral.completedAt != null)
                _buildDetailRow('Completed', _formatDate(referral.completedAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (referral.status == 'accepted' && referral.referredDoctorId == _doctorId)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _completeReferral(referral);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Mark Complete'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _acceptReferral(ReferralModel referral) async {
    try {
      await _referralService.acceptReferral(referral.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral accepted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _declineReferral(ReferralModel referral) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Referral'),
        content: const Text('Are you sure you want to decline this referral?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _referralService.declineReferral(referral.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referral declined')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _completeReferral(ReferralModel referral) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Referral'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add completion notes:'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Treatment notes, outcome...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _referralService.completeReferral(
          referral.id,
          notesController.text.isNotEmpty ? notesController.text : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Referral marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'emergency':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
