import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientRecordsScreen extends ConsumerStatefulWidget {
  final String? patientId;
  final String? patientName;

  const PatientRecordsScreen({
    super.key,
    this.patientId,
    this.patientName,
  });

  @override
  ConsumerState<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends ConsumerState<PatientRecordsScreen>
    with SingleTickerProviderStateMixin {
  final _doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _searchController = TextEditingController();
  late TabController _tabController;
  String? _selectedPatientId;
  String? _selectedPatientName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedPatientId = widget.patientId;
    _selectedPatientName = widget.patientName;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedPatientName != null
            ? 'Records: $_selectedPatientName'
            : 'Patient Records'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        bottom: _selectedPatientId != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Appointments'),
                  Tab(text: 'Prescriptions'),
                  Tab(text: 'Lab Results'),
                ],
              )
            : null,
      ),
      body: _selectedPatientId == null
          ? _buildPatientSearch()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPatientOverview(),
                _buildAppointmentHistory(),
                _buildPrescriptionHistory(),
                _buildLabResults(),
              ],
            ),
    );
  }

  Widget _buildPatientSearch() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search patients by name or phone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _searchController.text.isEmpty
                ? FirebaseFirestore.instance
                    .collection('appointments')
                    .where('doctorId', isEqualTo: _doctorId)
                    .orderBy('appointmentDateTime', descending: true)
                    .limit(50)
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('patients')
                    .where('name', isGreaterThanOrEqualTo: _searchController.text)
                    .where('name', isLessThanOrEqualTo: '${_searchController.text}\uf8ff')
                    .limit(20)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No patients found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // Get unique patients from appointments
              if (_searchController.text.isEmpty) {
                final patientIds = <String>{};
                final uniqueDocs = <QueryDocumentSnapshot>[];
                
                for (final doc in snapshot.data!.docs) {
                  final patientId = doc.data() is Map ? (doc.data() as Map)['patientId'] as String? : null;
                  if (patientId != null && !patientIds.contains(patientId)) {
                    patientIds.add(patientId);
                    uniqueDocs.add(doc);
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: uniqueDocs.length,
                  itemBuilder: (context, index) {
                    final data = uniqueDocs[index].data() as Map<String, dynamic>;
                    return _buildPatientListTile(
                      data['patientId'] as String,
                      data['patientName'] as String? ?? 'Unknown',
                    );
                  },
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildPatientListTile(
                    doc.id,
                    data['name'] as String? ?? 'Unknown',
                    phone: data['phone'] as String?,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPatientListTile(String patientId, String name, {String? phone}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'P',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(name),
        subtitle: phone != null ? Text(phone) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          setState(() {
            _selectedPatientId = patientId;
            _selectedPatientName = name;
          });
        },
      ),
    );
  }

  Widget _buildPatientOverview() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('patients')
          .doc(_selectedPatientId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientInfoCard(data),
              const SizedBox(height: 16),
              _buildVitalsCard(),
              const SizedBox(height: 16),
              _buildMedicalHistoryCard(data),
              const SizedBox(height: 16),
              _buildAllergiesCard(data),
              const SizedBox(height: 16),
              _buildCurrentMedicationsCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientInfoCard(Map<String, dynamic> data) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    (_selectedPatientName ?? 'P')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPatientName ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_selectedPatientId?.substring(0, 8) ?? 'N/A'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {},
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.cake,
                  label: 'Age',
                  value: '${data['age'] ?? 'N/A'} years',
                ),
                _buildInfoItem(
                  icon: Icons.person,
                  label: 'Gender',
                  value: data['gender'] ?? 'N/A',
                ),
                _buildInfoItem(
                  icon: Icons.bloodtype,
                  label: 'Blood',
                  value: data['bloodGroup'] ?? 'N/A',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: data['phone'] ?? 'N/A',
                ),
                _buildInfoItem(
                  icon: Icons.email,
                  label: 'Email',
                  value: data['email'] ?? 'N/A',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Recent Vitals',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('Add Vitals'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildVitalItem(
                  icon: Icons.favorite,
                  label: 'BP',
                  value: '120/80',
                  unit: 'mmHg',
                  color: Colors.red,
                ),
                _buildVitalItem(
                  icon: Icons.monitor_heart,
                  label: 'Pulse',
                  value: '72',
                  unit: 'bpm',
                  color: Colors.orange,
                ),
                _buildVitalItem(
                  icon: Icons.thermostat,
                  label: 'Temp',
                  value: '98.6',
                  unit: '°F',
                  color: Colors.blue,
                ),
                _buildVitalItem(
                  icon: Icons.speed,
                  label: 'Weight',
                  value: '70',
                  unit: 'kg',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistoryCard(Map<String, dynamic> data) {
    final conditions = (data['medicalHistory'] as List<dynamic>?) ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medical History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (conditions.isEmpty)
              const Text('No medical history recorded')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: conditions.map((c) {
                  return Chip(
                    label: Text(c.toString()),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergiesCard(Map<String, dynamic> data) {
    final allergies = (data['allergies'] as List<dynamic>?) ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Allergies',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (allergies.isEmpty)
              const Text('No known allergies')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allergies.map((a) {
                  return Chip(
                    label: Text(a.toString()),
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    avatar: const Icon(Icons.warning, size: 16, color: Colors.red),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMedicationsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Medications',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('prescriptions')
                  .where('patientId', isEqualTo: _selectedPatientId)
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No current medications');
                }

                final prescriptions = snapshot.data!.docs;
                return Column(
                  children: prescriptions.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final medicines = (data['medicines'] as List<dynamic>?) ?? [];
                    return Column(
                      children: medicines.map((med) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.medication,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(med['name'] ?? 'Unknown'),
                          subtitle: Text(
                            '${med['dosage'] ?? ''} - ${med['frequency'] ?? ''}',
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: _doctorId)
          .where('patientId', isEqualTo: _selectedPatientId)
          .orderBy('appointmentDateTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No appointment history'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final date = (data['appointmentDateTime'] as Timestamp?)?.toDate();
            final status = data['status'] as String? ?? 'unknown';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                  ),
                ),
                title: Text(data['appointmentType'] ?? 'Consultation'),
                subtitle: Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
                      : 'Date not available',
                ),
                trailing: Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 10,
                    ),
                  ),
                  backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrescriptionHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prescriptions')
          .where('patientId', isEqualTo: _selectedPatientId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No prescription history'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final date = (data['createdAt'] as Timestamp?)?.toDate();
            final medicines = (data['medicines'] as List<dynamic>?) ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description, color: AppTheme.primaryColor),
                ),
                title: Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Date not available',
                ),
                subtitle: Text('${medicines.length} medications'),
                children: medicines.map((med) {
                  return ListTile(
                    title: Text(med['name'] ?? 'Unknown'),
                    subtitle: Text('${med['dosage'] ?? ''} - ${med['frequency'] ?? ''}'),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lab_test_bookings')
          .where('patientId', isEqualTo: _selectedPatientId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No lab results'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final date = (data['createdAt'] as Timestamp?)?.toDate();
            final status = data['status'] as String? ?? 'pending';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.science, color: Colors.purple),
                ),
                title: Text(data['centreName'] ?? 'Lab Test'),
                subtitle: Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Date not available',
                ),
                trailing: Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                onTap: data['reportUrl'] != null
                    ? () {
                        // Open report
                      }
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.event_available;
      default:
        return Icons.help_outline;
    }
  }
}
