import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/family_member_selector.dart';
import '../../../core/providers/family_member_provider.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../../../models/doctor_model.dart';
import '../../../models/appointment_model.dart';
import '../../../models/time_slot_model.dart';
import '../../../models/hospital_model.dart';

// Conditional import for web payment
import '../../../core/utils/web_payment_stub.dart'
    if (dart.library.html) '../../../core/utils/web_payment_helper.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final DoctorModel doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeSlotModel? _selectedSlot;
  String? _selectedHospitalId;
  final _reasonController = TextEditingController();
  Map<String, List<TimeSlotModel>> _availableSlotsByHospital = {};
  List<Hospital> _doctorHospitals = [];
  bool _isLoadingSlots = false;
  bool _isBooking = false;
  
  // Payment related state
  PaymentMethod _selectedPaymentMethod = PaymentMethod.payInPerson;
  final PaymentService _paymentService = PaymentService();
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _loadDoctorHospitals();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorHospitals() async {
    // TODO: Fetch hospitals where this doctor practices
    // For now, using mock data
    _doctorHospitals = [
      Hospital(
        id: 'h1',
        name: 'City General Hospital',
        address: '123 Main St',
        city: 'Dhaka',
        phone: '+880 1234567890',
        email: 'info@citygeneral.com',
        imageUrl: '',
        rating: 4.5,
        totalReviews: 100,
        specialties: [],
        isEmergencyAvailable: true,
        description: '',
      ),
      Hospital(
        id: 'h2',
        name: 'Medicare Center',
        address: '456 Park Ave',
        city: 'Dhaka',
        phone: '+880 1234567891',
        email: 'info@medicare.com',
        imageUrl: '',
        rating: 4.3,
        totalReviews: 80,
        specialties: [],
        isEmergencyAvailable: true,
        description: '',
      ),
    ];
    
    if (_doctorHospitals.isNotEmpty) {
      setState(() {
        _selectedHospitalId = _doctorHospitals.first.id;
      });
      _loadAvailableSlots();
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedHospitalId == null) return;
    
    setState(() => _isLoadingSlots = true);

    // TODO: Fetch from Firestore based on doctor schedule, date, and hospital
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock available slots grouped by hospital
    _availableSlotsByHospital = {
      'h1': [
        TimeSlotModel(
          slotId: '1',
          start: '14:00',
          end: '14:30',
          hospitalId: 'h1',
          hospitalName: 'City General Hospital',
        ),
        TimeSlotModel(
          slotId: '2',
          start: '14:30',
          end: '15:00',
          hospitalId: 'h1',
          hospitalName: 'City General Hospital',
        ),
        TimeSlotModel(
          slotId: '3',
          start: '15:00',
          end: '15:30',
          isBooked: true,
          hospitalId: 'h1',
          hospitalName: 'City General Hospital',
        ),
        TimeSlotModel(
          slotId: '4',
          start: '15:30',
          end: '16:00',
          hospitalId: 'h1',
          hospitalName: 'City General Hospital',
        ),
        TimeSlotModel(
          slotId: '5',
          start: '16:00',
          end: '16:30',
          hospitalId: 'h1',
          hospitalName: 'City General Hospital',
        ),
      ],
      'h2': [
        TimeSlotModel(
          slotId: '7',
          start: '17:30',
          end: '18:00',
          hospitalId: 'h2',
          hospitalName: 'Medicare Center',
        ),
        TimeSlotModel(
          slotId: '8',
          start: '18:00',
          end: '18:30',
          hospitalId: 'h2',
          hospitalName: 'Medicare Center',
        ),
        TimeSlotModel(
          slotId: '9',
          start: '18:30',
          end: '19:00',
          hospitalId: 'h2',
          hospitalName: 'Medicare Center',
        ),
        TimeSlotModel(
          slotId: '10',
          start: '19:00',
          end: '19:30',
          isBooked: true,
          hospitalId: 'h2',
          hospitalName: 'Medicare Center',
        ),
      ],
    };

    setState(() => _isLoadingSlots = false);
  }

  Future<void> _bookAppointment() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book an appointment')),
      );
      return;
    }

    // If online payment selected, process payment first
    if (_selectedPaymentMethod == PaymentMethod.online) {
      await _processOnlinePayment(user);
    } else {
      // Pay in person - directly book appointment
      await _saveAppointment(
        user: user,
        paymentStatus: PaymentStatus.pending,
        paymentMethod: PaymentMethod.payInPerson,
      );
    }
  }

  Future<void> _processOnlinePayment(User user) async {
    setState(() => _isProcessingPayment = true);

    try {
      // Get patient info
      final patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final patientData = patientDoc.data() ?? {};
      final patientName = patientData['name'] ?? 'Patient';
      final patientEmail = patientData['email'] ?? user.email ?? 'patient@example.com';
      final patientPhone = patientData['phone'] ?? '01700000000';

      // Ensure minimum amount for SSLCommerz (minimum 10 BDT)
      final amount = widget.doctor.consultationFee > 0 ? widget.doctor.consultationFee : 10.0;

      debugPrint('=== PAYMENT DEBUG ===');
      debugPrint('Platform: ${kIsWeb ? "Web" : "Mobile"}');
      debugPrint('Amount: $amount BDT');
      debugPrint('Patient: $patientName');

      if (kIsWeb) {
        // Web: Use HTTP gateway URL approach
        final transactionId = _paymentService.generateTransactionId();

        final result = await _paymentService.initializePayment(
          patientName: patientName,
          patientEmail: patientEmail,
          patientPhone: patientPhone,
          doctorName: widget.doctor.name,
          amount: amount,
          transactionId: transactionId,
        );

        if (mounted) {
          setState(() => _isProcessingPayment = false);

          if (result.success && result.gatewayUrl != null) {
            await _handleWebPayment(user, transactionId, result);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Mobile (Android/iOS): Use native SSLCommerz SDK
        debugPrint('Using native SSLCommerz SDK...');
        
        final result = await _paymentService.processNativePayment(
          context: context,
          amount: amount,
          patientName: patientName,
          patientEmail: patientEmail,
          patientPhone: patientPhone,
          doctorName: widget.doctor.name,
          appointmentDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        );

        debugPrint('Payment result: ${result.status} - ${result.message}');

        if (mounted) {
          setState(() => _isProcessingPayment = false);

          if (result.success) {
            // Payment successful - save appointment
            await _saveAppointment(
              user: user,
              paymentStatus: PaymentStatus.completed,
              paymentMethod: PaymentMethod.online,
              transactionId: result.transactionId,
              paymentDate: DateTime.now(),
            );
          } else if (result.status == 'closed') {
            // User cancelled payment
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment cancelled'),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            // Payment failed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Payment error: $e');
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleWebPayment(User user, String transactionId, PaymentResult result) async {
    // For web, open the gateway URL in a new tab
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Online Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ৳${widget.doctor.consultationFee.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'You will be redirected to SSLCommerz payment gateway.\n\n'
              'After completing payment, return here and confirm.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For sandbox testing, use card: 4111111111111111',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Open payment URL in browser
      openPaymentUrl(result.gatewayUrl!);
      
      // Show confirmation dialog after opening payment
      if (mounted) {
        final paymentCompleted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Payment Status'),
            content: const Text(
              'Did you complete the payment successfully?\n\n'
              'Click "Yes" only if you received a payment confirmation from SSLCommerz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No, Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Yes, Payment Done'),
              ),
            ],
          ),
        );

        if (paymentCompleted == true && mounted) {
          await _saveAppointment(
            user: user,
            paymentStatus: PaymentStatus.completed,
            paymentMethod: PaymentMethod.online,
            transactionId: transactionId,
            paymentDate: DateTime.now(),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open payment page: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAppointment({
    required User user,
    required PaymentStatus paymentStatus,
    required PaymentMethod paymentMethod,
    String? transactionId,
    DateTime? paymentDate,
  }) async {
    setState(() => _isBooking = true);

    try {
      final selectedFamilyMember = ref.read(selectedFamilyMemberProvider);
      final effectiveDoctorId = widget.doctor.userId.isNotEmpty 
          ? widget.doctor.userId 
          : widget.doctor.doctorId;

      // Duplicate Check: Same Doctor, Same Recipient (Self or specific family member), Same Day
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final querySnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: effectiveDoctorId)
          .where('patientId', isEqualTo: user.uid)
          .get();

      final hasDuplicate = querySnapshot.docs.any((doc) {
        final data = doc.data();
        final dateVal = data['date'];
        DateTime docDate;
        if (dateVal is Timestamp) {
          docDate = dateVal.toDate();
        } else if (dateVal is String) {
          docDate = DateTime.tryParse(dateVal) ?? DateTime.now();
        } else {
          return false;
        }

        final docFamilyMemberId = data['familyMemberId'];
        final targetFamilyMemberId = selectedFamilyMember?.id;

        final isSameDay = docDate.year == startOfDay.year &&
            docDate.month == startOfDay.month &&
            docDate.day == startOfDay.day;

        final isSameRecipient = docFamilyMemberId == targetFamilyMemberId;
        final status = data['status'];
        final isCancelled = status == 'cancelled';

        return isSameDay && isSameRecipient && !isCancelled;
      });

      if (hasDuplicate) {
        setState(() => _isBooking = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                selectedFamilyMember == null
                    ? 'You already have an appointment with this doctor on this day!'
                    : '${selectedFamilyMember.name} already has an appointment with this doctor on this day!',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      // Debug: Print doctor info
      debugPrint('=== BOOKING DEBUG ===');
      debugPrint('Doctor doctorId (doc ID): ${widget.doctor.doctorId}');
      debugPrint('Doctor userId (Auth UID): ${widget.doctor.userId}');
      debugPrint('Doctor name: ${widget.doctor.name}');
      debugPrint('Payment Method: ${paymentMethod.name}');
      debugPrint('Payment Status: ${paymentStatus.name}');
      
      // Get patient name from Firestore
      final patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final accountUserOwnerName = patientDoc.data()?['name'] ?? 'Patient';

      // Check if booking is for a selected family member
      final effectivePatientName = selectedFamilyMember != null 
          ? '${selectedFamilyMember.name} (${selectedFamilyMember.relationship})'
          : accountUserOwnerName;

      // Get hospital name
      final selectedHospital = _doctorHospitals.firstWhere(
        (h) => h.id == _selectedHospitalId,
        orElse: () => _doctorHospitals.first,
      );

      debugPrint('Using effective doctorId: $effectiveDoctorId');
      
      final docRef = FirebaseFirestore.instance.collection('appointments').doc();

      final appointment = AppointmentModel(
        appointmentId: docRef.id,
        doctorId: effectiveDoctorId,
        patientId: user.uid,
        doctorName: widget.doctor.name,
        patientName: effectivePatientName,
        familyMemberId: selectedFamilyMember?.id,
        familyMemberName: selectedFamilyMember?.name,
        specialization: widget.doctor.specialization,
        date: _selectedDate,
        timeSlotId: DateTime.now().millisecondsSinceEpoch.toString(),
        timeSlot: '${_selectedSlot!.start} - ${_selectedSlot!.end}',
        hospitalName: selectedHospital.name,
        status: AppointmentStatus.upcoming,
        reason: _reasonController.text.isNotEmpty 
            ? _reasonController.text 
            : 'General consultation',
        paymentStatus: paymentStatus,
        paymentMethod: paymentMethod,
        consultationFee: widget.doctor.consultationFee,
        transactionId: transactionId,
        paymentDate: paymentDate,
      );

      // Save to Firebase
      await docRef.set(appointment.toJson());

      // Generate PDF slip and notify patient
      await PdfGeneratorService.saveAndNotifyAppointmentPdf(appointment);

      // Reset selected family member state
      ref.read(selectedFamilyMemberProvider.notifier).state = null;

      debugPrint('=== APPOINTMENT SAVED ===');
      debugPrint('Saved appointmentId: ${appointment.appointmentId}');
      debugPrint('Saved doctorId: ${appointment.doctorId}');
      debugPrint('========================');

      if (mounted) {
        setState(() => _isBooking = false);
        
        // Show success dialog with PDF preview
        _showBookingSuccessDialog(appointment, paymentMethod, paymentStatus);
      }
    } catch (e) {
      debugPrint('Error booking appointment: $e');
      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBookingSuccessDialog(AppointmentModel appointment, PaymentMethod method, PaymentStatus status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppTheme.secondaryColor,
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Appointment Booked!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              method == PaymentMethod.online && status == PaymentStatus.completed
                  ? 'Payment successful! Your appointment is confirmed.'
                  : 'Your appointment is confirmed. Please pay ৳${widget.doctor.consultationFee.toStringAsFixed(0)} at the clinic.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: method == PaymentMethod.online && status == PaymentStatus.completed
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                method == PaymentMethod.online && status == PaymentStatus.completed
                    ? '✓ Paid Online'
                    : '⏱ Pay at Clinic',
                style: TextStyle(
                  color: method == PaymentMethod.online && status == PaymentStatus.completed
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => PdfGeneratorService.showPdfPreview(context, appointment),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 16),
            label: const Text('View / Download PDF Slip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border(
                        bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(
                            widget.doctor.name
                                .split(' ')
                                .map((e) => e[0])
                                .take(2)
                                .join(),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.doctor.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.doctor.specialization,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Select Patient / Family Member
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: FamilyMemberSelector(),
                  ),
                  const Divider(height: 1),

                  // Select Hospital
                  if (_doctorHospitals.length > 1)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Hospital',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          ..._doctorHospitals.map((hospital) {
                            final isSelected = _selectedHospitalId == hospital.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _HospitalCard(
                                hospital: hospital,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedHospitalId = hospital.id;
                                    _selectedSlot = null;
                                  });
                                  _loadAvailableSlots();
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                  const Divider(height: 1),
                  // Select Date
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Date',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 14,
                            itemBuilder: (context, index) {
                              final date =
                                  DateTime.now().add(Duration(days: index));
                              final isSelected = DateUtils.isSameDay(
                                date,
                                _selectedDate,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _DateCard(
                                  date: date,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = date;
                                      _selectedSlot = null;
                                    });
                                    _loadAvailableSlots();
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Select Time Slot
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Time Slot',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingSlots)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_selectedHospitalId == null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Please select a hospital first',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                              ),
                            ),
                          )
                        else if (_availableSlotsByHospital[_selectedHospitalId]?.isEmpty ?? true)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No slots available for this date at selected hospital',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: (_availableSlotsByHospital[_selectedHospitalId] ?? []).map((slot) {
                              final isSelected = _selectedSlot?.slotId == slot.slotId;
                              return _TimeSlotChip(
                                slot: slot,
                                isSelected: isSelected,
                                onTap: () {
                                  if (!slot.isBooked) {
                                    setState(() => _selectedSlot = slot);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Reason (Optional)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reason for Visit (Optional)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _reasonController,
                          label: 'Describe your symptoms',
                          hint: 'e.g., Fever, headache, chest pain...',
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Payment Method Selection
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Pay Online Option
                        _PaymentOptionTile(
                          title: 'Pay Online',
                          subtitle: 'Pay now using bKash, Nagad, Card, etc.',
                          icon: Icons.payment,
                          iconColor: Colors.green,
                          isSelected: _selectedPaymentMethod == PaymentMethod.online,
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = PaymentMethod.online;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Pay in Person Option
                        _PaymentOptionTile(
                          title: 'Pay at Clinic',
                          subtitle: 'Pay in cash or card at the clinic',
                          icon: Icons.account_balance_wallet,
                          iconColor: Colors.orange,
                          isSelected: _selectedPaymentMethod == PaymentMethod.payInPerson,
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = PaymentMethod.payInPerson;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Booking Summary & Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Fee Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consultation Fee',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedPaymentMethod == PaymentMethod.online
                                  ? 'Pay now via SSLCommerz'
                                  : 'Pay at clinic',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _selectedPaymentMethod == PaymentMethod.online
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '৳${widget.doctor.consultationFee.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Book/Pay Button
                  CustomButton(
                    text: _selectedPaymentMethod == PaymentMethod.online
                        ? 'Pay ৳${widget.doctor.consultationFee.toStringAsFixed(0)} & Book'
                        : 'Confirm Booking',
                    onPressed: _bookAppointment,
                    isLoading: _isBooking || _isProcessingPayment,
                    icon: _selectedPaymentMethod == PaymentMethod.online
                        ? Icons.lock
                        : Icons.check_circle,
                  ),
                  
                  if (_selectedPaymentMethod == PaymentMethod.online) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.security, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Secured by SSLCommerz',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Payment Option Tile Widget
class _PaymentOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.05) 
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor 
                : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateCard({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('EEE').format(date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('d').format(date),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (isToday) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  final TimeSlotModel slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: slot.isBooked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: slot.isBooked
              ? AppTheme.borderColor
              : isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: slot.isBooked
                ? AppTheme.borderColor
                : isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.borderColor,
          ),
        ),
        child: Text(
          slot.displayTime,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: slot.isBooked
                    ? AppTheme.textSecondaryColor
                    : isSelected
                        ? Colors.white
                        : AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w500,
                decoration: slot.isBooked ? TextDecoration.lineThrough : null,
              ),
        ),
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final bool isSelected;
  final VoidCallback onTap;

  const _HospitalCard({
    required this.hospital,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.secondaryColor.withOpacity(0.1)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.secondaryColor
                : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.secondaryColor.withOpacity(0.2)
                    : AppTheme.borderColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_hospital,
                color: isSelected
                    ? AppTheme.secondaryColor
                    : AppTheme.textSecondaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospital.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? AppTheme.secondaryColor
                              : AppTheme.textPrimaryColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${hospital.address}, ${hospital.city}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.secondaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
