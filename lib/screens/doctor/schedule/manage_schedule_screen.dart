import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/time_slot_model.dart';
import '../../../models/hospital_model.dart';

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({super.key});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  // Changed structure: Map<dayIndex, Map<hospitalId, List<TimeSlotModel>>>
  Map<int, Map<String, HospitalSchedule>> _schedule = {};
  List<Hospital> _availableHospitals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    // Mock hospitals
    _availableHospitals = [
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

    // Mock schedule data - example: Monday at City General 2-5pm, Medicare 5:30-8:30pm
    _schedule = {
      1: {
        'h1': HospitalSchedule(
          hospital: _availableHospitals[0],
          slots: [
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
            TimeSlotModel(
              slotId: '6',
              start: '16:30',
              end: '17:00',
              hospitalId: 'h1',
              hospitalName: 'City General Hospital',
            ),
          ],
        ),
        'h2': HospitalSchedule(
          hospital: _availableHospitals[1],
          slots: [
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
              hospitalId: 'h2',
              hospitalName: 'Medicare Center',
            ),
            TimeSlotModel(
              slotId: '11',
              start: '19:30',
              end: '20:00',
              hospitalId: 'h2',
              hospitalName: 'Medicare Center',
            ),
            TimeSlotModel(
              slotId: '12',
              start: '20:00',
              end: '20:30',
              hospitalId: 'h2',
              hospitalName: 'Medicare Center',
            ),
          ],
        ),
      },
    };

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addHospitalSchedule(),
            tooltip: 'Add Hospital Schedule',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              itemBuilder: (context, index) {
                final daySchedules = _schedule[index] ?? {};
                return _DayScheduleCard(
                  dayIndex: index,
                  dayName: AppConstants.weekDays[index],
                  hospitalSchedules: daySchedules,
                  onAddHospital: () => _addHospitalToDay(index),
                  onEditHospital: (hospitalId) => _editHospitalSchedule(index, hospitalId),
                  onDeleteHospital: (hospitalId) => _deleteHospitalSchedule(index, hospitalId),
                );
              },
            ),
    );
  }

  void _addHospitalSchedule() {
    // Global add - choose day first
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Select a day below to add hospital schedule'),
      ),
    );
  }

  void _addHospitalToDay(int dayIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddHospitalScheduleSheet(
        dayIndex: dayIndex,
        dayName: AppConstants.weekDays[dayIndex],
        availableHospitals: _availableHospitals,
        existingHospitalIds: _schedule[dayIndex]?.keys.toList() ?? [],
        onSave: (hospitalId, slots) {
          setState(() {
            final hospital = _availableHospitals.firstWhere((h) => h.id == hospitalId);
            if (_schedule[dayIndex] == null) {
              _schedule[dayIndex] = {};
            }
            _schedule[dayIndex]![hospitalId] = HospitalSchedule(
              hospital: hospital,
              slots: slots,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule added successfully')),
          );
        },
      ),
    );
  }

  void _editHospitalSchedule(int dayIndex, String hospitalId) {
    final currentSchedule = _schedule[dayIndex]?[hospitalId];
    if (currentSchedule == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditHospitalScheduleSheet(
        dayIndex: dayIndex,
        dayName: AppConstants.weekDays[dayIndex],
        hospital: currentSchedule.hospital,
        currentSlots: currentSchedule.slots,
        onSave: (slots) {
          setState(() {
            _schedule[dayIndex]![hospitalId] = HospitalSchedule(
              hospital: currentSchedule.hospital,
              slots: slots,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule updated successfully')),
          );
        },
      ),
    );
  }

  void _deleteHospitalSchedule(int dayIndex, String hospitalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this hospital schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _schedule[dayIndex]?.remove(hospitalId);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Schedule deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class HospitalSchedule {
  final Hospital hospital;
  final List<TimeSlotModel> slots;

  HospitalSchedule({
    required this.hospital,
    required this.slots,
  });
}

class _DayScheduleCard extends StatelessWidget {
  final int dayIndex;
  final String dayName;
  final Map<String, HospitalSchedule> hospitalSchedules;
  final VoidCallback onAddHospital;
  final Function(String) onEditHospital;
  final Function(String) onDeleteHospital;

  const _DayScheduleCard({
    required this.dayIndex,
    required this.dayName,
    required this.hospitalSchedules,
    required this.onAddHospital,
    required this.onEditHospital,
    required this.onDeleteHospital,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateTime.now().weekday % 7 == dayIndex;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      dayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onAddHospital,
                  tooltip: 'Add Hospital',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hospitalSchedules.isEmpty)
              Text(
                'No schedule set for this day',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              )
            else
              ...hospitalSchedules.entries.map((entry) {
                final hospitalSchedule = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_hospital,
                                  size: 20,
                                  color: AppTheme.secondaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    hospitalSchedule.hospital.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.secondaryColor,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => onEditHospital(entry.key),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: AppTheme.errorColor,
                                ),
                                onPressed: () => onDeleteHospital(entry.key),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: hospitalSchedule.slots.map((slot) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              slot.displayTime,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class _AddHospitalScheduleSheet extends StatefulWidget {
  final int dayIndex;
  final String dayName;
  final List<Hospital> availableHospitals;
  final List<String> existingHospitalIds;
  final Function(String, List<TimeSlotModel>) onSave;

  const _AddHospitalScheduleSheet({
    required this.dayIndex,
    required this.dayName,
    required this.availableHospitals,
    required this.existingHospitalIds,
    required this.onSave,
  });

  @override
  State<_AddHospitalScheduleSheet> createState() =>
      _AddHospitalScheduleSheetState();
}

class _AddHospitalScheduleSheetState extends State<_AddHospitalScheduleSheet> {
  Hospital? _selectedHospital;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _slotDuration = 30;

  @override
  Widget build(BuildContext context) {
    final availableHospitals = widget.availableHospitals
        .where((h) => !widget.existingHospitalIds.contains(h.id))
        .toList();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add Schedule for ${widget.dayName}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          // Hospital Selection
          DropdownButtonFormField<Hospital>(
            value: _selectedHospital,
            decoration: const InputDecoration(
              labelText: 'Select Hospital',
              prefixIcon: Icon(Icons.local_hospital),
            ),
            items: availableHospitals.map((hospital) {
              return DropdownMenuItem(
                value: hospital,
                child: Text(hospital.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedHospital = value);
            },
          ),
          const SizedBox(height: 16),
          
          // Time Range
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(_startTime.format(context)),
                  leading: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (time != null) {
                      setState(() => _startTime = time);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ListTile(
                  title: const Text('End Time'),
                  subtitle: Text(_endTime.format(context)),
                  leading: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (time != null) {
                      setState(() => _endTime = time);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Slot Duration
          DropdownButtonFormField<int>(
            value: _slotDuration,
            decoration: const InputDecoration(
              labelText: 'Slot Duration (minutes)',
              prefixIcon: Icon(Icons.timer),
            ),
            items: [15, 30, 45, 60].map((duration) {
              return DropdownMenuItem(
                value: duration,
                child: Text('$duration minutes'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _slotDuration = value);
              }
            },
          ),
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _selectedHospital != null ? _saveSchedule : null,
            child: const Text('Save Schedule'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _saveSchedule() {
    if (_selectedHospital == null) return;

    // Generate time slots
    final slots = _generateTimeSlots();
    
    widget.onSave(_selectedHospital!.id, slots);
    Navigator.pop(context);
  }

  List<TimeSlotModel> _generateTimeSlots() {
    final slots = <TimeSlotModel>[];
    int slotId = 1;
    
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    
    for (int currentMinutes = startMinutes;
        currentMinutes < endMinutes;
        currentMinutes += _slotDuration) {
      final startHour = currentMinutes ~/ 60;
      final startMin = currentMinutes % 60;
      final endMin = (currentMinutes + _slotDuration);
      final endHour = endMin ~/ 60;
      final endMinute = endMin % 60;
      
      if (endMin > endMinutes) break;
      
      slots.add(TimeSlotModel(
        slotId: 'slot_$slotId',
        start: '${startHour.toString().padLeft(2, '0')}:${startMin.toString().padLeft(2, '0')}',
        end: '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
        hospitalId: _selectedHospital!.id,
        hospitalName: _selectedHospital!.name,
      ));
      slotId++;
    }
    
    return slots;
  }
}

class _EditHospitalScheduleSheet extends StatefulWidget {
  final int dayIndex;
  final String dayName;
  final Hospital hospital;
  final List<TimeSlotModel> currentSlots;
  final Function(List<TimeSlotModel>) onSave;

  const _EditHospitalScheduleSheet({
    required this.dayIndex,
    required this.dayName,
    required this.hospital,
    required this.currentSlots,
    required this.onSave,
  });

  @override
  State<_EditHospitalScheduleSheet> createState() =>
      _EditHospitalScheduleSheetState();
}

class _EditHospitalScheduleSheetState
    extends State<_EditHospitalScheduleSheet> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  int _slotDuration = 30;

  @override
  void initState() {
    super.initState();
    if (widget.currentSlots.isNotEmpty) {
      final firstSlot = widget.currentSlots.first;
      final lastSlot = widget.currentSlots.last;
      _startTime = _parseTime(firstSlot.start);
      _endTime = _parseTime(lastSlot.end);
      
      if (widget.currentSlots.length > 1) {
        final first = _parseTime(widget.currentSlots[0].start);
        final second = _parseTime(widget.currentSlots[1].start);
        _slotDuration = (second.hour - first.hour) * 60 + (second.minute - first.minute);
      }
    } else {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 17, minute: 0);
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit ${widget.dayName} Schedule',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.local_hospital,
                size: 20,
                color: AppTheme.secondaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                widget.hospital.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.secondaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Time Range
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(_startTime.format(context)),
                  leading: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (time != null) {
                      setState(() => _startTime = time);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ListTile(
                  title: const Text('End Time'),
                  subtitle: Text(_endTime.format(context)),
                  leading: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (time != null) {
                      setState(() => _endTime = time);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Slot Duration
          DropdownButtonFormField<int>(
            value: _slotDuration,
            decoration: const InputDecoration(
              labelText: 'Slot Duration (minutes)',
              prefixIcon: Icon(Icons.timer),
            ),
            items: [15, 30, 45, 60].map((duration) {
              return DropdownMenuItem(
                value: duration,
                child: Text('$duration minutes'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _slotDuration = value);
              }
            },
          ),
          const SizedBox(height: 24),
          
          CustomButton(
            text: 'Update Schedule',
            onPressed: _updateSchedule,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _updateSchedule() {
    final slots = _generateTimeSlots();
    widget.onSave(slots);
    Navigator.pop(context);
  }

  List<TimeSlotModel> _generateTimeSlots() {
    final slots = <TimeSlotModel>[];
    int slotId = 1;
    
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    
    for (int currentMinutes = startMinutes;
        currentMinutes < endMinutes;
        currentMinutes += _slotDuration) {
      final startHour = currentMinutes ~/ 60;
      final startMin = currentMinutes % 60;
      final endMin = (currentMinutes + _slotDuration);
      final endHour = endMin ~/ 60;
      final endMinute = endMin % 60;
      
      if (endMin > endMinutes) break;
      
      slots.add(TimeSlotModel(
        slotId: 'slot_$slotId',
        start: '${startHour.toString().padLeft(2, '0')}:${startMin.toString().padLeft(2, '0')}',
        end: '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
        hospitalId: widget.hospital.id,
        hospitalName: widget.hospital.name,
      ));
      slotId++;
    }
    
    return slots;
  }
}
