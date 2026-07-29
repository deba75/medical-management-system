import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/lab_test_service.dart';
import '../../../core/widgets/family_member_selector.dart';
import '../../../core/providers/family_member_provider.dart';
import '../../../models/diagnostic_centre_model.dart';
import '../../../models/family_member_model.dart';
import '../../../models/lab_test_model.dart';
import '../lab_test/lab_test_booking_screen.dart';

class DiagnosticCentreDetailScreen extends ConsumerStatefulWidget {
  final DiagnosticCentreModel centre;

  const DiagnosticCentreDetailScreen({super.key, required this.centre});

  @override
  ConsumerState<DiagnosticCentreDetailScreen> createState() =>
      _DiagnosticCentreDetailScreenState();
}

class _DiagnosticCentreDetailScreenState
    extends ConsumerState<DiagnosticCentreDetailScreen> {
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();
  final _labTestService = LabTestService();
  List<DiagnosticTest> _filteredTests = [];
  final List<DiagnosticTest> _selectedTests = [];

  @override
  void initState() {
    super.initState();
    _filteredTests = widget.centre.tests;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTests(String query) {
    setState(() {
      if (query.isEmpty && _selectedCategory == 'All') {
        _filteredTests = widget.centre.tests;
      } else {
        _filteredTests = widget.centre.tests.where((test) {
          final matchesQuery = query.isEmpty ||
              test.testName.toLowerCase().contains(query.toLowerCase());
          final matchesCategory =
              _selectedCategory == 'All' || test.category == _selectedCategory;
          return matchesQuery && matchesCategory;
        }).toList();
      }
    });
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
    _filterTests(_searchController.text);
  }

  void _toggleTestSelection(DiagnosticTest test) {
    setState(() {
      final exists = _selectedTests.any((t) => t.testId == test.testId);
      if (exists) {
        _selectedTests.removeWhere((t) => t.testId == test.testId);
      } else {
        _selectedTests.add(test);
      }
    });
  }

  double get _totalPrice {
    return _selectedTests.fold(0, (sum, t) => sum + t.price);
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<String> get _categories {
    final cats = widget.centre.tests.map((t) => t.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  void _showCheckoutBottomSheet() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = '09:00 AM - 12:00 PM';
    SampleCollectionType collectionType = SampleCollectionType.homeSample;
    LabPaymentMethod paymentMethod = LabPaymentMethod.online;
    final addressController = TextEditingController();
    FamilyMemberModel? targetFamilyMember = ref.read(selectedFamilyMemberProvider);

    final slots = [
      '08:00 AM - 11:00 AM',
      '11:00 AM - 02:00 PM',
      '02:00 PM - 05:00 PM',
      '05:00 PM - 08:00 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final homeFee = collectionType == SampleCollectionType.homeSample ? 150.0 : 0.0;
          final totalAmount = _totalPrice + homeFee;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
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
                  Text(
                    'Book Test at ${widget.centre.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedTests.length} Test(s) Selected',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // 1. Patient Selection (Self or Family Member)
                  FamilyMemberSelector(
                    onSelected: (member) {
                      setModalState(() {
                        targetFamilyMember = member;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Collection Type Selection
                  const Text(
                    'Sample Collection Method',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              collectionType = SampleCollectionType.homeSample;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: collectionType == SampleCollectionType.homeSample
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: collectionType == SampleCollectionType.homeSample
                                    ? AppTheme.primaryColor
                                    : Colors.grey[300]!,
                                width: collectionType == SampleCollectionType.homeSample ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.home_work_outlined,
                                  color: collectionType == SampleCollectionType.homeSample
                                      ? AppTheme.primaryColor
                                      : Colors.grey[700],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Home Specimen',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: collectionType == SampleCollectionType.homeSample
                                        ? AppTheme.primaryColor
                                        : Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Technician Visits Home (+৳150)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              collectionType = SampleCollectionType.centerWalkIn;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: collectionType == SampleCollectionType.centerWalkIn
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: collectionType == SampleCollectionType.centerWalkIn
                                    ? AppTheme.primaryColor
                                    : Colors.grey[300]!,
                                width: collectionType == SampleCollectionType.centerWalkIn ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.local_hospital_outlined,
                                  color: collectionType == SampleCollectionType.centerWalkIn
                                      ? AppTheme.primaryColor
                                      : Colors.grey[700],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Center Walk-In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: collectionType == SampleCollectionType.centerWalkIn
                                        ? AppTheme.primaryColor
                                        : Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Visit Diagnostic Lab',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (collectionType == SampleCollectionType.homeSample) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Home Collection Address',
                        hintText: 'Enter detailed street address and landmarks',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 3. Date & Time Slot
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Schedule Date',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
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
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(selectedDate),
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Time Slot',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots.map((slot) {
                      final isSelected = selectedSlot == slot;
                      return ChoiceChip(
                        label: Text(slot),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setModalState(() => selectedSlot = slot);
                        },
                        selectedColor: AppTheme.primaryColor,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[800],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // 4. Payment Method Options
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      RadioListTile<LabPaymentMethod>(
                        value: LabPaymentMethod.online,
                        groupValue: paymentMethod,
                        title: const Text('Online Payment (bKash / Card / Banking)'),
                        subtitle: const Text('Instant confirmation & digital receipt'),
                        secondary: const Icon(Icons.payment, color: AppTheme.primaryColor),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          if (val != null) setModalState(() => paymentMethod = val);
                        },
                      ),
                      RadioListTile<LabPaymentMethod>(
                        value: LabPaymentMethod.manual,
                        groupValue: paymentMethod,
                        title: const Text('Pay Manually / Cash on Collection'),
                        subtitle: const Text('Pay technician upon sample collection or lab visit'),
                        secondary: const Icon(Icons.money, color: Colors.green),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          if (val != null) setModalState(() => paymentMethod = val);
                        },
                      ),
                      RadioListTile<LabPaymentMethod>(
                        value: LabPaymentMethod.due,
                        groupValue: paymentMethod,
                        title: const Text('Pay Later / Diagnostic Bill Due'),
                        subtitle: const Text('Bill added to your account due balance'),
                        secondary: const Icon(Icons.receipt_long, color: Colors.orange),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          if (val != null) setModalState(() => paymentMethod = val);
                        },
                      ),
                    ],
                  ),

                  const Divider(),
                  const SizedBox(height: 8),

                  // Payment Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tests Subtotal:', style: TextStyle(color: Colors.grey[700])),
                      Text('৳${_totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (collectionType == SampleCollectionType.homeSample) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Home Collection Charge:', style: TextStyle(color: Colors.grey[700])),
                        const Text('৳150', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '৳${totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _confirmCentreBooking(
                        selectedDate,
                        selectedSlot,
                        collectionType,
                        addressController.text,
                        paymentMethod,
                        targetFamilyMember,
                        homeFee,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Test Order',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
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
                                Navigator.pop(ctx, true);
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

  void _confirmCentreBooking(
    DateTime date,
    String slot,
    SampleCollectionType collectionType,
    String address,
    LabPaymentMethod paymentMethod,
    FamilyMemberModel? familyMember,
    double homeFee,
  ) async {
    try {
      final totalPayable = _totalPrice + homeFee;

      // If Online payment is selected, go through bKash payment gateway modal
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
      final patientId = user?.uid ?? 'guest';
      final patientName = user?.displayName ?? 'Patient';

      final testItems = _selectedTests.map((t) => TestItem(
        testId: t.testId,
        testName: t.testName,
        category: t.category,
        price: t.price,
        description: t.description,
      )).toList();

      final booking = LabTestModel(
        id: '',
        patientId: patientId,
        patientName: patientName,
        familyMemberId: familyMember?.id,
        familyMemberName: familyMember?.name,
        familyMemberRelationship: familyMember?.relationship,
        diagnosticCentreId: widget.centre.centreId,
        diagnosticCentreName: widget.centre.name,
        tests: testItems,
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
        address: collectionType == SampleCollectionType.homeSample ? address : widget.centre.address,
        totalAmount: _totalPrice,
        homeCollectionFee: homeFee,
        createdAt: DateTime.now(),
      );

      await _labTestService.bookLabTest(booking);

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        setState(() => _selectedTests.clear());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test order placed successfully at ${widget.centre.name}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Open Lab Test Bookings Screen to track order
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LabTestBookingScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.centre.name),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Centre Info Header
          _buildCentreInfoHeader(),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterTests,
              decoration: InputDecoration(
                hintText: 'Search tests...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Category Filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => _selectCategory(category),
                    selectedColor: AppTheme.primaryColor,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Tests List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Available Tests & Prices',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_filteredTests.length} tests',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // Tests List
          Expanded(
            child: _filteredTests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTests.length,
                    itemBuilder: (context, index) {
                      final test = _filteredTests[index];
                      return _buildTestCard(test);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedTests.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
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
                            '${_selectedTests.length} Test(s) Selected',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '৳${_totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCheckoutBottomSheet,
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text('Proceed to Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCentreInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.centre.address}, ${widget.centre.city}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 18, color: AppTheme.primaryColor),
                onPressed: () => _copyToClipboard(
                  '${widget.centre.address}, ${widget.centre.city}',
                  'Address copied!',
                ),
                tooltip: 'Copy address',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Contact
          Row(
            children: [
              Icon(Icons.phone, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                widget.centre.contactNumber,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.copy, size: 18, color: AppTheme.primaryColor),
                onPressed: () => _copyToClipboard(
                  widget.centre.contactNumber.replaceAll(' ', '').replaceAll('-', ''),
                  'Phone number copied!',
                ),
                tooltip: 'Copy phone number',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.science, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  '${widget.centre.tests.length} Tests Available',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(DiagnosticTest test) {
    final isSelected = _selectedTests.any((t) => t.testId == test.testId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleTestSelection(test),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                activeColor: AppTheme.primaryColor,
                onChanged: (_) => _toggleTestSelection(test),
              ),
              const SizedBox(width: 8),

              // Test Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getCategoryColor(test.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(test.category),
                  color: _getCategoryColor(test.category),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Test Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.testName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        test.category,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Price
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.15)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '৳${test.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tests found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'blood test':
        return Colors.red;
      case 'radiology':
        return Colors.blue;
      case 'ultrasound':
        return Colors.purple;
      case 'cardiology':
        return Colors.pink;
      case 'pathology':
        return Colors.orange;
      case 'gastroenterology':
        return Colors.teal;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'blood test':
        return Icons.bloodtype;
      case 'radiology':
        return Icons.camera_alt;
      case 'ultrasound':
        return Icons.waves;
      case 'cardiology':
        return Icons.favorite;
      case 'pathology':
        return Icons.science;
      case 'gastroenterology':
        return Icons.medical_services;
      default:
        return Icons.biotech;
    }
  }
}
