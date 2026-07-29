import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';

class AdminVerificationScreen extends ConsumerStatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  ConsumerState<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends ConsumerState<AdminVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  Future<void> _updateDoctorStatus(String doctorId, String status, {String? reason}) async {
    try {
      await FirebaseFirestore.instance.collection('doctors').doc(doctorId).update({
        'verificationStatus': status,
        'active': status == 'approved',
        if (reason != null) 'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Doctor status updated to $status'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateDiagnosticCentreStatus(String centreId, String status, {String? reason}) async {
    try {
      await FirebaseFirestore.instance.collection('diagnostic_centres').doc(centreId).update({
        'verificationStatus': status,
        'status': status == 'approved' ? 'active' : 'inactive',
        if (reason != null) 'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diagnostic Centre status updated to $status'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRejectDialog(String id, bool isDoctor) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Verification Request'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for Rejection',
            hintText: 'Enter specific details (e.g. invalid BMDC or DGHS code)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(context);
              if (isDoctor) {
                _updateDoctorStatus(id, 'rejected', reason: reason);
              } else {
                _updateDiagnosticCentreStatus(id, 'rejected', reason: reason);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Verification Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.biotech_rounded), text: 'Diagnostic Centres'),
            Tab(icon: Icon(Icons.medical_services_rounded), text: 'Doctors'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiagnosticCentresTab(),
          _buildDoctorsTab(),
        ],
      ),
    );
  }

  Widget _buildDiagnosticCentresTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('diagnostic_centres').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No Diagnostic Centre verification requests found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            final name = data['name'] ?? 'Unnamed Centre';
            final dghsCode = data['dghsCode'] ?? 'N/A';
            final pathologistName = data['pathologistName'] ?? 'N/A';
            final pathologistBmdc = data['pathologistBmdcNumber'] ?? 'N/A';
            final status = data['verificationStatus'] ?? 'pending';
            final city = data['city'] ?? '';
            final phone = data['contactNumber'] ?? '';

            Color statusColor;
            switch (status) {
              case 'approved':
                statusColor = Colors.green;
                break;
              case 'rejected':
                statusColor = Colors.red;
                break;
              default:
                statusColor = Colors.orange;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
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
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Verification Data
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_hospital, size: 18, color: Colors.purple),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('DGHS Registration Code: $dghsCode', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.badge, size: 18, color: Colors.purple),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Pathologist: $pathologistName (BMDC: $pathologistBmdc)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Location: $city • Contact: $phone', style: const TextStyle(color: Colors.grey, fontSize: 13)),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status != 'rejected')
                          OutlinedButton.icon(
                            onPressed: () => _showRejectDialog(id, false),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Reject', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        const SizedBox(width: 12),
                        if (status != 'approved')
                          ElevatedButton.icon(
                            onPressed: () => _updateDiagnosticCentreStatus(id, 'approved'),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('Approve', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDoctorsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No Doctor verification requests found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            final name = data['name'] ?? 'Unnamed Doctor';
            final bmdcNumber = data['bmdcNumber'] ?? 'N/A';
            final specialization = data['specialization'] ?? '';
            final status = data['verificationStatus'] ?? 'pending';
            final phone = data['phone'] ?? '';

            Color statusColor;
            switch (status) {
              case 'approved':
                statusColor = Colors.green;
                break;
              case 'rejected':
                statusColor = Colors.red;
                break;
              default:
                statusColor = Colors.orange;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
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
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('BMDC Registration Number: $bmdcNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Specialization: $specialization • Phone: $phone', style: const TextStyle(color: Colors.grey, fontSize: 13)),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status != 'rejected')
                          OutlinedButton.icon(
                            onPressed: () => _showRejectDialog(id, true),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Reject', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        const SizedBox(width: 12),
                        if (status != 'approved')
                          ElevatedButton.icon(
                            onPressed: () => _updateDoctorStatus(id, 'approved'),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('Approve', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
