import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/time_slot_model.dart';

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({super.key});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  Map<int, List<TimeSlotModel>> _schedule = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    _schedule = {
      1: [
        TimeSlotModel(slotId: '1', start: '09:00', end: '09:30'),
        TimeSlotModel(slotId: '2', start: '09:30', end: '10:00'),
        TimeSlotModel(slotId: '3', start: '10:00', end: '10:30'),
      ],
      2: [
        TimeSlotModel(slotId: '4', start: '09:00', end: '09:30'),
        TimeSlotModel(slotId: '5', start: '10:00', end: '10:30'),
      ],
    };

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              itemBuilder: (context, index) {
                return _DayScheduleCard(
                  dayIndex: index,
                  dayName: AppConstants.weekDays[index],
                  slots: _schedule[index] ?? [],
                  onEdit: () => _editDaySchedule(index),
                );
              },
            ),
    );
  }

  void _editDaySchedule(int dayIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit ${AppConstants.weekDays[dayIndex]} Schedule',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // TODO: Add time slot selection UI
                      const Text('Select time slots:'),
                      // Add checkboxes or chips for available time slots
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Save Schedule',
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Save to Firestore
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayScheduleCard extends StatelessWidget {
  final int dayIndex;
  final String dayName;
  final List<TimeSlotModel> slots;
  final VoidCallback onEdit;

  const _DayScheduleCard({
    required this.dayIndex,
    required this.dayName,
    required this.slots,
    required this.onEdit,
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
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (slots.isEmpty)
              Text(
                'No schedule set',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slots.map((slot) {
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
