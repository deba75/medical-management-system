import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';

class EditDoctorProfileDialog extends StatefulWidget {
  const EditDoctorProfileDialog({super.key});

  @override
  State<EditDoctorProfileDialog> createState() => _EditDoctorProfileDialogState();
}

class _EditDoctorProfileDialogState extends State<EditDoctorProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _feeController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _specializationController = TextEditingController();
  final _bmdcController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _feeController.dispose();
    _qualificationsController.dispose();
    _specializationController.dispose();
    _bmdcController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('doctors').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _feeController.text = (data['consultationFee'] ?? 500).toString();
        _qualificationsController.text = data['qualifications'] ?? '';
        _specializationController.text = data['specialization'] ?? '';
        _bmdcController.text = data['bmdcNumber'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _bioController.text = data['bio'] ?? '';
      }
    } catch (e) {
      debugPrint('Error loading doctor profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final fee = double.tryParse(_feeController.text.trim()) ?? 500.0;
      final qualifications = _qualificationsController.text.trim();
      final specialization = _specializationController.text.trim();
      final bmdc = _bmdcController.text.trim();
      final phone = _phoneController.text.trim();
      final bio = _bioController.text.trim();

      final updatePayload = {
        'consultationFee': fee,
        'qualifications': qualifications,
        'specialization': specialization,
        'bmdcNumber': bmdc,
        'phone': phone,
        'bio': bio,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 1. Sync to doctors collection
      await FirebaseFirestore.instance.collection('doctors').doc(user.uid).set(updatePayload, SetOptions(merge: true));

      // 2. Sync to users collection
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'consultationFee': fee,
        'qualifications': qualifications,
        'specialization': specialization,
        'bmdcNumber': bmdc,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor profile, fee & degrees updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Doctor Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editable Credentials & Fees',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Updates will be synchronized immediately across Patient, Diagnostic, Doctor, and Admin views.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),

                    // Consultation Fee (৳)
                    TextFormField(
                      controller: _feeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Consultation Fee (৳) *',
                        prefixIcon: Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(),
                        helperText: 'Your standard fee shown to patients during booking',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Fee is required';
                        if (double.tryParse(value.trim()) == null) return 'Enter a valid fee amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Qualifications / Degrees
                    TextFormField(
                      controller: _qualificationsController,
                      decoration: const InputDecoration(
                        labelText: 'Qualifications / Degrees *',
                        prefixIcon: Icon(Icons.school_outlined),
                        border: OutlineInputBorder(),
                        helperText: 'e.g. MBBS, FCPS (Medicine), MD',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Qualifications are required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Specialization
                    TextFormField(
                      controller: _specializationController,
                      decoration: const InputDecoration(
                        labelText: 'Specialization',
                        prefixIcon: Icon(Icons.medical_services_outlined),
                        border: OutlineInputBorder(),
                        helperText: 'e.g. Cardiologist, Neurologist',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // BMDC Registration Number
                    TextFormField(
                      controller: _bmdcController,
                      decoration: const InputDecoration(
                        labelText: 'BMDC Registration Number',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Professional Bio
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Professional Bio / About',
                        prefixIcon: Icon(Icons.description_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving Updates...' : 'Save Profile Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
