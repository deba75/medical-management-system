import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/lab_test_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/lab_test_model.dart';
import '../../../models/family_member_model.dart';
import '../../../core/widgets/family_member_selector.dart';
import '../../../core/providers/family_member_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/pdf_generator_service.dart';


class LabTestBookingScreen extends ConsumerStatefulWidget {
  const LabTestBookingScreen({super.key});

  @override
  ConsumerState<LabTestBookingScreen> createState() => _LabTestBookingScreenState();
}

class _LabTestBookingScreenState extends ConsumerState<LabTestBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _labTestService = LabTestService();
  final _patientId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<AvailableLabTest> _availableTests = [];
  List<AvailableLabTest> _filteredTests = [];
  List<TestItem> _cart = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTests();
  }

  void _loadTests() async {
    try {
      final tests = await _labTestService.getAvailableTests();
      setState(() {
        _availableTests = tests;
        _filteredTests = tests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterTests(String query) {
    setState(() {
      _filteredTests = _availableTests.where((test) {
        final matchesSearch = test.name.toLowerCase().contains(query.toLowerCase()) ||
            test.category.toLowerCase().contains(query.toLowerCase());
        final matchesCategory = _selectedCategory == 'All' || test.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
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
        title: const Text(
          'Lab Tests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.0,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Book Test'),
            Tab(text: 'My Bookings'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookTestTab(),
          _buildMyBookingsTab(),
          _buildReportsTab(),
        ],
      ),
      bottomNavigationBar: _cart.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_cart.length} Test(s) Selected',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '₹${_cart.fold<double>(0, (sum, item) => sum + item.price).toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showBookingDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Book Now'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBookTestTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search tests...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: _filterTests,
          ),
        ),
        SizedBox(
          height: 45,
          child: FutureBuilder<List<String>>(
            future: _labTestService.getCategories(),
            builder: (context, snapshot) {
              final categories = ['All', ...snapshot.data ?? []];
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _filterTests(_searchController.text);
                        });
                      },
                      selectedColor: AppTheme.primaryColor,
                      checkmarkColor: Colors.white,
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredTests.isEmpty
                  ? _buildEmptyState('No tests found', 'Try a different search term')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTests.length,
                      itemBuilder: (context, index) {
                        return _buildTestCard(_filteredTests[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTestCard(AvailableLabTest test) {
    final isInCart = _cart.any((item) => item.testId == test.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTestDetails(test),
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
                child: const Icon(
                  Icons.science,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          test.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        if (test.centreName != null && test.centreName!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              test.centreName!,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (test.preparationHours != null && test.preparationHours! > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.warning_amber, size: 14, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${test.preparationHours}h fasting required',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'BDT ${test.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: isInCart
                        ? OutlinedButton(
                            onPressed: () => _removeFromCart(test),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Remove'),
                          )
                        : ElevatedButton(
                            onPressed: () => _addToCart(test),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Add'),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(AvailableLabTest test) {
    setState(() {
      _cart.add(TestItem(
        testId: test.id,
        testName: test.name,
        category: test.category,
        price: test.price,
        description: test.description,
        preparationHours: test.preparationHours,
        diagnosticCentreId: test.centreId,
        diagnosticCentreName: test.centreName,
      ));
    });
  }

  void _removeFromCart(AvailableLabTest test) {
    setState(() {
      _cart.removeWhere((item) => item.testId == test.id);
    });
  }

  void _showTestDetails(AvailableLabTest test) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 20),
            Text(
              test.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(test.category),
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              test.description,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            if (test.parameters.isNotEmpty) ...[
              const Text(
                'Parameters Included:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: test.parameters.map((param) {
                  return Chip(
                    label: Text(param, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.grey[100],
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (test.preparationHours != null && test.preparationHours! > 0)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Text('${test.preparationHours}h fasting required'),
                      ],
                    ),
                  ),
                if (test.reportTime != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text('Report: ${test.reportTime}'),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  '৳${test.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _addToCart(test);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Add to Cart'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyBookingsTab() {
    return StreamBuilder<List<LabTestModel>>(
      stream: _labTestService.getPatientBookings(_patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return _buildEmptyState('No bookings yet', 'Book a lab test to see it here');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return _buildBookingCard(bookings[index]);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(LabTestModel booking) {
    final statusColor = _getStatusColor(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Status badge & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(booking.status),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.tests.map((t) => t.testName).join(', '),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.diagnosticCentreName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    booking.statusDisplay,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Beneficiary & Collection Badges
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // Patient / Family Member Badge
                Chip(
                  avatar: Icon(
                    booking.isForFamilyMember ? Icons.family_restroom : Icons.person,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                  label: Text(
                    'For: ${booking.targetPatientDisplay}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                // Collection Type Badge
                Chip(
                  avatar: Icon(
                    booking.collectionType == SampleCollectionType.homeSample
                        ? Icons.home_work_outlined
                        : Icons.local_hospital_outlined,
                    size: 14,
                    color: Colors.teal,
                  ),
                  label: Text(
                    booking.collectionTypeDisplay,
                    style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: Colors.teal.withOpacity(0.08),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                // Payment Method Badge
                Chip(
                  avatar: Icon(
                    booking.paymentMethod == LabPaymentMethod.online
                        ? Icons.payment
                        : (booking.paymentMethod == LabPaymentMethod.manual
                            ? Icons.money
                            : Icons.receipt_long),
                    size: 14,
                    color: Colors.indigo,
                  ),
                  label: Text(
                    booking.paymentMethodDisplay,
                    style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: Colors.indigo.withOpacity(0.08),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),

            const Divider(height: 20),

            // Schedule & Price Row
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM d, yyyy').format(booking.scheduledDate),
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  booking.timeSlot ?? 'Any time',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Text(
                  '৳${booking.finalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),

                // Track Order Button
                OutlinedButton.icon(
                  onPressed: () => _showTrackingTimelineSheet(booking),
                  icon: const Icon(Icons.timeline, size: 16),
                  label: const Text('Track Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),

                const SizedBox(width: 8),

                if (booking.status == LabTestStatus.pending)
                  TextButton(
                    onPressed: () => _cancelBooking(booking),
                    child: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                if (booking.reportUrl != null || booking.status == LabTestStatus.completed)
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        if (booking.reportUrl != null && (booking.reportUrl!.startsWith('http://') || booking.reportUrl!.startsWith('https://'))) {
                          await launchUrl(Uri.parse(booking.reportUrl!), mode: LaunchMode.externalApplication);
                        } else {
                          final pdfBytes = await PdfGeneratorService.generateLabTestReportPdf(booking);
                          await Printing.layoutPdf(onLayout: (_) => pdfBytes, name: 'Report_${booking.id}.pdf');
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error viewing report PDF: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                    label: const Text('View PDF Report', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackingTimelineSheet(LabTestModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.biotech, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order Lifecycle Tracking',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Order ID: #${booking.id.isNotEmpty ? booking.id.substring(0, booking.id.length > 8 ? 8 : booking.id.length) : "TEST-REG"}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Divider(height: 24),

                // Order summary details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Patient Beneficiary:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(booking.targetPatientDisplay, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Center:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(booking.diagnosticCentreName, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sample Method:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(booking.collectionTypeDisplay, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 5-Stage Lifecycle Progress Timeline
                _buildTimelineStep(
                  stepNumber: '1',
                  title: 'Booking & Verification',
                  subtitle: 'Order placed by patient. Diagnostic center reviewing location availability.',
                  isCompleted: true,
                  isActive: booking.status == LabTestStatus.pending,
                  icon: Icons.assignment_turned_in_outlined,
                ),
                _buildTimelineStep(
                  stepNumber: '2',
                  title: 'Review & Approval',
                  subtitle: 'Center verified availability and approved order request.',
                  isCompleted: booking.status.index >= LabTestStatus.approved.index && booking.status != LabTestStatus.cancelled,
                  isActive: booking.status == LabTestStatus.approved || booking.status == LabTestStatus.scheduled,
                  icon: Icons.verified_user_outlined,
                ),
                _buildTimelineStep(
                  stepNumber: '3',
                  title: 'Collector Assignment',
                  subtitle: booking.phlebotomistName != null
                      ? 'Technician ${booking.phlebotomistName} assigned with ${booking.phlebotomistEquipment ?? "Biohazard & Temp-Controlled Storage"}.'
                      : 'Assigning trained Phlebotomist technician & visit schedule.',
                  isCompleted: booking.status.index >= LabTestStatus.collectorAssigned.index && booking.status != LabTestStatus.cancelled,
                  isActive: booking.status == LabTestStatus.collectorAssigned,
                  icon: Icons.two_wheeler,
                ),
                _buildTimelineStep(
                  stepNumber: '4',
                  title: 'Sample Collection & Transit',
                  subtitle: 'Specimen collected using cold-chain storage gear & transported to lab.',
                  isCompleted: booking.status.index >= LabTestStatus.sampleCollected.index && booking.status != LabTestStatus.cancelled,
                  isActive: booking.status == LabTestStatus.sampleCollected,
                  icon: Icons.sanitizer_outlined,
                ),
                _buildTimelineStep(
                  stepNumber: '5',
                  title: 'Processing & Reporting',
                  subtitle: booking.status == LabTestStatus.completed
                      ? 'Diagnostic test complete. Report uploaded to MediConnect dashboard!'
                      : 'Lab analyzing specimen samples.',
                  isCompleted: booking.status == LabTestStatus.completed,
                  isActive: booking.status == LabTestStatus.processing || booking.status == LabTestStatus.completed,
                  isLast: true,
                  icon: Icons.analytics_outlined,
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close Tracking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required IconData icon,
    bool isLast = false,
  }) {
    final color = isCompleted
        ? Colors.green
        : (isActive ? AppTheme.primaryColor : Colors.grey[400]!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                size: 18,
                color: color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCompleted || isActive ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    return StreamBuilder<List<LabTestModel>>(
      stream: _labTestService.getPatientBookings(_patientId),
      builder: (context, snapshot) {
        final bookings = (snapshot.data ?? [])
            .where((b) => b.status == LabTestStatus.completed && b.reportUrl != null)
            .toList();

        if (bookings.isEmpty) {
          return _buildEmptyState(
            'No reports available',
            'Completed test reports issued by diagnostic centers will automatically appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf, color: Colors.green, size: 28),
                      ),
                      title: Text(
                        booking.tests.map((t) => t.testName).join(', '),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Lab: ${booking.diagnosticCentreName}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text('Patient: ${booking.targetPatientDisplay} • Date: ${DateFormat("dd MMM yyyy, hh:mm a").format(booking.reportGeneratedAt ?? booking.scheduledDate)}'),
                        ],
                      ),
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final pdfBytes = await PdfGeneratorService.generateLabTestReportPdf(booking);
                            await Printing.layoutPdf(onLayout: (_) => pdfBytes);
                          },
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('View PDF Report'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final pdfBytes = await PdfGeneratorService.generateLabTestReportPdf(booking);
                            await Printing.sharePdf(
                              bytes: pdfBytes,
                              filename: 'Report_${booking.targetPatientDisplay.replaceAll(' ', '_')}.pdf',
                            );
                          },
                          icon: const Icon(Icons.download, size: 16, color: Colors.white),
                          label: const Text('Download PDF', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
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

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
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

  IconData _getStatusIcon(LabTestStatus status) {
    switch (status) {
      case LabTestStatus.pending:
        return Icons.hourglass_empty;
      case LabTestStatus.approved:
        return Icons.verified_user_outlined;
      case LabTestStatus.scheduled:
        return Icons.event;
      case LabTestStatus.collectorAssigned:
        return Icons.two_wheeler;
      case LabTestStatus.sampleCollected:
        return Icons.sanitizer_outlined;
      case LabTestStatus.processing:
        return Icons.science;
      case LabTestStatus.completed:
        return Icons.done_all;
      case LabTestStatus.cancelled:
        return Icons.cancel;
    }
  }

  void _showBookingDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = '09:00 AM - 12:00 PM';
    SampleCollectionType collectionType = SampleCollectionType.homeSample;
    LabPaymentMethod paymentMethod = LabPaymentMethod.online;
    final addressController = TextEditingController();
    FamilyMemberModel? selectedMember = ref.read(selectedFamilyMemberProvider);

    final slots = [
      '08:00 AM - 11:00 AM',
      '11:00 AM - 02:00 PM',
      '02:00 PM - 05:00 PM',
      '05:00 PM - 08:00 PM',
    ];

    final cartSubtotal = _cart.fold<double>(0, (sum, item) => sum + item.price);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final homeFee = collectionType == SampleCollectionType.homeSample ? 150.0 : 0.0;
          final totalPayable = cartSubtotal + homeFee;

          return Container(
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
                  const SizedBox(height: 16),
                  const Text(
                    'Complete Lab Booking',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Family Member Selector
                  FamilyMemberSelector(
                    onSelected: (member) {
                      setModalState(() {
                        selectedMember = member;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text('Selected Tests:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _cart.map((test) {
                      return Chip(
                        label: Text('${test.testName} (৳${test.price.toStringAsFixed(0)})'),
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  const Text('Sample Collection Method', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: Icon(Icons.home_work_outlined, size: 16, color: collectionType == SampleCollectionType.homeSample ? Colors.white : AppTheme.primaryColor),
                          label: Text(
                            'Home Specimen',
                            style: TextStyle(
                              color: collectionType == SampleCollectionType.homeSample ? Colors.white : Colors.black87,
                              fontWeight: collectionType == SampleCollectionType.homeSample ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: collectionType == SampleCollectionType.homeSample,
                          selectedColor: AppTheme.primaryColor,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            setModalState(() => collectionType = SampleCollectionType.homeSample);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          avatar: Icon(Icons.local_hospital_outlined, size: 16, color: collectionType == SampleCollectionType.centerWalkIn ? Colors.white : AppTheme.primaryColor),
                          label: Text(
                            'Center Walk-In',
                            style: TextStyle(
                              color: collectionType == SampleCollectionType.centerWalkIn ? Colors.white : Colors.black87,
                              fontWeight: collectionType == SampleCollectionType.centerWalkIn ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: collectionType == SampleCollectionType.centerWalkIn,
                          selectedColor: AppTheme.primaryColor,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            setModalState(() => collectionType = SampleCollectionType.centerWalkIn);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (collectionType == SampleCollectionType.homeSample) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Home Collection Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  RadioListTile<LabPaymentMethod>(
                    value: LabPaymentMethod.online,
                    groupValue: paymentMethod,
                    title: const Text('Online Payment (Digital)'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) setModalState(() => paymentMethod = val);
                    },
                  ),
                  RadioListTile<LabPaymentMethod>(
                    value: LabPaymentMethod.manual,
                    groupValue: paymentMethod,
                    title: const Text('Pay Manually / Cash on Collection'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) setModalState(() => paymentMethod = val);
                    },
                  ),
                  RadioListTile<LabPaymentMethod>(
                    value: LabPaymentMethod.due,
                    groupValue: paymentMethod,
                    title: const Text('Pay Later / Due'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) setModalState(() => paymentMethod = val);
                    },
                  ),

                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Schedule Date', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) {
                        setModalState(() => selectedDate = date);
                      }
                    },
                  ),

                  const Text('Time Slot', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: slots.map((slot) {
                      final isSelected = selectedSlot == slot;
                      return ChoiceChip(
                        label: Text(
                          slot,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          setModalState(() => selectedSlot = slot);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Amount'),
                          Text(
                            '৳${totalPayable.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _confirmBooking(
                          selectedDate,
                          selectedSlot,
                          collectionType,
                          addressController.text,
                          paymentMethod,
                          selectedMember,
                          homeFee,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Confirm Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _showBkashPaymentGateway(BuildContext context, double amount) async {
    final phoneController = TextEditingController(text: '01712345678');
    final otpController = TextEditingController(text: '123456');
    final pinController = TextEditingController(text: '12345');
    int currentStep = 1;
    bool isProcessing = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2136E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                            SizedBox(width: 10),
                            Text(
                              'bKash Payment Gateway',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Merchant: MediConnect Health & Diagnostics',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Amount: ৳${amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (currentStep == 1) ...[
                    const Text(
                      'Enter Your bKash Account Number',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'bKash Mobile Number',
                        hintText: 'e.g. 01712345678',
                        prefixIcon: const Icon(Icons.phone_android, color: Color(0xFFE2136E)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                setSheetState(() => isProcessing = true);
                                await Future.delayed(const Duration(milliseconds: 500));
                                setSheetState(() {
                                  isProcessing = false;
                                  currentStep = 2;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE2136E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isProcessing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Proceed to Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else if (currentStep == 2) ...[
                    const Text(
                      'Enter 6-Digit bKash Verification Code (OTP)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sent to ${phoneController.text}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(letterSpacing: 8, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '123456',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                setSheetState(() => isProcessing = true);
                                await Future.delayed(const Duration(milliseconds: 500));
                                setSheetState(() {
                                  isProcessing = false;
                                  currentStep = 3;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE2136E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isProcessing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Confirm OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Enter bKash 5-Digit PIN',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(letterSpacing: 8, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '•••••',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                setSheetState(() => isProcessing = true);
                                await Future.delayed(const Duration(milliseconds: 700));
                                if (ctx.mounted) Navigator.pop(ctx, true);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE2136E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isProcessing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Confirm Payment ৳', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel Payment', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return result ?? false;
  }

  void _confirmBooking(
    DateTime date,
    String slot,
    SampleCollectionType collectionType,
    String address,
    LabPaymentMethod paymentMethod,
    FamilyMemberModel? familyMember,
    double homeFee,
  ) async {
    try {
      final cartSubtotal = _cart.fold<double>(0, (sum, item) => sum + item.price);
      final totalPayable = cartSubtotal + homeFee;

      // If Online payment is selected, launch bKash gateway modal
      if (paymentMethod == LabPaymentMethod.online) {
        final paymentSuccess = await _showBkashPaymentGateway(context, totalPayable);
        if (!paymentSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('bKash Payment was cancelled'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      final booking = LabTestModel(
        id: '',
        patientId: _patientId,
        patientName: user?.displayName ?? 'Patient',
        familyMemberId: familyMember?.id,
        familyMemberName: familyMember?.name,
        familyMemberRelationship: familyMember?.relationship,
        diagnosticCentreId: _cart.isNotEmpty ? (_cart.first.diagnosticCentreId ?? 'default') : 'default',
        diagnosticCentreName: _cart.isNotEmpty ? (_cart.first.diagnosticCentreName ?? 'MediCare Diagnostics') : 'MediCare Diagnostics',
        tests: _cart,
        status: LabTestStatus.pending,
        collectionType: collectionType,
        paymentMethod: paymentMethod,
        paymentStatus: paymentMethod == LabPaymentMethod.online
            ? LabPaymentStatus.paid
            : (paymentMethod == LabPaymentMethod.due
                ? LabPaymentStatus.due
                : LabPaymentStatus.pending),
        scheduledDate: date,
        timeSlot: slot,
        address: collectionType == SampleCollectionType.homeSample ? address : null,
        totalAmount: cartSubtotal,
        homeCollectionFee: homeFee,
        createdAt: DateTime.now(),
      );

      await _labTestService.bookLabTest(booking);

      if (mounted) {
        Navigator.pop(context);
        setState(() => _cart.clear());
        _tabController.animateTo(1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lab test booking confirmed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _cancelBooking(LabTestModel booking) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              await _labTestService.cancelBooking(booking.id);
              if (mounted && dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
