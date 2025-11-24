import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/ambulance_model.dart';

class BookAmbulanceScreen extends StatefulWidget {
  const BookAmbulanceScreen({super.key});

  @override
  State<BookAmbulanceScreen> createState() => _BookAmbulanceScreenState();
}

class _BookAmbulanceScreenState extends State<BookAmbulanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupAddressController = TextEditingController();
  final _dropAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  AmbulanceType _selectedType = AmbulanceType.basic;
  bool _isBooking = false;

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _dropAddressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _bookAmbulance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBooking = true);

    // TODO: Create ambulance request in Firestore
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isBooking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ambulance request submitted successfully!'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Ambulance'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Emergency Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.errorColor,
                      AppTheme.errorColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Service',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quick ambulance dispatch',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ambulance Type
              Text(
                'Select Ambulance Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...AmbulanceType.values.map((type) {
                return RadioListTile<AmbulanceType>(
                  value: type,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                  title: Text(AppConstants.ambulanceTypes[type.name] ?? type.name),
                  subtitle: Text(_getTypeDescription(type)),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primaryColor,
                );
              }),
              const SizedBox(height: 16),

              // Pickup Address
              CustomTextField(
                controller: _pickupAddressController,
                label: 'Pickup Address',
                hint: 'Enter pickup location',
                prefixIcon: Icons.location_on,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pickup address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Drop Address
              CustomTextField(
                controller: _dropAddressController,
                label: 'Hospital/Drop Address',
                hint: 'Enter destination',
                prefixIcon: Icons.local_hospital,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter drop address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact Number
              CustomTextField(
                controller: _phoneController,
                label: 'Contact Number',
                hint: 'Enter your phone number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact number';
                  }
                  if (value.length < 10) {
                    return 'Please enter valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your request will be assigned to the nearest available ambulance. You will receive notification with driver details.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              CustomButton(
                text: 'Request Ambulance',
                onPressed: _bookAmbulance,
                isLoading: _isBooking,
                backgroundColor: AppTheme.errorColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeDescription(AmbulanceType type) {
    switch (type) {
      case AmbulanceType.basic:
        return 'For non-critical emergencies';
      case AmbulanceType.icu:
        return 'With ICU facilities for critical cases';
      case AmbulanceType.neonatal:
        return 'Specialized for newborns';
    }
  }
}
