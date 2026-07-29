import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PrescribedMedicineItem {
  final String name;
  final String dosage;
  final String instruction;
  final String duration;

  PrescribedMedicineItem({
    required this.name,
    required this.dosage,
    required this.instruction,
    required this.duration,
  });

  factory PrescribedMedicineItem.fromJson(Map<String, dynamic> json) {
    return PrescribedMedicineItem(
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '1-0-1',
      instruction: json['instruction'] ?? 'After meal',
      duration: json['duration'] ?? '5 days',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'instruction': instruction,
      'duration': duration,
    };
  }
}

class PrescriptionPdfService {
  /// Generates a professional 2-column Medical Prescription PDF:
  /// Left Column: Diagnostic Tests & Advice
  /// Right Column: Prescribed Medicines (Rx) with dosage, timing, duration
  static Future<Uint8List> generatePrescriptionPdf({
    required String prescriptionId,
    required String doctorName,
    required String doctorSpecialization,
    required String doctorQualifications,
    required String bmdcNumber,
    required String hospitalName,
    required String patientName,
    required String patientAgeGender,
    required DateTime date,
    required List<PrescribedMedicineItem> medicines,
    required List<String> diagnosticTests,
    required String clinicalNotes,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#0066CC');
    final darkTextColor = PdfColor.fromHex('#1E293B');
    final lightGreyColor = PdfColor.fromHex('#F8FAFC');
    final borderColor = PdfColor.fromHex('#CBD5E1');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. DOCTOR HEADER
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.blue, width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          doctorName.startsWith('Dr.') ? doctorName : 'Dr. $doctorName',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          doctorSpecialization,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: darkTextColor,
                          ),
                        ),
                        pw.Text(
                          doctorQualifications,
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                        if (bmdcNumber.isNotEmpty)
                          pw.Text(
                            'BMDC Reg. No: $bmdcNumber',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                          ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          hospitalName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Official Telemedicine Consultation',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'Prescription ID: #${prescriptionId.substring(0, prescriptionId.length > 8 ? 8 : prescriptionId.length).toUpperCase()}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // 2. PATIENT INFORMATION BANNER
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: lightGreyColor,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Patient: $patientName',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkTextColor),
                    ),
                    if (patientAgeGender.isNotEmpty)
                      pw.Text(
                        'Age/Gender: $patientAgeGender',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                    pw.Text(
                      'Date: ${DateFormat('MMMM dd, yyyy').format(date)}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // 3. TWO-COLUMN MEDICAL LAYOUT (Tests/Advice on Left, Rx Medicines on Right)
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN: Diagnostic Tests & Clinical Advice / Notes (35% width)
                    pw.Container(
                      width: 175,
                      padding: const pw.EdgeInsets.only(right: 12),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(color: PdfColors.grey300, width: 1),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Diagnostic Tests Section
                          pw.Text(
                            'DIAGNOSTIC TESTS',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(height: 1, color: primaryColor),
                          pw.SizedBox(height: 6),
                          if (diagnosticTests.isEmpty)
                            pw.Text(
                              'None advised',
                              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                            )
                          else
                            ...diagnosticTests.map(
                              (test) => pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 6),
                                child: pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor)),
                                    pw.Expanded(
                                      child: pw.Text(
                                        test,
                                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkTextColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          pw.SizedBox(height: 20),

                          // Advice / Clinical Notes Section
                          pw.Text(
                            'CLINICAL ADVICE',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(height: 1, color: primaryColor),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            clinicalNotes.isNotEmpty ? clinicalNotes : 'Drink plenty of water, rest adequately, and follow up if symptoms persist.',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(width: 16),

                    // RIGHT COLUMN: Prescribed Medicines Rx (65% width)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Rx',
                                style: pw.TextStyle(
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Text(
                                'PRESCRIBED MEDICATIONS',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(height: 1.5, color: primaryColor),
                          pw.SizedBox(height: 12),

                          if (medicines.isEmpty)
                            pw.Text(
                              'No medications prescribed.',
                              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                            )
                          else
                            ...List.generate(medicines.length, (index) {
                              final med = medicines[index];
                              return pw.Container(
                                margin: const pw.EdgeInsets.only(bottom: 12),
                                padding: const pw.EdgeInsets.all(8),
                                decoration: pw.BoxDecoration(
                                  color: lightGreyColor,
                                  borderRadius: pw.BorderRadius.circular(6),
                                  border: pw.Border.all(color: borderColor),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Row(
                                      children: [
                                        pw.Text(
                                          '${index + 1}. ',
                                          style: pw.TextStyle(
                                            fontSize: 11,
                                            fontWeight: pw.FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        pw.Expanded(
                                          child: pw.Text(
                                            med.name,
                                            style: pw.TextStyle(
                                              fontSize: 11,
                                              fontWeight: pw.FontWeight.bold,
                                              color: darkTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text(
                                          'Dosage: ${med.dosage}',
                                          style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColors.blue900,
                                          ),
                                        ),
                                        pw.Text(
                                          med.instruction,
                                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                                        ),
                                        pw.Text(
                                          'Duration: ${med.duration}',
                                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // 4. FOOTER & VERIFICATION STAMP
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Verified Medical Telemedicine Record',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor),
                        ),
                        pw.Text(
                          'Generates official digital PDF record for patient profile.',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 90,
                          height: 1,
                          color: PdfColors.grey800,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          doctorName.startsWith('Dr.') ? doctorName : 'Dr. $doctorName',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkTextColor),
                        ),
                        pw.Text(
                          'Digitally Signed & Verified',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.green700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
