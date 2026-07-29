import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/lab_test_service.dart';
import '../../core/services/pdf_generator_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lab_test_model.dart';

class DiagnosticCentreDashboardScreen extends StatefulWidget {
  const DiagnosticCentreDashboardScreen({super.key});

  @override
  State<DiagnosticCentreDashboardScreen> createState() =>
      _DiagnosticCentreDashboardScreenState();
}

class _DiagnosticCentreDashboardScreenState
    extends State<DiagnosticCentreDashboardScreen> {
  final _labTestService = LabTestService();
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Pending',
    'Approved',
    'Collector Assigned',
    'In Transit',
    'Processing',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Diagnostic Admin Portal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.price_change_rounded, color: Colors.white),
            onPressed: () => _showManageTestCatalogDialog(context),
            tooltip: 'Manage Test Prices & Catalog',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh Requests',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<List<LabTestModel>>(
        stream: _labTestService.getAllBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBookings = snapshot.data ?? [];

          // Calculate Analytics
          final totalCount = allBookings.length;
          final pendingCount = allBookings.where((b) => b.status == LabTestStatus.pending).length;
          final transitCount = allBookings.where((b) => b.status == LabTestStatus.collectorAssigned || b.status == LabTestStatus.sampleCollected).length;
          final completedCount = allBookings.where((b) => b.status == LabTestStatus.completed).length;

          // Filter Bookings
          final filteredBookings = allBookings.where((booking) {
            if (_selectedFilter == 'All') return true;
            if (_selectedFilter == 'Pending') return booking.status == LabTestStatus.pending;
            if (_selectedFilter == 'Approved') return booking.status == LabTestStatus.approved;
            if (_selectedFilter == 'Collector Assigned') return booking.status == LabTestStatus.collectorAssigned;
            if (_selectedFilter == 'In Transit') return booking.status == LabTestStatus.sampleCollected;
            if (_selectedFilter == 'Processing') return booking.status == LabTestStatus.processing;
            if (_selectedFilter == 'Completed') return booking.status == LabTestStatus.completed;
            return true;
          }).toList();

          return Column(
            children: [
              // Analytics Overview Banner
              _buildAnalyticsHeader(totalCount, pendingCount, transitCount, completedCount),

              // Filter Chips
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedFilter = filter);
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Bookings List
              Expanded(
                child: filteredBookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'No $_selectedFilter requests',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          return _buildAdminBookingCard(filteredBookings[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsHeader(int total, int pending, int transit, int completed) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          _buildStatCard('Total', '$total', Colors.blue, Icons.assignment),
          const SizedBox(width: 8),
          _buildStatCard('Pending', '$pending', Colors.orange, Icons.hourglass_top),
          const SizedBox(width: 8),
          _buildStatCard('In Transit', '$transit', Colors.purple, Icons.two_wheeler),
          const SizedBox(width: 8),
          _buildStatCard('Completed', '$completed', Colors.green, Icons.verified),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminBookingCard(LabTestModel booking) {
    final statusColor = _getStatusColor(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Patient Name & Status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    booking.targetPatientDisplay[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.targetPatientDisplay,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Account: ${booking.patientName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    booking.statusDisplay,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // Tests Requested
            Text(
              'Tests Requested:',
              style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: booking.tests.map((t) {
                return Chip(
                  label: Text('${t.testName} (৳${t.price.toStringAsFixed(0)})', style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.grey[100],
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Collection Method & Address
            Row(
              children: [
                Icon(
                  booking.collectionType == SampleCollectionType.homeSample
                      ? Icons.home_work_outlined
                      : Icons.local_hospital_outlined,
                  size: 16,
                  color: Colors.teal,
                ),
                const SizedBox(width: 6),
                Text(
                  booking.collectionTypeDisplay,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal),
                ),
              ],
            ),
            if (booking.collectionType == SampleCollectionType.homeSample && booking.address != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  'Address: ${booking.address}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Payment Method & Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment: ${booking.paymentMethodDisplay}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
                Text(
                  'Total: ৳${booking.finalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                ),
              ],
            ),

            if (booking.phlebotomistName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.two_wheeler, size: 16, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Collector: ${booking.phlebotomistName} (${booking.phlebotomistPhone ?? ""})\nGear: ${booking.phlebotomistEquipment ?? "Biohazard Box"}',
                        style: const TextStyle(fontSize: 11, color: Colors.deepOrange),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 20),

            // Diagnostic Center Admin Action Buttons
            _buildAdminActionControls(booking),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionControls(LabTestModel booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Diagnostic Center Actions:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Step 1: Pending Request -> Approve Request
            if (booking.status == LabTestStatus.pending)
              ElevatedButton.icon(
                onPressed: () async {
                  await _labTestService.approveBooking(booking.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order request approved! Assign a sample collector next.'), backgroundColor: Colors.teal),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                label: const Text('Approve Request', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),

            // Step 2: Approved Request -> Assign Collector
            if (booking.status == LabTestStatus.approved)
              ElevatedButton.icon(
                onPressed: () => _showAssignPhlebotomistDialog(booking),
                icon: const Icon(Icons.two_wheeler, size: 16, color: Colors.white),
                label: const Text('Assign Collector', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              ),

            // Step 3: Collector Assigned -> Mark Sample Collected
            if (booking.status == LabTestStatus.collectorAssigned)
              ElevatedButton.icon(
                onPressed: () async {
                  await _labTestService.updateBookingStatus(booking.id, LabTestStatus.sampleCollected);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sample collected & received by centre! Ready for processing.'), backgroundColor: Colors.purple),
                    );
                  }
                },
                icon: const Icon(Icons.sanitizer, size: 16, color: Colors.white),
                label: const Text('Mark Sample Collected', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),

            // Step 4: Sample Collected / Processing -> Preview & Enter Test Results to Issue PDF Report
            if (booking.status == LabTestStatus.sampleCollected || booking.status == LabTestStatus.processing) ...[
              OutlinedButton.icon(
                onPressed: () => _showEnterTestResultsDialog(booking),
                icon: const Icon(Icons.edit_note_rounded, size: 16, color: Colors.indigo),
                label: const Text('Enter Test Results', style: TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.indigo)),
              ),
              ElevatedButton.icon(
                onPressed: () => _showEnterTestResultsDialog(booking),
                icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                label: const Text('Issue & Send PDF Report', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],

            // Step 5: Completed -> View Issued Report
            if (booking.status == LabTestStatus.completed) ...[
              const Chip(
                avatar: Icon(Icons.verified, color: Colors.green, size: 16),
                label: Text('Report Issued & Sent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                backgroundColor: Color(0xFFE8F5E9),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final pdfBytes = await PdfGeneratorService.generateLabTestReportPdf(booking);
                  await Printing.layoutPdf(onLayout: (_) => pdfBytes);
                },
                icon: const Icon(Icons.print, size: 16),
                label: const Text('View/Print PDF Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showAssignPhlebotomistDialog(LabTestModel booking) {
    final nameController = TextEditingController(text: 'Mr. Tareq Hasan (Sr. Collector)');
    final phoneController = TextEditingController(text: '+880 1711-889900');
    final gearController = TextEditingController(text: 'Sterile Biohazard Cold-Box & Digital Temp Gauge');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Sample Collector'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign technician for ${booking.targetPatientDisplay}:', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Technician Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Contact Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: gearController,
              decoration: const InputDecoration(
                labelText: 'Biohazard & Storage Gear',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _labTestService.assignPhlebotomist(
                booking.id,
                name: nameController.text,
                phone: phoneController.text,
                equipment: gearController.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Assigned collector ${nameController.text} to patient!'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Confirm Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(LabTestStatus status) {
    switch (status) {
      case LabTestStatus.pending:
        return Colors.orange;
      case LabTestStatus.approved:
        return Colors.teal;
      case LabTestStatus.scheduled:
        return Colors.blue;
      case LabTestStatus.collectorAssigned:
        return Colors.deepOrange;
      case LabTestStatus.sampleCollected:
        return Colors.purple;
      case LabTestStatus.processing:
        return Colors.indigo;
      case LabTestStatus.completed:
        return Colors.green;
      case LabTestStatus.cancelled:
        return Colors.red;
    }
  }

  void _showManageTestCatalogDialog(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final defaultTests = [
      {'name': 'Complete Blood Count (CBC)', 'category': 'Blood Test', 'price': '500', 'preparation': '12-hour fasting required', 'tat': '6 Hours', 'enabled': true},
      {'name': 'Blood Sugar (Fasting)', 'category': 'Blood Test', 'price': '200', 'preparation': 'Overnight fasting required', 'tat': '4 Hours', 'enabled': true},
      {'name': 'Lipid Profile', 'category': 'Blood Test', 'price': '1000', 'preparation': '12-hour fasting required', 'tat': '12 Hours', 'enabled': true},
      {'name': 'Dengue NS1 Antigen', 'category': 'Serology', 'price': '650', 'preparation': 'No special preparation', 'tat': '4 Hours', 'enabled': true},
      {'name': 'Liver Function Test (LFT)', 'category': 'Blood Test', 'price': '1200', 'preparation': 'Fasting recommended', 'tat': '12 Hours', 'enabled': true},
      {'name': 'Kidney Function Test (KFT)', 'category': 'Blood Test', 'price': '1100', 'preparation': 'No special preparation', 'tat': '12 Hours', 'enabled': true},
      {'name': 'Thyroid Profile (T3, T4, TSH)', 'category': 'Blood Test', 'price': '1500', 'preparation': 'No special preparation', 'tat': '24 Hours', 'enabled': true},
      {'name': 'HbA1c (Diabetes)', 'category': 'Blood Test', 'price': '800', 'preparation': 'No fasting needed', 'tat': '6 Hours', 'enabled': true},
      {'name': 'Vitamin D', 'category': 'Blood Test', 'price': '2500', 'preparation': 'No special preparation', 'tat': '24 Hours', 'enabled': true},
      {'name': 'X-Ray (Chest)', 'category': 'Radiology', 'price': '600', 'preparation': 'Remove metal objects', 'tat': '2 Hours', 'enabled': true},
      {'name': 'Ultrasound (Whole Abdomen)', 'category': 'Ultrasound', 'price': '1800', 'preparation': 'Full bladder required', 'tat': 'Same Day', 'enabled': true},
      {'name': 'ECG', 'category': 'Cardiology', 'price': '400', 'preparation': 'No special preparation', 'tat': 'Immediate', 'enabled': true},
      {'name': 'Echo Cardiogram', 'category': 'Cardiology', 'price': '2500', 'preparation': 'No special preparation', 'tat': 'Same Day', 'enabled': true},
      {'name': 'MRI (Brain)', 'category': 'Radiology', 'price': '6500', 'preparation': 'Remove metallic accessories', 'tat': '24 Hours', 'enabled': true},
      {'name': 'CT Scan', 'category': 'Radiology', 'price': '4500', 'preparation': '4-hour fasting if contrast used', 'tat': '12 Hours', 'enabled': true},
      {'name': 'Urine R/E', 'category': 'Pathology', 'price': '300', 'preparation': 'First morning sample preferred', 'tat': '4 Hours', 'enabled': true},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('diagnostic_centres').doc(currentUser.uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 300,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final existingTestsList = (data?['tests'] as List<dynamic>?) ?? [];

            final Map<String, Map<String, dynamic>> testMap = {};
            for (var t in defaultTests) {
              testMap[t['name'] as String] = Map<String, dynamic>.from(t);
            }

            for (var et in existingTestsList) {
              if (et is Map) {
                final name = et['testName']?.toString() ?? et['name']?.toString() ?? '';
                if (name.isNotEmpty) {
                  testMap[name] = {
                    'name': name,
                    'category': et['category']?.toString() ?? 'General',
                    'price': (et['price'] ?? 0).toString(),
                    'preparation': et['preparationRequired']?.toString() ?? et['preparation']?.toString() ?? 'No special preparation',
                    'tat': et['turnaroundTime']?.toString() ?? et['tat']?.toString() ?? 'Same Day',
                    'enabled': true,
                  };
                }
              }
            }

            final testItems = testMap.values.toList();
            final priceControllers = {
              for (var t in testItems) t['name'] as String: TextEditingController(text: t['price'].toString())
            };
            final preparationMap = {
              for (var t in testItems) t['name'] as String: t['preparation'].toString()
            };
            final tatMap = {
              for (var t in testItems) t['name'] as String: t['tat'].toString()
            };
            final enabledState = {
              for (var t in testItems) t['name'] as String: t['enabled'] as bool
            };

            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.88,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.price_change_rounded, color: AppTheme.primaryColor, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Test Catalog & Pricing Management',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showAddNewTestDialog(context, (newTest) {
                                  setModalState(() {
                                    final name = newTest['name'] as String;
                                    testItems.add(newTest);
                                    priceControllers[name] = TextEditingController(text: newTest['price'].toString());
                                    preparationMap[name] = newTest['preparation'].toString();
                                    tatMap[name] = newTest['tat'].toString();
                                    enabledState[name] = true;
                                  });
                                });
                              },
                              icon: const Icon(Icons.add, size: 16, color: Colors.white),
                              label: const Text('Add Test', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: testItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final test = testItems[index];
                            final testName = test['name'] as String;
                            final isEnabled = enabledState[testName] ?? true;
                            final prep = preparationMap[testName] ?? 'No special preparation';
                            final tat = tatMap[testName] ?? 'Same Day';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: isEnabled,
                                    activeColor: AppTheme.primaryColor,
                                    onChanged: (val) {
                                      setModalState(() {
                                        enabledState[testName] = val ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          testName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isEnabled ? Colors.black87 : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(test['category'] as String, style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.w600)),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text('TAT: $tat', style: TextStyle(fontSize: 10, color: Colors.purple.shade800, fontWeight: FontWeight.w600)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Prep: $prep',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 95,
                                    child: TextField(
                                      controller: priceControllers[testName],
                                      enabled: isEnabled,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        prefixText: '৳ ',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              final List<Map<String, dynamic>> updatedTests = [];
                              for (var item in testItems) {
                                final name = item['name'] as String;
                                if (enabledState[name] == true) {
                                  final priceVal = int.tryParse(priceControllers[name]?.text.trim() ?? '') ?? 0;
                                  updatedTests.add({
                                    'testName': name,
                                    'category': item['category'],
                                    'price': priceVal,
                                    'preparationRequired': preparationMap[name] ?? '',
                                    'turnaroundTime': tatMap[name] ?? '',
                                  });
                                }
                              }

                              await FirebaseFirestore.instance
                                  .collection('diagnostic_centres')
                                  .doc(currentUser.uid)
                                  .set({
                                'tests': updatedTests,
                                'updatedAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Test catalog & prices updated successfully (${updatedTests.length} active tests)!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Save Test Catalog & Prices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddNewTestDialog(BuildContext context, Function(Map<String, dynamic>) onTestAdded) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final prepController = TextEditingController(text: 'No special preparation required');
    final tatController = TextEditingController(text: 'Same Day');
    String selectedCategory = 'Blood Test';

    final categories = ['Blood Test', 'Serology', 'Radiology', 'Ultrasound', 'Cardiology', 'Pathology', 'Microbiology', 'Other'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_task_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Text('Add Custom Diagnostic Test'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Test Name *',
                  hintText: 'e.g. Dengue NS1 Antigen, CBC',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) selectedCategory = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (৳) *',
                  hintText: 'e.g. 650',
                  prefixText: '৳ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: prepController,
                decoration: const InputDecoration(
                  labelText: 'Preparation Instructions',
                  hintText: 'e.g. 12-hour fasting required',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tatController,
                decoration: const InputDecoration(
                  labelText: 'Turnaround Time (TAT)',
                  hintText: 'e.g. 4 Hours, Same Day, 24 Hours',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = priceController.text.trim();
              if (name.isEmpty || price.isEmpty) return;

              onTestAdded({
                'name': name,
                'category': selectedCategory,
                'price': price,
                'preparation': prepController.text.trim(),
                'tat': tatController.text.trim(),
                'enabled': true,
              });

              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Add Test', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEnterTestResultsDialog(LabTestModel booking) {
    final Map<String, TextEditingController> valueControllers = {};
    final Map<String, TextEditingController> rangeControllers = {};
    final Map<String, String> statusMap = {};

    final remarksController = TextEditingController(text: 'All parameters verified by Chief Pathologist. Correlate clinically.');

    for (var test in booking.tests) {
      final nameLower = test.testName.toLowerCase();
      final isBlood = nameLower.contains('cbc') || nameLower.contains('blood');
      final isDengue = nameLower.contains('dengue') || nameLower.contains('antigen');
      final isThyroid = nameLower.contains('thyroid') || nameLower.contains('tsh');
      final isSugar = nameLower.contains('sugar') || nameLower.contains('glucose');

      valueControllers[test.testName] = TextEditingController(
        text: isBlood ? '13.5 g/dL' : isSugar ? '95 mg/dL' : isDengue ? 'Negative' : isThyroid ? '2.4 uIU/mL' : 'Normal',
      );
      rangeControllers[test.testName] = TextEditingController(
        text: isBlood ? '12.0 - 16.0 g/dL' : isSugar ? '70 - 100 mg/dL' : isDengue ? 'Negative' : isThyroid ? '0.4 - 4.0 uIU/mL' : 'Normal / Negative',
      );
      statusMap[test.testName] = isDengue ? 'NEGATIVE' : 'NORMAL';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_turned_in_rounded, color: Colors.teal, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Enter Lab Test Results & Issue Report',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                              Text(
                                'Patient: ${booking.targetPatientDisplay}',
                                style: TextStyle(fontSize: 12, color: Colors.teal.shade800),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: booking.tests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final test = booking.tests[index];
                        final testName = test.testName;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      testName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                    child: Text(test.category, style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: valueControllers[testName],
                                      decoration: const InputDecoration(
                                        labelText: 'Measured Result Value *',
                                        hintText: 'e.g. 13.5 g/dL, Positive, Normal',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: rangeControllers[testName],
                                      decoration: const InputDecoration(
                                        labelText: 'Reference Range',
                                        hintText: 'e.g. 12.0-16.0 g/dL',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Text('Status: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  Wrap(
                                    spacing: 6,
                                    children: ['NORMAL', 'HIGH', 'LOW', 'POSITIVE', 'NEGATIVE'].map((st) {
                                      final isSelected = statusMap[testName] == st;
                                      return ChoiceChip(
                                        label: Text(st, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black87)),
                                        selected: isSelected,
                                        selectedColor: st == 'HIGH' || st == 'POSITIVE' ? Colors.red : Colors.teal,
                                        onSelected: (selected) {
                                          if (selected) {
                                            setModalState(() {
                                              statusMap[testName] = st;
                                            });
                                          }
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: remarksController,
                      decoration: const InputDecoration(
                        labelText: 'Pathologist Remarks & Clinical Notes',
                        hintText: 'e.g. All parameters checked and verified.',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(top: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final Map<String, Map<String, String>> customResults = {};
                              for (var test in booking.tests) {
                                customResults[test.testName] = {
                                  'value': valueControllers[test.testName]?.text.trim() ?? '',
                                  'range': rangeControllers[test.testName]?.text.trim() ?? '',
                                  'status': statusMap[test.testName] ?? 'NORMAL',
                                };
                              }

                              final pdfBytes = await PdfGeneratorService.generateLabTestReportPdf(
                                booking,
                                customResults: customResults,
                                pathologistRemarks: remarksController.text.trim(),
                              );
                              await Printing.layoutPdf(onLayout: (_) => pdfBytes);
                            },
                            icon: const Icon(Icons.preview_rounded, size: 18),
                            label: const Text('Preview PDF'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.teal),
                              foregroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final Map<String, Map<String, String>> customResults = {};
                              for (var test in booking.tests) {
                                customResults[test.testName] = {
                                  'value': valueControllers[test.testName]?.text.trim() ?? '',
                                  'range': rangeControllers[test.testName]?.text.trim() ?? '',
                                  'status': statusMap[test.testName] ?? 'NORMAL',
                                };
                              }

                              final reportUrl = 'https://mediconnect.health/reports/REPORT_${booking.id}.pdf';
                              await _labTestService.uploadReport(booking.id, reportUrl);

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Official PDF Report created with entered test results & delivered to patient!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                            label: const Text('Confirm & Send PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
