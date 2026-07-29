import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/prescription_pdf_service.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../../../models/appointment_model.dart';
import '../settings/manage_favorite_medicines_dialog.dart';

class WritePrescriptionDialog extends StatefulWidget {
  final AppointmentModel appointment;

  const WritePrescriptionDialog({
    super.key,
    required this.appointment,
  });

  @override
  State<WritePrescriptionDialog> createState() => _WritePrescriptionDialogState();
}

class _WritePrescriptionDialogState extends State<WritePrescriptionDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Doctor Info & Favorite Medicines
  String? _doctorId = FirebaseAuth.instance.currentUser?.uid;
  String _doctorName = '';
  String _doctorSpecialization = 'General Physician';
  String _doctorQualifications = 'MBBS';
  String _bmdcNumber = '';
  String _hospitalName = 'MediConnect Hospital';
  List<FavoriteMedicineItem> _favoriteMedicines = [];

  // Prescription Form State
  final List<PrescribedMedicineItem> _selectedMedicines = [];
  final List<String> _diagnosticTests = [];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customMedNameController = TextEditingController();
  final TextEditingController _customDosageController = TextEditingController(text: '1-0-1');
  final TextEditingController _customInstructionController = TextEditingController(text: 'After meal');
  final TextEditingController _customDurationController = TextEditingController(text: '5 days');
  final TextEditingController _testNameController = TextEditingController();

  // Manual Photo State
  File? _manualPrescriptionImage;
  bool _isSubmitting = false;
  bool _isLoadingFavorites = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDoctorProfileAndFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _customMedNameController.dispose();
    _customDosageController.dispose();
    _customInstructionController.dispose();
    _customDurationController.dispose();
    _testNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorProfileAndFavorites() async {
    _doctorId ??= FirebaseAuth.instance.currentUser?.uid;
    if (_doctorId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(_doctorId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _doctorName = data['name'] ?? widget.appointment.doctorName;
        _doctorSpecialization = data['specialization'] ?? 'General Physician';
        _doctorQualifications = data['qualifications'] ?? 'MBBS';
        _bmdcNumber = data['bmdcNumber'] ?? '';
        if (data['hospitals'] != null && (data['hospitals'] as List).isNotEmpty) {
          _hospitalName = (data['hospitals'] as List).first;
        }

        if (data['favoriteMedicines'] != null) {
          final list = data['favoriteMedicines'] as List;
          _favoriteMedicines = list
              .map((e) => FavoriteMedicineItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else {
          _favoriteMedicines = [
            FavoriteMedicineItem(name: 'Tab. Napa 500mg', dosage: '1-1-1', instruction: 'After meal', duration: '5 days'),
            FavoriteMedicineItem(name: 'Cap. Seclo 20mg', dosage: '1-0-1', instruction: 'Before meal', duration: '7 days'),
            FavoriteMedicineItem(name: 'Tab. Alatrol 10mg', dosage: '0-0-1', instruction: 'At bedtime', duration: '5 days'),
            FavoriteMedicineItem(name: 'Tab. Ace 500mg', dosage: '1-1-1', instruction: 'After meal', duration: '3 days'),
          ];
        }
      }
    } catch (e) {
      debugPrint('Error loading doctor favorites: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFavorites = false);
    }
  }

  void _viewPatientAppointmentPdf() {
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text('Appointment Slip #${widget.appointment.appointmentId.substring(0, 8)}'),
        ),
        body: PdfPreview(
          build: (format) => PdfGeneratorService.generateAppointmentPdf(
            widget.appointment,
          ),
          canChangeOrientation: false,
          canChangePageFormat: false,
        ),
      ),
    );
  }

  void _toggleFavoriteMedicine(FavoriteMedicineItem fav, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        // Add to prescription list if not already present
        if (!_selectedMedicines.any((m) => m.name == fav.name)) {
          _selectedMedicines.add(
            PrescribedMedicineItem(
              name: fav.name,
              dosage: fav.dosage,
              instruction: fav.instruction,
              duration: fav.duration,
            ),
          );
        }
      } else {
        _selectedMedicines.removeWhere((m) => m.name == fav.name);
      }
    });
  }

  bool _saveToFavorites = false;

  void _addCustomMedicine() async {
    final name = _customMedNameController.text.trim();
    if (name.isEmpty) return;

    final item = PrescribedMedicineItem(
      name: name,
      dosage: _customDosageController.text.trim(),
      instruction: _customInstructionController.text.trim(),
      duration: _customDurationController.text.trim(),
    );

    setState(() {
      _selectedMedicines.add(item);
    });

    if (_saveToFavorites && _doctorId != null) {
      final favItem = FavoriteMedicineItem(
        name: item.name,
        dosage: item.dosage,
        instruction: item.instruction,
        duration: item.duration,
      );

      if (!_favoriteMedicines.any((f) => f.name == favItem.name)) {
        setState(() {
          _favoriteMedicines.add(favItem);
        });

        try {
          await FirebaseFirestore.instance
              .collection('doctors')
              .doc(_doctorId)
              .set({
            'favoriteMedicines': _favoriteMedicines.map((e) => e.toJson()).toList(),
          }, SetOptions(merge: true));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saved to your Favorite Medicines list!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error saving favorite: $e');
        }
      }
    }

    _customMedNameController.clear();
  }

  void _addDiagnosticTest() {
    final test = _testNameController.text.trim();
    if (test.isEmpty) return;

    setState(() {
      _diagnosticTests.add(test);
      _testNameController.clear();
    });
  }

  Future<void> _pickManualPrescriptionImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (picked != null) {
      setState(() => _manualPrescriptionImage = File(picked.path));
    }
  }

  Future<void> _submitOnlinePrescription() async {
    if (_selectedMedicines.isEmpty && _diagnosticTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one medicine or diagnostic test.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final docId = FirebaseFirestore.instance.collection('prescriptions').doc().id;

      // 1. Generate 2-Column PDF
      final pdfBytes = await PrescriptionPdfService.generatePrescriptionPdf(
        prescriptionId: docId,
        doctorName: _doctorName.isNotEmpty ? _doctorName : widget.appointment.doctorName,
        doctorSpecialization: _doctorSpecialization,
        doctorQualifications: _doctorQualifications,
        bmdcNumber: _bmdcNumber,
        hospitalName: _hospitalName,
        patientName: widget.appointment.patientName,
        patientAgeGender: '',
        date: DateTime.now(),
        medicines: _selectedMedicines,
        diagnosticTests: _diagnosticTests,
        clinicalNotes: _notesController.text.trim(),
      );

      // 2. Upload PDF to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('prescriptions')
          .child(widget.appointment.patientId)
          .child('${DateTime.now().millisecondsSinceEpoch}_prescription.pdf');

      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {'uploadedBy': _doctorId ?? ''},
      );

      final uploadTask = storageRef.putData(pdfBytes, metadata);
      final snapshot = await uploadTask;
      final fileUrl = await snapshot.ref.getDownloadURL();

      // 3. Save Prescription Record to Firestore
      await FirebaseFirestore.instance.collection('prescriptions').doc(docId).set({
        'prescriptionId': docId,
        'appointmentId': widget.appointment.appointmentId,
        'patientId': widget.appointment.patientId,
        'patientName': widget.appointment.patientName,
        'doctorId': widget.appointment.doctorId,
        'doctorName': widget.appointment.doctorName,
        'hospital': _hospitalName,
        'notes': _notesController.text.trim(),
        'fileURL': fileUrl,
        'fileName': 'Prescription_${widget.appointment.patientName}.pdf',
        'prescriptionDate': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'isFromDoctor': true,
        'isManualPhoto': false,
        'medicines': _selectedMedicines.map((m) => m.toJson()).toList(),
        'diagnosticTests': _diagnosticTests,
      });

      // 4. Update Appointment Status to Completed
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointment.appointmentId)
          .update({'status': 'completed'});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription issued & saved to patient profile!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error issuing online prescription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitManualPrescription() async {
    if (_manualPrescriptionImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or capture a photo of the handwritten prescription.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final docId = FirebaseFirestore.instance.collection('prescriptions').doc().id;
      final bytes = await _manualPrescriptionImage!.readAsBytes();

      // 1. Upload Photo to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('prescriptions')
          .child(widget.appointment.patientId)
          .child('${DateTime.now().millisecondsSinceEpoch}_manual_prescription.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': _doctorId ?? ''},
      );

      final uploadTask = storageRef.putData(bytes, metadata);
      final snapshot = await uploadTask;
      final fileUrl = await snapshot.ref.getDownloadURL();

      // 2. Save Prescription Record to Firestore
      await FirebaseFirestore.instance.collection('prescriptions').doc(docId).set({
        'prescriptionId': docId,
        'appointmentId': widget.appointment.appointmentId,
        'patientId': widget.appointment.patientId,
        'patientName': widget.appointment.patientName,
        'doctorId': widget.appointment.doctorId,
        'doctorName': widget.appointment.doctorName,
        'hospital': _hospitalName,
        'notes': 'Handwritten Paper Prescription',
        'fileURL': fileUrl,
        'fileName': 'Prescription_Photo_${widget.appointment.patientName}.jpg',
        'prescriptionDate': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'isFromDoctor': true,
        'isManualPhoto': true,
      });

      // 3. Update Appointment Status to Completed
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointment.appointmentId)
          .update({'status': 'completed'});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual paper prescription uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading manual prescription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HEADER & APPOINTMENT VERIFICATION BUTTON
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prescribe for ${widget.appointment.patientName}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Slot: ${widget.appointment.timeSlot} • ${widget.appointment.status.name.toUpperCase()}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _viewPatientAppointmentPdf,
                  icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor, size: 18),
                  label: const Text('Verify PDF Slip', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // TAB BAR (Prescribe Online vs. Prescribe Manually)
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.edit_note), text: 'Prescribe Online'),
                Tab(icon: Icon(Icons.camera_alt), text: 'Prescribe Manually (Photo)'),
              ],
            ),
            const SizedBox(height: 12),

            // TAB VIEWS
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPrescribeOnlineTab(),
                  _buildPrescribeManuallyTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescribeOnlineTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. QUICK-TICK FAVORITE MEDICINES SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Common / Favorite Medicines (Tick to Add):',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 13),
              ),
              TextButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => const ManageFavoriteMedicinesDialog(),
                  );
                  _loadDoctorProfileAndFavorites();
                },
                icon: const Icon(Icons.tune, size: 14),
                label: const Text('Manage Favorites', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _isLoadingFavorites
              ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
              : _favoriteMedicines.isEmpty
                  ? Text('No favorite medicines configured in settings.', style: TextStyle(color: Colors.grey[500], fontSize: 12))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _favoriteMedicines.map((fav) {
                        final isChecked = _selectedMedicines.any((m) => m.name == fav.name);
                        return FilterChip(
                          avatar: Icon(
                            isChecked ? Icons.check_circle : Icons.add_circle_outline,
                            color: isChecked ? Colors.white : AppTheme.primaryColor,
                            size: 18,
                          ),
                          label: Text('${fav.name} (${fav.dosage})'),
                          selected: isChecked,
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isChecked ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) => _toggleFavoriteMedicine(fav, selected),
                        );
                      }).toList(),
                    ),

          const Divider(height: 24),

          // 2. CUSTOM MEDICINE TYPE-IN FORM
          Text(
            'Type Custom Medicine:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _customMedNameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    hintText: 'e.g. Tab. Napa Extend 665mg',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _customDosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: '1-0-1',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _customInstructionController,
                  decoration: const InputDecoration(
                    labelText: 'Instruction',
                    hintText: 'After meal',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _customDurationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    hintText: '5 days',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_box, color: Colors.green, size: 32),
                onPressed: _addCustomMedicine,
                tooltip: 'Add Custom Medicine',
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _saveToFavorites,
                onChanged: (val) => setState(() => _saveToFavorites = val ?? false),
                activeColor: AppTheme.primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const Expanded(
                child: Text(
                  '★ Save this medicine to my Favorite list for future quick-select',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // SELECTED MEDICINES LIST PREVIEW
          if (_selectedMedicines.isNotEmpty) ...[
            Text('Prescribed Medicines (${_selectedMedicines.length}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            ..._selectedMedicines.asMap().entries.map((entry) {
              final idx = entry.key;
              final med = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('${idx + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text('${med.name} • ${med.dosage} (${med.instruction}, ${med.duration})', style: const TextStyle(fontSize: 12))),
                    GestureDetector(
                      onTap: () => setState(() => _selectedMedicines.removeAt(idx)),
                      child: const Icon(Icons.close, size: 18, color: Colors.red),
                    ),
                  ],
                ),
              );
            }),
          ],

          const Divider(height: 24),

          // 3. DIAGNOSTIC TEST SUGGESTIONS
          Text(
            'Suggest Diagnostic Tests:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _testNameController,
                  decoration: const InputDecoration(
                    labelText: 'Test Name',
                    hintText: 'e.g., CBC, Blood Glucose, Chest X-Ray',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor, size: 28),
                onPressed: _addDiagnosticTest,
                tooltip: 'Add Test',
              ),
            ],
          ),
          if (_diagnosticTests.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: _diagnosticTests.asMap().entries.map((entry) {
                final idx = entry.key;
                final test = entry.value;
                return Chip(
                  label: Text(test, style: const TextStyle(fontSize: 11)),
                  onDeleted: () => setState(() => _diagnosticTests.removeAt(idx)),
                  deleteIconColor: Colors.red,
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),

          // 4. CLINICAL ADVICE / NOTES
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Clinical Advice & Follow-up Notes',
              hintText: 'e.g., Drink plenty of fluids, rest adequately.',
              isDense: true,
            ),
          ),

          const SizedBox(height: 16),

          // SUBMIT BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitOnlinePrescription,
              icon: _isSubmitting ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Icon(Icons.send),
              label: Text(_isSubmitting ? 'Generating 2-Column PDF...' : 'Issue & Save Prescription PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescribeManuallyTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'Snap or Select a Photo of the Physical Handwritten Prescription Sheet:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 16),

          // IMAGE PREVIEW AREA
          GestureDetector(
            onTap: () => _pickManualPrescriptionImage(ImageSource.camera),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: _manualPrescriptionImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_manualPrescriptionImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 56, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to Capture Photo with Camera',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickManualPrescriptionImage(ImageSource.camera),
                icon: const Icon(Icons.camera),
                label: const Text('Camera'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _pickManualPrescriptionImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // UPLOAD BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_manualPrescriptionImage == null || _isSubmitting)
                  ? null
                  : _submitManualPrescription,
              icon: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Icon(Icons.cloud_upload),
              label: Text(_isSubmitting ? 'Uploading Photo...' : 'Upload Manual Prescription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
