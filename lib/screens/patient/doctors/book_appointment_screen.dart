import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/doctor_model.dart';
import '../../../models/time_slot_model.dart';
import '../../../models/hospital_model.dart';

class BookAppointmentScreen extends StatefulWidget {
  final DoctorModel doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeSlotModel? _selectedSlot;
  String? _selectedHospitalId;
  final _reasonController = TextEditingController();
  Map<String, List<TimeSlotModel>> _availableSlotsByHospital = {};
  List<Hospital> _doctorHospitals = [];
  bool _isLoadingSlots = false;
  bool _isBooking = false;

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

    setState(() => _isBooking = true);

    // TODO: Call Cloud Function to validate and book
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isBooking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
      Navigator.pop(context);
      Navigator.pop(context);
    }
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
                      color: AppTheme.surfaceColor,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderColor),
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
                ],
              ),
            ),
          ),

          // Booking Summary & Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                top: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Consultation Fee',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '₹${widget.doctor.consultationFee}',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Confirm Booking',
                    onPressed: _bookAppointment,
                    isLoading: _isBooking,
                  ),
                ],
              ),
            ),
          ),
        ],
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
