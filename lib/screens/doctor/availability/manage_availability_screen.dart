import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/chamber_model.dart';

class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  State<ManageAvailabilityScreen> createState() => _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  DateTime _selectedDate = DateTime.now();
  DoctorAvailability? _availability;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    
    // TODO: Fetch from Firebase
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock data
    _availability = DoctorAvailability(
      id: '1',
      doctorId: 'doc1',
      chamberId: 'chamber1',
      date: _selectedDate,
      slots: [
        TimeSlotAvailability(
          startTime: '10:00 AM',
          endTime: '10:30 AM',
          isBooked: false,
          appointmentId: null,
        ),
        TimeSlotAvailability(
          startTime: '11:00 AM',
          endTime: '11:30 AM',
          isBooked: true,
          appointmentId: 'apt1',
        ),
        TimeSlotAvailability(
          startTime: '2:00 PM',
          endTime: '2:30 PM',
          isBooked: false,
          appointmentId: null,
        ),
      ],
      isLeave: false,
      leaveReason: null,
    );
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_busy),
            onPressed: _markLeave,
            tooltip: 'Mark Leave',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          _buildWeekCalendar(),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildDaySchedule(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewSlot,
        icon: const Icon(Icons.add),
        label: const Text('Add Slot'),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 7));
              });
              _loadAvailability();
            },
          ),
          Column(
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Week ${_getWeekNumber(_selectedDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 7));
              });
              _loadAvailability();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCalendar() {
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = startOfWeek.add(Duration(days: index));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(_selectedDate);
          final isToday = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _loadAvailability();
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : isToday
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.borderColor,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  Widget _buildDaySchedule() {
    if (_availability == null) {
      return const Center(child: Text('No availability data'));
    }

    if (_availability!.isLeave) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Marked as Leave',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_availability!.leaveReason != null) ...[
              const SizedBox(height: 8),
              Text(
                _availability!.leaveReason!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _unmarkLeave,
              child: const Text('Remove Leave'),
            ),
          ],
        ),
      );
    }

    if (_availability!.slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_available,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No slots added yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add slots',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availability!.slots.length,
      itemBuilder: (context, index) {
        final slotAvailability = _availability!.slots[index];
        return _SlotCard(
          slotAvailability: slotAvailability,
          onDelete: () => _deleteSlot(slotAvailability),
          onToggle: () => _toggleSlot(slotAvailability),
        );
      },
    );
  }

  Future<void> _addNewSlot() async {
    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );

    if (startTime == null) return;

    TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: startTime.hour,
        minute: startTime.minute + 30,
      ),
    );

    if (endTime == null) return;

    // TODO: Add to Firebase
    setState(() {
      _availability?.slots.add(
        TimeSlotAvailability(
          startTime: _formatTimeOfDay(startTime),
          endTime: _formatTimeOfDay(endTime),
          isBooked: false,
          appointmentId: null,
        ),
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot added successfully')),
      );
    }
  }

  Future<void> _deleteSlot(TimeSlotAvailability slotAvailability) async {
    if (slotAvailability.isBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete booked slot'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slot'),
        content: const Text('Are you sure you want to delete this slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Delete from Firebase
      setState(() {
        _availability?.slots.remove(slotAvailability);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot deleted')),
        );
      }
    }
  }

  void _toggleSlot(TimeSlotAvailability slotAvailability) {
    if (slotAvailability.isBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot modify booked slot'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Note: TimeSlotAvailability doesn't have toggle, only delete
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Use delete to remove slots')),
    );
  }

  Future<void> _markLeave() async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mark ${DateFormat('MMM dd, yyyy').format(_selectedDate)} as leave?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
            child: const Text('Mark Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Save to Firebase
      setState(() {
        _availability = DoctorAvailability(
          id: _availability!.id,
          doctorId: _availability!.doctorId,
          chamberId: _availability!.chamberId,
          date: _availability!.date,
          slots: [],
          isLeave: true,
          leaveReason: controller.text.isEmpty ? null : controller.text,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave marked successfully')),
        );
      }
    }
  }

  void _unmarkLeave() {
    // TODO: Update in Firebase
    setState(() {
      _availability = DoctorAvailability(
        id: _availability!.id,
        doctorId: _availability!.doctorId,
        chamberId: _availability!.chamberId,
        date: _availability!.date,
        slots: [],
        isLeave: false,
        leaveReason: null,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leave removed')),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil() + 1;
  }
}

class _SlotCard extends StatelessWidget {
  final TimeSlotAvailability slotAvailability;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _SlotCard({
    required this.slotAvailability,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isBooked = slotAvailability.isBooked;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isBooked) {
      statusColor = AppTheme.errorColor;
      statusText = 'Booked';
      statusIcon = Icons.event_busy;
    } else {
      statusColor = Colors.green;
      statusText = 'Available';
      statusIcon = Icons.event_available;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text('${slotAvailability.startTime} - ${slotAvailability.endTime}'),
        subtitle: isBooked
            ? Text('Appointment ID: ${slotAvailability.appointmentId}')
            : Text(statusText),
        trailing: !isBooked
            ? IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.errorColor,
                ),
                onPressed: onDelete,
                tooltip: 'Delete',
              )
            : Chip(
                label: Text(statusText),
                backgroundColor: statusColor.withOpacity(0.1),
                labelStyle: TextStyle(color: statusColor, fontSize: 12),
              ),
      ),
    );
  }
}
