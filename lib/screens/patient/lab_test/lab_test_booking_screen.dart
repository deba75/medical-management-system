import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/lab_test_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/lab_test_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
        title: const Text('Lab Tests'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
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
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _filterTests(_searchController.text);
                        });
                      },
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primaryColor,
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
                    Text(
                      test.category,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
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
                    '₹${test.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(booking.status),
                    color: _getStatusColor(booking.status),
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
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.statusDisplay,
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(booking.scheduledDate),
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(width: 24),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  booking.timeSlot ?? 'Any time',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                if (booking.status == LabTestStatus.pending)
                  TextButton(
                    onPressed: () => _cancelBooking(booking),
                    child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                if (booking.reportUrl != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Open report
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Report'),
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
  }

  Widget _buildReportsTab() {
    return StreamBuilder<List<LabTestModel>>(
      stream: _labTestService.getPatientBookings(_patientId),
      builder: (context, snapshot) {
        final bookings = (snapshot.data ?? [])
            .where((b) => b.status == LabTestStatus.completed && b.reportUrl != null)
            .toList();

        if (bookings.isEmpty) {
          return _buildEmptyState('No reports available', 'Completed tests with reports will appear here');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description, color: Colors.green),
                ),
                title: Text(
                  booking.tests.map((t) => t.testName).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  DateFormat('MMM d, yyyy').format(booking.reportGeneratedAt ?? booking.scheduledDate),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.download, color: AppTheme.primaryColor),
                  onPressed: () {
                    // Download report
                  },
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
      case LabTestStatus.scheduled:
        return Colors.blue;
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
      case LabTestStatus.scheduled:
        return Icons.event;
      case LabTestStatus.sampleCollected:
        return Icons.check_circle_outline;
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
    SampleCollectionType collectionType = SampleCollectionType.visitLab;
    final addressController = TextEditingController();

    final slots = [
      '09:00 AM - 12:00 PM',
      '12:00 PM - 03:00 PM',
      '03:00 PM - 06:00 PM',
    ];

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete Booking',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text('Selected Tests:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _cart.map((test) {
                    return Chip(label: Text(test.testName));
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Collection Type', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Visit Lab'),
                        selected: collectionType == SampleCollectionType.visitLab,
                        onSelected: (selected) {
                          setModalState(() => collectionType = SampleCollectionType.visitLab);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Home Sample'),
                        selected: collectionType == SampleCollectionType.homeSample,
                        onSelected: (selected) {
                          setModalState(() => collectionType = SampleCollectionType.homeSample);
                        },
                      ),
                    ),
                  ],
                ),
                if (collectionType == SampleCollectionType.homeSample) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Home Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Select Date'),
                  subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      setModalState(() => selectedDate = date);
                    }
                  },
                ),
                const Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: slots.map((slot) {
                    return ChoiceChip(
                      label: Text(slot),
                      selected: selectedSlot == slot,
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
                          '৳${_cart.fold<double>(0, (sum, item) => sum + item.price).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
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
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Confirm Booking'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmBooking(
    DateTime date,
    String slot,
    SampleCollectionType collectionType,
    String address,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final booking = LabTestModel(
        id: '',
        patientId: _patientId,
        patientName: user?.displayName ?? 'Patient',
        diagnosticCentreId: 'default',
        diagnosticCentreName: 'MediCare Diagnostics',
        tests: _cart,
        status: LabTestStatus.pending,
        collectionType: collectionType,
        scheduledDate: date,
        timeSlot: slot,
        address: collectionType == SampleCollectionType.homeSample ? address : null,
        totalAmount: _cart.fold(0, (sum, item) => sum + item.price),
        createdAt: DateTime.now(),
      );

      await _labTestService.bookLabTest(booking);

      if (mounted) {
        Navigator.pop(context);
        setState(() => _cart.clear());
        _tabController.animateTo(1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _cancelBooking(LabTestModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              await _labTestService.cancelBooking(booking.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
