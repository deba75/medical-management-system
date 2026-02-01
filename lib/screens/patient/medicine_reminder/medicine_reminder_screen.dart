import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/medicine_reminder_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/medicine_reminder_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MedicineReminderScreen extends ConsumerStatefulWidget {
  const MedicineReminderScreen({super.key});

  @override
  ConsumerState<MedicineReminderScreen> createState() => _MedicineReminderScreenState();
}

class _MedicineReminderScreenState extends ConsumerState<MedicineReminderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _reminderService = MedicineReminderService();
  final _patientId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Medicine Reminders'),
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 60),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 70),
                      child: _buildAdherenceCard(),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Today'),
                  Tab(text: 'All Medicines'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTodayTab(),
            _buildAllMedicinesTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildAdherenceCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reminderService.getAdherenceStats(_patientId),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {
          'adherenceRate': 0.0,
          'activeReminders': 0,
          'takenDoses': 0,
          'totalDoses': 0,
        };

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${stats['adherenceRate']?.toStringAsFixed(0) ?? 0}%',
                'Adherence',
                Icons.trending_up,
              ),
              _buildStatItem(
                '${stats['activeReminders'] ?? 0}',
                'Active',
                Icons.medication,
              ),
              _buildStatItem(
                '${stats['takenDoses'] ?? 0}/${stats['totalDoses'] ?? 0}',
                'Taken',
                Icons.check_circle,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayTab() {
    return StreamBuilder<List<MedicineReminderModel>>(
      stream: _reminderService.getTodayReminders(_patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reminders = snapshot.data ?? [];

        if (reminders.isEmpty) {
          return _buildEmptyState(
            'No medicines for today',
            'Add your medicines to get timely reminders',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            return _buildTodayReminderCard(reminders[index]);
          },
        );
      },
    );
  }

  Widget _buildTodayReminderCard(MedicineReminderModel reminder) {
    final now = DateTime.now();
    final todayTaken = reminder.takenHistory
        .where((dt) =>
            dt.year == now.year && dt.month == now.month && dt.day == now.day)
        .length;

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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reminder.medicineTypeIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.medicineName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${reminder.dosage} • ${reminder.mealTiming.name.replaceAll('meal', ' meal').replaceAll('M', ' M')}',
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
                    color: todayTaken >= reminder.timings.length
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$todayTaken/${reminder.timings.length}',
                    style: TextStyle(
                      color: todayTaken >= reminder.timings.length
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Today\'s Schedule',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reminder.timings.map((time) {
                final timeParts = time.split(':');
                final hour = int.tryParse(timeParts[0]) ?? 0;
                final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
                final scheduleTime = DateTime(now.year, now.month, now.day, hour, minute);
                final isPast = scheduleTime.isBefore(now);
                final isTaken = reminder.takenHistory.any((dt) =>
                    dt.year == now.year &&
                    dt.month == now.month &&
                    dt.day == now.day &&
                    dt.hour == hour);

                return InkWell(
                  onTap: isTaken
                      ? null
                      : () => _markAsTaken(reminder.id, time),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isTaken
                          ? Colors.green.withValues(alpha: 0.1)
                          : isPast
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isTaken
                            ? Colors.green
                            : isPast
                                ? Colors.red
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTaken
                              ? Icons.check_circle
                              : isPast
                                  ? Icons.warning
                                  : Icons.access_time,
                          size: 16,
                          color: isTaken
                              ? Colors.green
                              : isPast
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          time,
                          style: TextStyle(
                            color: isTaken
                                ? Colors.green
                                : isPast
                                    ? Colors.red
                                    : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildAllMedicinesTab() {
    return StreamBuilder<List<MedicineReminderModel>>(
      stream: _reminderService.getRemindersForPatient(_patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reminders = snapshot.data ?? [];

        if (reminders.isEmpty) {
          return _buildEmptyState(
            'No medicines added',
            'Add your medicines to track your medication schedule',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            return _buildMedicineCard(reminders[index]);
          },
        );
      },
    );
  }

  Widget _buildMedicineCard(MedicineReminderModel reminder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showMedicineDetails(reminder),
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
                child: Text(
                  reminder.medicineTypeIcon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.medicineName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reminder.dosage} • ${reminder.frequency.name}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    if (reminder.doctorName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Prescribed by Dr. ${reminder.doctorName}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '${reminder.adherenceRate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: reminder.adherenceRate >= 80
                          ? Colors.green
                          : reminder.adherenceRate >= 50
                              ? Colors.orange
                              : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'adherence',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
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

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
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
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _markAsTaken(String reminderId, String time) async {
    try {
      final now = DateTime.now();
      final timeParts = time.split(':');
      final hour = int.tryParse(timeParts[0]) ?? now.hour;
      final takenAt = DateTime(now.year, now.month, now.day, hour);
      
      await _reminderService.markAsTaken(reminderId, takenAt);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine marked as taken!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMedicineDetails(MedicineReminderModel reminder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        reminder.medicineTypeIcon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.medicineName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            reminder.medicineType.name.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Dosage', reminder.dosage),
                _buildDetailRow('Frequency', reminder.frequency.name),
                _buildDetailRow('Timings', reminder.timings.join(', ')),
                _buildDetailRow('Meal Timing', reminder.mealTiming.name.replaceAll('meal', ' meal')),
                _buildDetailRow('Start Date', DateFormat('MMM d, yyyy').format(reminder.startDate)),
                if (reminder.endDate != null)
                  _buildDetailRow('End Date', DateFormat('MMM d, yyyy').format(reminder.endDate!)),
                if (reminder.doctorName != null)
                  _buildDetailRow('Prescribed by', 'Dr. ${reminder.doctorName}'),
                if (reminder.notes != null && reminder.notes!.isNotEmpty)
                  _buildDetailRow('Notes', reminder.notes!),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.analytics, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Adherence Rate',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${reminder.takenDoses} of ${reminder.totalDoses} doses taken (${reminder.adherenceRate.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteReminder(reminder);
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditReminderDialog(reminder);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    _showReminderFormDialog(context, null);
  }

  void _showEditReminderDialog(MedicineReminderModel reminder) {
    _showReminderFormDialog(context, reminder);
  }

  void _showReminderFormDialog(BuildContext context, MedicineReminderModel? existingReminder) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingReminder?.medicineName ?? '');
    final dosageController = TextEditingController(text: existingReminder?.dosage ?? '');
    final notesController = TextEditingController(text: existingReminder?.notes ?? '');
    
    MedicineType selectedType = existingReminder?.medicineType ?? MedicineType.tablet;
    FrequencyType selectedFrequency = existingReminder?.frequency ?? FrequencyType.daily;
    MealTiming selectedMealTiming = existingReminder?.mealTiming ?? MealTiming.afterMeal;
    List<String> selectedTimings = existingReminder?.timings ?? ['08:00'];
    DateTime startDate = existingReminder?.startDate ?? DateTime.now();
    DateTime? endDate = existingReminder?.endDate;

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
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
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
                          existingReminder != null ? 'Edit Medicine' : 'Add Medicine',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Medicine Name',
                            prefixIcon: Icon(Icons.medication),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter medicine name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<MedicineType>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Medicine Type',
                            prefixIcon: Icon(Icons.category),
                            border: OutlineInputBorder(),
                          ),
                          items: MedicineType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() => selectedType = value!);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: dosageController,
                          decoration: const InputDecoration(
                            labelText: 'Dosage (e.g., 500mg, 1 tablet)',
                            prefixIcon: Icon(Icons.scale),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter dosage';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<FrequencyType>(
                          value: selectedFrequency,
                          decoration: const InputDecoration(
                            labelText: 'Frequency',
                            prefixIcon: Icon(Icons.repeat),
                            border: OutlineInputBorder(),
                          ),
                          items: FrequencyType.values.map((freq) {
                            return DropdownMenuItem(
                              value: freq,
                              child: Text(freq.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() => selectedFrequency = value!);
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<MealTiming>(
                          value: selectedMealTiming,
                          decoration: const InputDecoration(
                            labelText: 'Meal Timing',
                            prefixIcon: Icon(Icons.restaurant),
                            border: OutlineInputBorder(),
                          ),
                          items: MealTiming.values.map((timing) {
                            return DropdownMenuItem(
                              value: timing,
                              child: Text(timing.name.replaceAll('meal', ' Meal').replaceAll('M', ' M')),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() => selectedMealTiming = value!);
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Reminder Times',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ...selectedTimings.map((time) {
                              return Chip(
                                label: Text(time),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () {
                                  setModalState(() {
                                    selectedTimings.remove(time);
                                  });
                                },
                              );
                            }),
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 18),
                              label: const Text('Add Time'),
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setModalState(() {
                                    selectedTimings.add(
                                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                    );
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            prefixIcon: Icon(Icons.notes),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                if (selectedTimings.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please add at least one reminder time'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final reminder = MedicineReminderModel(
                                  id: existingReminder?.id ?? '',
                                  patientId: _patientId,
                                  medicineName: nameController.text,
                                  medicineType: selectedType,
                                  dosage: dosageController.text,
                                  frequency: selectedFrequency,
                                  timings: selectedTimings,
                                  mealTiming: selectedMealTiming,
                                  startDate: startDate,
                                  endDate: endDate,
                                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                                  isActive: true,
                                  totalDoses: existingReminder?.totalDoses ?? 0,
                                  takenDoses: existingReminder?.takenDoses ?? 0,
                                  takenHistory: existingReminder?.takenHistory ?? [],
                                  createdAt: existingReminder?.createdAt ?? DateTime.now(),
                                );

                                try {
                                  if (existingReminder != null) {
                                    await _reminderService.updateReminder(
                                      existingReminder.id,
                                      reminder.toJson(),
                                    );
                                  } else {
                                    await _reminderService.createReminder(reminder);
                                  }
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(existingReminder != null
                                            ? 'Medicine updated successfully'
                                            : 'Medicine added successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(existingReminder != null ? 'Update Medicine' : 'Add Medicine'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteReminder(MedicineReminderModel reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text('Are you sure you want to delete "${reminder.medicineName}" from your reminders?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _reminderService.deactivateReminder(reminder.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Medicine deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
