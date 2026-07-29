import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/family_member_selector.dart';
import '../../../core/providers/family_member_provider.dart';
import '../../../core/services/prescription_pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class PrescriptionsScreen extends ConsumerStatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  ConsumerState<PrescriptionsScreen> createState() =>
      _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends ConsumerState<PrescriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isUploading = false;

  Future<void> _openUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

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
      appBar: AppBar(
        title: const Text('Prescriptions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Doctor Prescribed'),
            Tab(text: 'My Uploads'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDoctorPrescriptionsTab(), _buildMyPrescriptionsTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading
            ? null
            : () => _showAddPrescriptionDialog(context),
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add),
        label: Text(_isUploading ? 'Uploading...' : 'Add Prescription'),
        backgroundColor: _isUploading ? Colors.grey : AppTheme.primaryColor,
      ),
    );
  }

  // Doctor Prescribed Prescriptions
  Widget _buildDoctorPrescriptionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prescriptions')
          .where('patientId', isEqualTo: _currentUserId)
          .where('isFromDoctor', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final prescriptions = snapshot.data?.docs ?? [];

        if (prescriptions.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: 'No doctor prescriptions',
            subtitle:
                'Prescriptions from your doctors will appear here after consultations',
          );
        }

        // Sort by date (newest first)
        prescriptions.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final dateA = _parseDate(dataA['createdAt']);
          final dateB = _parseDate(dataB['createdAt']);
          return dateB.compareTo(dateA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: prescriptions.length,
          itemBuilder: (context, index) {
            final data = prescriptions[index].data() as Map<String, dynamic>;
            return _DoctorPrescriptionCard(
              data: data,
              prescriptionId: prescriptions[index].id,
              onView: () => _viewDoctorPrescription(data),
            );
          },
        );
      },
    );
  }

  // My Uploaded Prescriptions
  Widget _buildMyPrescriptionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prescriptions')
          .where('patientId', isEqualTo: _currentUserId)
          .where('isFromDoctor', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final prescriptions = snapshot.data?.docs ?? [];

        if (prescriptions.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.upload_file_outlined,
            title: 'No uploaded prescriptions',
            subtitle: 'Upload your prescriptions here for easy access',
            actionText: 'Upload Prescription',
            onAction: () => _showAddPrescriptionDialog(context),
          );
        }

        // Sort by date (newest first)
        prescriptions.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final dateA = _parseDate(dataA['createdAt']);
          final dateB = _parseDate(dataB['createdAt']);
          return dateB.compareTo(dateA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: prescriptions.length,
          itemBuilder: (context, index) {
            final data = prescriptions[index].data() as Map<String, dynamic>;
            return _MyPrescriptionCard(
              data: data,
              prescriptionId: prescriptions[index].id,
              onView: () => _viewPrescription(data['fileURL']),
              onDelete: () => _deletePrescription(prescriptions[index].id),
            );
          },
        );
      },
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  void _viewDoctorPrescription(Map<String, dynamic> data) async {
    final String? fileUrl = data['fileURL'];
    final List medicines = data['medicines'] as List? ?? [];
    final bool isManual = data['isManualPhoto'] ?? false;

    if (isManual || (fileUrl != null && fileUrl.isNotEmpty && (fileUrl.startsWith('http') || fileUrl.startsWith('data:image')))) {
      _viewPrescription(fileUrl);
      return;
    }

    if (medicines.isNotEmpty) {
      final medicinesList = medicines
          .map((e) => PrescribedMedicineItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final testsList = (data['diagnosticTests'] as List? ?? []).map((e) => e.toString()).toList();
      final createdAt = _parseDate(data['createdAt']);

      final pdfBytes = await PrescriptionPdfService.generatePrescriptionPdf(
        prescriptionId: data['prescriptionId'] ?? 'PRE',
        doctorName: data['doctorName'] ?? 'Doctor',
        doctorSpecialization: data['specialization'] ?? 'General Physician',
        doctorQualifications: 'MBBS',
        bmdcNumber: '',
        hospitalName: data['hospital'] ?? 'MediConnect Hospital',
        patientName: data['patientName'] ?? 'Patient',
        patientAgeGender: 'Patient',
        date: createdAt,
        medicines: medicinesList,
        diagnosticTests: testsList,
        clinicalNotes: data['notes'] ?? '',
      );

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 10),
                    const Text('E-Prescription PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PdfPreview(
                  build: (format) => pdfBytes,
                  allowPrinting: true,
                  allowSharing: true,
                  canChangePageFormat: false,
                  initialPageFormat: PdfPageFormat.a4,
                  pdfFileName: 'Prescription_${(data['patientName'] ?? 'Patient').toString().replaceAll(' ', '_')}.pdf',
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      _viewPrescription(fileUrl);
    }
  }

  void _viewPrescription(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No prescription file available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isPdf = url.startsWith('data:application/pdf') ||
        url.toLowerCase().contains('.pdf') ||
        url.contains('pdf');
    final isBase64Image = url.startsWith('data:image/');
    final isNetworkUrl = url.startsWith('http') || url.startsWith('https');
    final isNetworkImage = isNetworkUrl && !isPdf;

    if (isPdf) {
      Uint8List? pdfBytes;
      if (url.startsWith('data:application/pdf;base64,')) {
        final base64Str = url.split(',').last;
        try {
          pdfBytes = base64Decode(base64Str);
        } catch (e) {
          debugPrint('Error decoding base64 PDF: $e');
        }
      } else if (isNetworkUrl) {
        try {
          final request = await HttpClient().getUrl(Uri.parse(url));
          final response = await request.close();
          final bytes = <int>[];
          await response.forEach(bytes.addAll);
          pdfBytes = Uint8List.fromList(bytes);
        } catch (e) {
          debugPrint('Error downloading network PDF: $e');
        }
      } else {
        try {
          final base64Str = url.contains(',') ? url.split(',').last : url;
          pdfBytes = base64Decode(base64Str);
        } catch (_) {}
      }

      if (pdfBytes != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.red),
                      const SizedBox(width: 10),
                      const Text('Uploaded Prescription PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    build: (format) => pdfBytes!,
                    allowPrinting: true,
                    allowSharing: true,
                    canChangePageFormat: false,
                    initialPageFormat: PdfPageFormat.a4,
                    pdfFileName: 'Prescription_Document.pdf',
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Prescription Document',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (isBase64Image) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  width: double.infinity,
                  color: Colors.black12,
                  child: Image.memory(
                    base64Decode(url.split(',').last),
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('Unable to render image'),
                    ),
                  ),
                ),
              ),
            ] else if (isNetworkImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  width: double.infinity,
                  color: Colors.black12,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (ctx, err, stack) => const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('Error loading network image'),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  url,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Prescription link copied!'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Link'),
                  ),
                ),
                if (url.startsWith('http')) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openUrl(url);
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print / View PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showAddPrescriptionDialog(BuildContext context) {
    final doctorNameController = TextEditingController();
    final hospitalController = TextEditingController();
    final notesController = TextEditingController();
    DateTime prescriptionDate = DateTime.now();
    File? selectedFile;
    String? fileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 24),
                Text(
                  'Upload Prescription',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload your official PDF prescription',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // Family Member Selector
                const FamilyMemberSelector(showAddButton: false),
                const SizedBox(height: 16),

                // File Upload Section (PDF Only)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selectedFile != null
                          ? Colors.green
                          : Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (selectedFile != null) ...[
                        const Icon(Icons.picture_as_pdf, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          fileName ?? 'Prescription.pdf',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              selectedFile = null;
                              fileName = null;
                            });
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          label: const Text('Remove PDF', style: TextStyle(color: Colors.red)),
                        ),
                      ] else ...[
                        Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppTheme.primaryColor,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Select PDF Prescription',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Only PDF documents are supported (.pdf)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                            );
                            if (result != null && result.files.single.path != null) {
                              setModalState(() {
                                selectedFile = File(result.files.single.path!);
                                fileName = result.files.single.name;
                              });
                            }
                          },
                          icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
                          label: const Text('Browse PDF Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Date Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: const Text('Prescription Date'),
                  subtitle: Text(
                    DateFormat('MMMM dd, yyyy').format(prescriptionDate),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: prescriptionDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setModalState(() => prescriptionDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Doctor Name
                TextField(
                  controller: doctorNameController,
                  decoration: InputDecoration(
                    labelText: 'Doctor Name (Optional)',
                    hintText: 'e.g., Dr. John Smith',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Hospital/Clinic
                TextField(
                  controller: hospitalController,
                  decoration: InputDecoration(
                    labelText: 'Hospital/Clinic (Optional)',
                    hintText: 'e.g., City Hospital',
                    prefixIcon: const Icon(Icons.local_hospital),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'e.g., For fever and cold',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Icon(Icons.notes),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedFile == null
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await _uploadPrescription(
                              selectedFile!,
                              fileName!,
                              doctorNameController.text,
                              hospitalController.text,
                              notesController.text,
                              prescriptionDate,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Upload Prescription',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadPrescription(
    File file,
    String fileName,
    String doctorName,
    String hospital,
    String notes,
    DateTime prescriptionDate,
  ) async {
    setState(() => _isUploading = true);

    try {
      final userId = _currentUserId;
      if (userId.isEmpty) {
        throw Exception(
          'User authentication missing. Please sign in to upload prescriptions.',
        );
      }

      final bytes = await file.readAsBytes();

      // Determine Content-Type MIME
      final sanitizedFileName = fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final ext = sanitizedFileName.split('.').last.toLowerCase();
      String contentType = 'image/jpeg';
      if (ext == 'png') contentType = 'image/png';
      if (ext == 'pdf') contentType = 'application/pdf';
      if (ext == 'webp') contentType = 'image/webp';
      if (ext == 'heic' || ext == 'heif') contentType = 'image/heic';
      if (ext == 'bmp') contentType = 'image/bmp';
      if (ext == 'gif') contentType = 'image/gif';
      if (ext == 'doc') contentType = 'application/msword';
      if (ext == 'docx') contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      if (ext == 'txt') contentType = 'text/plain';

      String? downloadUrl;

      // 1. Primary: Upload file bytes to Firebase Storage via putData (works across Mobile & Web)
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('prescriptions')
            .child(userId)
            .child(
              '${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName',
            );

        final metadata = SettableMetadata(
          contentType: contentType,
          customMetadata: {'uploadedBy': userId},
        );

        final uploadTask = storageRef.putData(bytes, metadata);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint(
          'Prescription uploaded successfully to Storage: $downloadUrl',
        );
      } catch (storageError) {
        debugPrint(
          'Firebase Storage Error ($storageError). Falling back to base64 encoding...',
        );

        if (bytes.length > 2500 * 1024) {
          throw Exception(
            'The selected PDF file is too large (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB). Please select a PDF under 2.5 MB.',
          );
        }

        final base64Str = base64Encode(bytes);
        downloadUrl = 'data:application/pdf;base64,$base64Str';
      }

      // Check if uploaded for a selected family member
      final selectedFamilyMember = ref.read(selectedFamilyMemberProvider);

      // 2. Save prescription metadata record to Firestore
      await FirebaseFirestore.instance.collection('prescriptions').add({
        'patientId': userId,
        'familyMemberId': selectedFamilyMember?.id,
        'familyMemberName': selectedFamilyMember?.name,
        'doctorName': doctorName.isNotEmpty ? doctorName : 'Patient Upload',
        'hospital': hospital,
        'notes': notes,
        'fileURL': downloadUrl,
        'fileName': fileName,
        'prescriptionDate': prescriptionDate.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'isFromDoctor': false,
      });

      // Clear selected family member after upload
      ref.read(selectedFamilyMemberProvider.notifier).state = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Prescription uploaded successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        // Switch to My Uploads tab
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Upload Failed'),
              ],
            ),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deletePrescription(String prescriptionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prescription'),
        content: const Text(
          'Are you sure you want to delete this prescription?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('prescriptions')
            .doc(prescriptionId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prescription deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

// Doctor Prescription Card
class _DoctorPrescriptionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String prescriptionId;
  final VoidCallback onView;

  const _DoctorPrescriptionCard({
    required this.data,
    required this.prescriptionId,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = _parseDate(data['createdAt']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  child: Icon(
                    Icons.receipt_long,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['doctorName'] ?? 'Doctor',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Doctor',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (data['medicines'] != null && (data['medicines'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Rx Medicines:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (data['medicines'] as List).map((m) {
                  final medMap = Map<String, dynamic>.from(m as Map);
                  return Chip(
                    avatar: const Icon(Icons.medication, size: 14, color: AppTheme.primaryColor),
                    label: Text('${medMap['name']} (${medMap['dosage']})', style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.blue.shade50,
                    side: BorderSide(color: Colors.blue.shade100),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
            if (data['notes'] != null &&
                (data['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Advice: ${data['notes']}',
                  style: TextStyle(color: Colors.grey[800], fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('View / Print E-Prescription PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

// My Prescription Card
class _MyPrescriptionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String prescriptionId;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _MyPrescriptionCard({
    required this.data,
    required this.prescriptionId,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final prescriptionDate = _parseDate(
      data['prescriptionDate'] ?? data['createdAt'],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.upload_file,
                    color: Colors.teal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['doctorName'] ?? 'Unknown Doctor',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (data['familyMemberName'] != null &&
                          (data['familyMemberName'] as String).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Patient: ${data['familyMemberName']}',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (data['hospital'] != null &&
                          (data['hospital'] as String).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          data['hospital'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(prescriptionDate),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Uploaded',
                    style: TextStyle(
                      color: Colors.teal[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (data['notes'] != null &&
                (data['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['notes'],
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
