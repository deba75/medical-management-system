import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/providers/auth_provider.dart';

/// Doctor Verification Screen
/// 
/// NOTE: File uploads are disabled because Firebase Storage requires 
/// Blaze plan for your region. This version uses text-based verification
/// where admin verifies the BMDC number manually.
/// 
/// To enable file uploads:
/// 1. Upgrade to Firebase Blaze plan, OR
/// 2. Create a new Firebase project in a US region
class DoctorVerificationScreen extends ConsumerStatefulWidget {
  const DoctorVerificationScreen({super.key});

  @override
  ConsumerState<DoctorVerificationScreen> createState() =>
      _DoctorVerificationScreenState();
}

class _DoctorVerificationScreenState
    extends ConsumerState<DoctorVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bmdcNumberController = TextEditingController();
  final _workplaceHospitalController = TextEditingController();
  final _workplaceDepartmentController = TextEditingController();
  final _specializationController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;
  bool _isSpecialist = false;

  @override
  void dispose() {
    _bmdcNumberController.dispose();
    _workplaceHospitalController.dispose();
    _workplaceDepartmentController.dispose();
    _specializationController.dispose();
    _qualificationsController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = ref.read(authServiceProvider).currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final userEmail = ref.read(authServiceProvider).currentUser?.email ?? '';
      final userName =
          ref.read(authServiceProvider).currentUser?.displayName ?? '';

      // Create doctor document in Firestore (without file uploads)
      final doctorData = {
        'userId': userId,
        'email': userEmail,
        'name': userName,
        'phone': _phoneController.text.trim(),
        'bmdcNumber': _bmdcNumberController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'qualifications': _qualificationsController.text.trim(),
        'experienceYears': _experienceController.text.trim(),
        'isSpecialist': _isSpecialist,
        'workplaceInfo': {
          'hospital': _workplaceHospitalController.text.trim(),
          'department': _workplaceDepartmentController.text.trim(),
        },
        'workplaceHospital': _workplaceHospitalController.text.trim(),
        'workplaceDepartment': _workplaceDepartmentController.text.trim(),
        'verificationStatus': 'pending',
        'verificationNote': 'Text-based verification - Admin to verify BMDC number manually',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'active': false,
        'isRestricted': false,
        // No file URLs since Storage is not available
        'certificateURLs': null,
        'photoURL': null,
      };

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(userId)
          .set(doctorData, SetOptions(merge: true));

      // Update the users collection
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'role': 'doctor',
        'verificationStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _isSubmitting = false);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Expanded(child: Text('Application Submitted')),
              ],
            ),
            content: const Text(
              'Your verification request has been submitted successfully.\n\n'
              'Admin will verify your BMDC registration number and approve your account within 24-48 hours.\n\n'
              'You will be able to login once approved.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await ref.read(authServiceProvider).signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Verification'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Submitting your application...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: AppTheme.primaryColor,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Doctor Registration',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please provide your professional details for verification. '
                            'Admin will verify your BMDC registration before approving your account.',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Personal Information Section
                    _buildSectionHeader('Personal Information'),
                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number *',
                      hint: 'Enter your phone number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number is required';
                        }
                        if (value.length < 10) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Professional Information Section
                    _buildSectionHeader('Professional Information'),
                    const SizedBox(height: 12),

                    // BMDC Registration Number
                    CustomTextField(
                      controller: _bmdcNumberController,
                      label: 'BMDC Registration Number *',
                      hint: 'e.g., A-12345',
                      prefixIcon: Icons.badge,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'BMDC registration number is required';
                        }
                        if (value.length < 4) {
                          return 'Please enter a valid BMDC number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will be verified with BMDC records',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Specialization
                    CustomTextField(
                      controller: _specializationController,
                      label: 'Specialization *',
                      hint: 'e.g., Cardiology, Neurology, General Medicine',
                      prefixIcon: Icons.medical_services,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Specialization is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Qualifications
                    CustomTextField(
                      controller: _qualificationsController,
                      label: 'Qualifications *',
                      hint: 'e.g., MBBS, FCPS, MD',
                      prefixIcon: Icons.school,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Qualifications are required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Experience
                    CustomTextField(
                      controller: _experienceController,
                      label: 'Years of Experience *',
                      hint: 'e.g., 5',
                      prefixIcon: Icons.work_history,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Experience is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Specialist Toggle
                    SwitchListTile(
                      title: const Text('I am a specialist (FCPS/MD/MS)'),
                      subtitle: const Text(
                        'Toggle if you have a post-graduate specialist degree',
                      ),
                      value: _isSpecialist,
                      onChanged: (value) {
                        setState(() => _isSpecialist = value);
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 24),

                    // Workplace Information Section
                    _buildSectionHeader('Workplace Information'),
                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: _workplaceHospitalController,
                      label: 'Hospital / Clinic Name *',
                      hint: 'Enter your primary workplace',
                      prefixIcon: Icons.local_hospital,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Workplace is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _workplaceDepartmentController,
                      label: 'Department *',
                      hint: 'e.g., Medicine, Surgery, Pediatrics',
                      prefixIcon: Icons.business,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Department is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit for Verification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Admin will verify your BMDC registration number with official records. '
                              'Approval usually takes 24-48 hours.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      '* All marked fields are required',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
