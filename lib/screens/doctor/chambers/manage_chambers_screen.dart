import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/chamber_model.dart';

class ManageChambersScreen extends StatefulWidget {
  const ManageChambersScreen({super.key});

  @override
  State<ManageChambersScreen> createState() => _ManageChambersScreenState();
}

class _ManageChambersScreenState extends State<ManageChambersScreen> {
  List<Chamber> _chambers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChambers();
  }

  Future<void> _loadChambers() async {
    setState(() => _isLoading = true);
    
    // TODO: Fetch from Firebase
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data
    _chambers = [
      Chamber(
        id: '1',
        name: 'City Clinic',
        address: '123 Main Street, Gulshan',
        city: 'Dhaka',
        phone: '+880 1712-345678',
        consultationFee: 1500,
        workingHours: {
          'Monday': WorkingHours(startTime: '09:00', endTime: '17:00'),
          'Wednesday': WorkingHours(startTime: '09:00', endTime: '17:00'),
          'Friday': WorkingHours(startTime: '09:00', endTime: '17:00'),
        },
      ),
    ];
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Chambers'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadChambers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _chambers.length + 1,
                itemBuilder: (context, index) {
                  if (index == _chambers.length) {
                    return _AddChamberButton(
                      onTap: () => _showAddChamberDialog(),
                    );
                  }
                  
                  return _ChamberCard(
                    chamber: _chambers[index],
                    onEdit: () => _showEditChamberDialog(_chambers[index]),
                    onDelete: () => _deleteChamber(_chambers[index].id),
                  );
                },
              ),
            ),
    );
  }

  void _showAddChamberDialog() {
    showDialog(
      context: context,
      builder: (context) => _ChamberDialog(
        onSave: (chamber) {
          setState(() => _chambers.add(chamber));
          // TODO: Save to Firebase
        },
      ),
    );
  }

  void _showEditChamberDialog(Chamber chamber) {
    showDialog(
      context: context,
      builder: (context) => _ChamberDialog(
        chamber: chamber,
        onSave: (updatedChamber) {
          setState(() {
            final index = _chambers.indexWhere((c) => c.id == updatedChamber.id);
            if (index != -1) {
              _chambers[index] = updatedChamber;
            }
          });
          // TODO: Update in Firebase
        },
      ),
    );
  }

  void _deleteChamber(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chamber'),
        content: const Text('Are you sure you want to delete this chamber?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _chambers.removeWhere((c) => c.id == id));
              Navigator.pop(context);
              // TODO: Delete from Firebase
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddChamberButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddChamberButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 48,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                'Add New Chamber',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChamberCard extends StatelessWidget {
  final Chamber chamber;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChamberCard({
    required this.chamber,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_hospital,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chamber.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        chamber.city,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  color: AppTheme.primaryColor,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: AppTheme.errorColor,
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.location_on,
              label: chamber.address,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.phone,
              label: chamber.phone,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.attach_money,
              label: 'Consultation Fee: ৳${chamber.consultationFee.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 12),
            Text(
              'Working Days',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chamber.workingHours.entries.map((entry) {
                return Chip(
                  label: Text(
                    '${entry.key}: ${entry.value.startTime} - ${entry.value.endTime}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _ChamberDialog extends StatefulWidget {
  final Chamber? chamber;
  final Function(Chamber) onSave;

  const _ChamberDialog({
    this.chamber,
    required this.onSave,
  });

  @override
  State<_ChamberDialog> createState() => _ChamberDialogState();
}

class _ChamberDialogState extends State<_ChamberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  late final TextEditingController _feeController;
  
  final Map<String, WorkingHours> _workingHours = {};
  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.chamber?.name);
    _addressController = TextEditingController(text: widget.chamber?.address);
    _cityController = TextEditingController(text: widget.chamber?.city);
    _phoneController = TextEditingController(text: widget.chamber?.phone);
    _feeController = TextEditingController(
      text: widget.chamber?.consultationFee.toStringAsFixed(0),
    );
    
    if (widget.chamber != null) {
      _workingHours.addAll(widget.chamber!.workingHours);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chamber == null ? 'Add Chamber' : 'Edit Chamber',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _nameController,
                  label: 'Chamber Name',
                  prefixIcon: Icons.local_hospital,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter chamber name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  label: 'Address',
                  prefixIcon: Icons.location_on,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _cityController,
                  label: 'City',
                  prefixIcon: Icons.location_city,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _feeController,
                  label: 'Consultation Fee (৳)',
                  prefixIcon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter fee';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Working Hours',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ..._days.map((day) => _DaySelector(
                      day: day,
                      workingHours: _workingHours[day],
                      onChanged: (hours) {
                        setState(() {
                          if (hours != null) {
                            _workingHours[day] = hours;
                          } else {
                            _workingHours.remove(day);
                          }
                        });
                      },
                    )),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: 'Save',
                      onPressed: _saveChamber,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveChamber() {
    if (_formKey.currentState!.validate()) {
      final chamber = Chamber(
        id: widget.chamber?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        address: _addressController.text,
        city: _cityController.text,
        phone: _phoneController.text,
        consultationFee: double.parse(_feeController.text),
        workingHours: _workingHours,
      );
      
      widget.onSave(chamber);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _feeController.dispose();
    super.dispose();
  }
}

class _DaySelector extends StatelessWidget {
  final String day;
  final WorkingHours? workingHours;
  final Function(WorkingHours?) onChanged;

  const _DaySelector({
    required this.day,
    required this.workingHours,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = workingHours != null;

    return CheckboxListTile(
      title: Text(day),
      subtitle: isSelected
          ? Text('${workingHours!.startTime} - ${workingHours!.endTime}')
          : null,
      value: isSelected,
      onChanged: (value) {
        if (value == true) {
          _selectTime(context);
        } else {
          onChanged(null);
        }
      },
      secondary: isSelected
          ? IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _selectTime(context),
            )
          : null,
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select Start Time',
    );

    if (startTime == null) return;

    if (!context.mounted) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select End Time',
    );

    if (endTime == null) return;

    onChanged(WorkingHours(
      startTime: startTime.format(context),
      endTime: endTime.format(context),
    ));
  }
}
