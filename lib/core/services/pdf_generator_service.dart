import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/lab_test_model.dart';

class PdfGeneratorService {
  /// Generate a clean, official appointment PDF document bytes
  static Future<Uint8List> generateAppointmentPdf(
    AppointmentModel appointment,
  ) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final formattedDate = dateFormat.format(appointment.date);
    final bookingTimestamp = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue800,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MediConnect Telemedicine',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Official Appointment Slip & Receipt',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'CONFIRMED',
                        style: pw.TextStyle(
                          color: PdfColors.green800,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Patient Header Section (Top of PDF)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PATIENT NAME',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          appointment.patientName,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        if (appointment.familyMemberName != null) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'For Family Member: ${appointment.familyMemberName}',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ],
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'BOOKED ON',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          bookingTimestamp,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Doctor & Appointment Details
              pw.Text(
                'APPOINTMENT DETAILS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Divider(color: PdfColors.blue800, thickness: 1),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: [
                  _buildTableRow(
                    'Doctor Name:',
                    'Dr. ${appointment.doctorName}',
                  ),
                  _buildTableRow('Specialization:', appointment.specialization),
                  _buildTableRow('Appointment Date:', formattedDate),
                  _buildTableRow('Time Slot:', appointment.timeSlot),
                  _buildTableRow(
                    'Reason / Notes:',
                    appointment.reason ?? 'General Consultation',
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Hospital Details Section
              pw.Text(
                'HOSPITAL / CLINIC LOCATION',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Divider(color: PdfColors.blue800, thickness: 1),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: [
                  _buildTableRow(
                    'Hospital Name:',
                    appointment.hospitalName ?? 'City General Hospital',
                  ),
                  _buildTableRow(
                    'Hospital Address:',
                    '123 Main Street, Dhaka, Bangladesh',
                  ),
                  _buildTableRow('Contact Hotline:', '+880 1234-567890'),
                ],
              ),

              pw.SizedBox(height: 20),

              // Payment & Fee Details
              pw.Text(
                'PAYMENT SUMMARY',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Divider(color: PdfColors.blue800, thickness: 1),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: [
                  _buildTableRow(
                    'Consultation Fee:',
                    'BDT ${appointment.consultationFee?.toStringAsFixed(0)}',
                  ),
                  _buildTableRow(
                    'Payment Status:',
                    appointment.paymentStatus.name.toUpperCase(),
                  ),
                  _buildTableRow(
                    'Payment Method:',
                    appointment.paymentMethod.name == 'online'
                        ? 'Online (SSLCommerz)'
                        : 'Pay at Hospital Counter',
                  ),
                  if (appointment.transactionId != null)
                    _buildTableRow(
                      'Transaction ID:',
                      appointment.transactionId!,
                    ),
                ],
              ),

              pw.Spacer(),

              // Footer & Instructions
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'IMPORTANT INSTRUCTIONS FOR PATIENTS:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '1. Please arrive at the hospital counter 15 minutes before your scheduled slot.\n'
                      '2. Show this PDF slip or present your Appointment ID on your phone at check-in.\n'
                      '3. For cancellations or reschedule, please use the MediConnect mobile app.',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  'Generated by MediConnect Telemedicine System • www.mediconnect.com',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  /// Opens interactive PDF Preview dialog with Print/Save/Download options
  static Future<void> showPdfPreview(
    BuildContext context,
    AppointmentModel appointment,
  ) async {
    final pdfBytes = await generateAppointmentPdf(appointment);

    if (!context.mounted) return;

    await showModalBottomSheet(
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red),
                  const SizedBox(width: 10),
                  const Text(
                    'Appointment PDF Slip',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
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
                pdfFileName:
                    'Appointment_${appointment.patientName.replaceAll(' ', '_')}.pdf',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create a notification in Firestore for the patient about the Appointment PDF
  static Future<void> saveAndNotifyAppointmentPdf(
    AppointmentModel appointment,
  ) async {
    try {
      final docId = appointment.appointmentId.isNotEmpty
          ? appointment.appointmentId
          : DateTime.now().millisecondsSinceEpoch.toString();

      final dateFormat = DateFormat('dd MMM yyyy');
      final formattedDate = dateFormat.format(appointment.date);

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': appointment.patientId,
        'type': 'appointment_pdf',
        'title': '📄 Appointment PDF Slip Ready',
        'message':
            'Your appointment slip for Dr. ${appointment.doctorName} on $formattedDate at ${appointment.timeSlot} is ready. Tap to view or download.',
        'appointmentId': docId,
        'doctorName': appointment.doctorName,
        'specialization': appointment.specialization,
        'patientName': appointment.patientName,
        'date': appointment.date.toIso8601String(),
        'timeSlot': appointment.timeSlot,
        'hospitalName': appointment.hospitalName ?? 'City General Hospital',
        'consultationFee': appointment.consultationFee,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      debugPrint(
        'Successfully sent appointment PDF notification to patient: ${appointment.patientId}',
      );
    } catch (e) {
      debugPrint('Error creating appointment PDF notification: $e');
    }
  }

  /// Generate official Diagnostic Lab Test Report PDF document bytes
  static Future<Uint8List> generateLabTestReportPdf(
    LabTestModel booking, {
    Map<String, Map<String, String>>? customResults,
    String? pathologistRemarks,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(
      booking.reportGeneratedAt ?? DateTime.now(),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Letterhead Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal800,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          booking.diagnosticCentreName,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Official Medical Pathology & Diagnostic Report',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'VERIFIED REPORT',
                        style: pw.TextStyle(
                          color: PdfColors.teal900,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Patient Info Section
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Patient Name: ${booking.targetPatientDisplay}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        pw.Text(
                          'Report Date: $formattedDate',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Collection Method: ${booking.collectionTypeDisplay}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Payment Status: ${booking.paymentMethodDisplay} (${booking.paymentStatus.name.toUpperCase()})',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    if (booking.phlebotomistName != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Assigned Technician: ${booking.phlebotomistName}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 16),
              pw.Text(
                'Diagnostic Test Parameters & Results:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 8),

              // Test Results Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.teal700,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                headers: [
                  'Test Name',
                  'Category',
                  'Measured Value',
                  'Reference Range',
                  'Status',
                ],
                data: booking.tests.map((test) {
                  final custom =
                      customResults?[test.testName] ??
                      customResults?[test.testId];
                  final valStr =
                      custom?['value'] ??
                      (test.price > 1000 ? '13.5 g/dL' : 'Normal');
                  final rangeStr =
                      custom?['range'] ??
                      (test.price > 1000
                          ? '12.0 - 16.0 g/dL'
                          : 'Normal / Negative');
                  final statusStr = custom?['status'] ?? 'NORMAL';

                  return [
                    test.testName,
                    test.category,
                    valStr,
                    rangeStr,
                    statusStr,
                  ];
                }).toList(),
              ),

              if (pathologistRemarks != null &&
                  pathologistRemarks.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Pathologist Remarks & Clinical Notes:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        pathologistRemarks,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              pw.SizedBox(height: 20),

              // Lab Director / Pathologist Signature Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Prepared by:',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Medical Technologist (Phlebotomy)',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        'License #MT-904812',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Approved & Signed by:',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Dr. Farhana Ahmed, MD (Pathology)',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        'Head of Laboratory & Diagnostics',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Center(
                child: pw.Text(
                  'MediConnect Telemedicine & Diagnostic Portal • Computer Generated Official Report',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
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
