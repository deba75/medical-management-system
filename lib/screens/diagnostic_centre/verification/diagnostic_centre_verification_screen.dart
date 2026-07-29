import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';

class DiagnosticCentreVerificationScreen extends ConsumerStatefulWidget {
  const DiagnosticCentreVerificationScreen({super.key});

  @override
  ConsumerState<DiagnosticCentreVerificationScreen> createState() =>
      _DiagnosticCentreVerificationScreenState();
}

class _DiagnosticCentreVerificationScreenState
    extends ConsumerState<DiagnosticCentreVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _centreNameController = TextEditingController();
  final _dghsCodeController = TextEditingController();
  final _pathologistNameController = TextEditingController();
  final _pathologistBmdcController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  File? _licenseImage;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _centreNameController.dispose();
    _dghsCodeController.dispose();
    _pathologistNameController.dispose();
    _pathologistBmdcController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _licenseImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadLicenseImage(String userId) async {
    if (_licenseImage == null) return null;

    setState(() => _isUploadingImage = true);

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('diagnostic_licenses')
          .child('$userId-dghs-license.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': userId},
      );

      final uploadTask = storageRef.putFile(_licenseImage!, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() => _isUploadingImage = false);
      return downloadUrl;
    } catch (e) {
      debugPrint('Storage upload error, falling back to base64: $e');
      try {
        final bytes = await _licenseImage!.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() => _isUploadingImage = false);
        return 'data:image/jpeg;base64,$base64String';
      } catch (err) {
        setState(() => _isUploadingImage = false);
        return null;
      }
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(authServiceProvider).currentUser;
      final userId = user?.uid;
      if (userId == null) throw Exception('User not logged in');

      final userEmail = user?.email ?? '';

      // Get phone number from registered user profile
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userPhone = userDoc.data()?['phone'] ?? user?.phoneNumber ?? '';

      String? licenseUrl;
      if (_licenseImage != null) {
        licenseUrl = await _uploadLicenseImage(userId);
      }

      final centreData = {
        'centreId': userId,
        'name': _centreNameController.text.trim(),
        'email': userEmail,
        'contactNumber': userPhone,
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'dghsCode': _dghsCodeController.text.trim(),
        'pathologistName': _pathologistNameController.text.trim(),
        'pathologistBmdcNumber': _pathologistBmdcController.text.trim(),
        'verificationStatus': 'pending',
        'verificationNote': 'DGHS code & Pathologist BMDC submitted for admin review',
        'licenseImageUrl': licenseUrl,
        'status': 'inactive',
        'submittedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('diagnostic_centres')
          .doc(userId)
          .set(centreData, SetOptions(merge: true));

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showPendingDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.verified_user_outlined, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Verification Submitted'),
          ],
        ),
        content: const Text(
          'Your Diagnostic Centre details (DGHS Code & Pathologist BMDC Number) have been submitted to the Admin team.\n\n'
          'Once verified by Admin, you will receive full access to your Diagnostic Centre portal.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authServiceProvider).signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to Login', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, color: Colors.teal.shade700, size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'DGHS Registration Code & Pathologist BMDC Registration Number are mandatory for Diagnostic Centre verification.',
                        style: TextStyle(fontSize: 13, color: Colors.teal.shade900, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Diagnostic Centre Information', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _centreNameController,
                decoration: InputDecoration(
                  labelText: 'Diagnostic Centre Name *',
                  hintText: 'e.g. Popular Diagnostic Center',
                  prefixIcon: const Icon(Icons.business_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter diagnostic centre name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dghsCodeController,
                decoration: InputDecoration(
                  labelText: 'DGHS Code / Registration Number *',
                  hintText: 'e.g. DGHS-LAB-2024-8849',
                  prefixIcon: const Icon(Icons.local_hospital_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter DGHS Code' : null,
              ),
              const SizedBox(height: 24),

              Text('Pathologist Verification Information', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _pathologistNameController,
                decoration: InputDecoration(
                  labelText: 'Chief Pathologist Name *',
                  hintText: 'e.g. Dr. Md. Ashraful Islam',
                  prefixIcon: const Icon(Icons.person_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter Pathologist name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _pathologistBmdcController,
                decoration: InputDecoration(
                  labelText: 'Pathologist BMDC Reg. Number *',
                  hintText: 'e.g. BMDC-A-45920',
                  prefixIcon: const Icon(Icons.badge_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter Pathologist BMDC Reg number' : null,
              ),
              const SizedBox(height: 24),

              Text('Location Information', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City *',
                        hintText: 'e.g. Dhaka',
                        prefixIcon: const Icon(Icons.location_city_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter city' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Full Address *',
                  hintText: 'e.g. House 12, Road 4, Dhanmondi, Dhaka',
                  prefixIcon: const Icon(Icons.place_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter full address' : null,
              ),
              const SizedBox(height: 24),

              Text('DGHS License / Certificate Document (Optional)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: _pickLicenseImage,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: _licenseImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_licenseImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.upload_file_rounded, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Upload DGHS License or Certificate Photo', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting || _isUploadingImage
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Verification',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
