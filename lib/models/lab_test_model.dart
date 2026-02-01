import 'package:cloud_firestore/cloud_firestore.dart';

enum LabTestStatus { pending, scheduled, sampleCollected, processing, completed, cancelled }
enum SampleCollectionType { homeSample, visitLab }

class LabTestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String diagnosticCentreId;
  final String diagnosticCentreName;
  final List<TestItem> tests;
  final LabTestStatus status;
  final SampleCollectionType collectionType;
  final DateTime scheduledDate;
  final String? timeSlot;
  final String? address;
  final double totalAmount;
  final double? discount;
  final String? couponCode;
  final String? prescriptionId;
  final String? doctorId;
  final String? doctorName;
  final String? reportUrl;
  final DateTime? reportGeneratedAt;
  final String? notes;
  final DateTime createdAt;

  LabTestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.diagnosticCentreId,
    required this.diagnosticCentreName,
    required this.tests,
    required this.status,
    required this.collectionType,
    required this.scheduledDate,
    this.timeSlot,
    this.address,
    required this.totalAmount,
    this.discount,
    this.couponCode,
    this.prescriptionId,
    this.doctorId,
    this.doctorName,
    this.reportUrl,
    this.reportGeneratedAt,
    this.notes,
    required this.createdAt,
  });

  factory LabTestModel.fromJson(Map<String, dynamic> json, String id) {
    return LabTestModel(
      id: id,
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      diagnosticCentreId: json['diagnosticCentreId'] ?? '',
      diagnosticCentreName: json['diagnosticCentreName'] ?? '',
      tests: (json['tests'] as List<dynamic>?)
              ?.map((e) => TestItem.fromJson(e))
              .toList() ??
          [],
      status: LabTestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LabTestStatus.pending,
      ),
      collectionType: SampleCollectionType.values.firstWhere(
        (e) => e.name == json['collectionType'],
        orElse: () => SampleCollectionType.visitLab,
      ),
      scheduledDate: json['scheduledDate'] is Timestamp
          ? (json['scheduledDate'] as Timestamp).toDate()
          : DateTime.parse(json['scheduledDate'] ?? DateTime.now().toIso8601String()),
      timeSlot: json['timeSlot'],
      address: json['address'],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      discount: json['discount']?.toDouble(),
      couponCode: json['couponCode'],
      prescriptionId: json['prescriptionId'],
      doctorId: json['doctorId'],
      doctorName: json['doctorName'],
      reportUrl: json['reportUrl'],
      reportGeneratedAt: json['reportGeneratedAt'] != null
          ? (json['reportGeneratedAt'] is Timestamp
              ? (json['reportGeneratedAt'] as Timestamp).toDate()
              : DateTime.parse(json['reportGeneratedAt']))
          : null,
      notes: json['notes'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'diagnosticCentreId': diagnosticCentreId,
      'diagnosticCentreName': diagnosticCentreName,
      'tests': tests.map((e) => e.toJson()).toList(),
      'status': status.name,
      'collectionType': collectionType.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      'timeSlot': timeSlot,
      'address': address,
      'totalAmount': totalAmount,
      'discount': discount,
      'couponCode': couponCode,
      'prescriptionId': prescriptionId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'reportUrl': reportUrl,
      'reportGeneratedAt': reportGeneratedAt?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  double get finalAmount => totalAmount - (discount ?? 0);

  String get statusDisplay {
    switch (status) {
      case LabTestStatus.pending:
        return 'Pending';
      case LabTestStatus.scheduled:
        return 'Scheduled';
      case LabTestStatus.sampleCollected:
        return 'Sample Collected';
      case LabTestStatus.processing:
        return 'Processing';
      case LabTestStatus.completed:
        return 'Completed';
      case LabTestStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class TestItem {
  final String testId;
  final String testName;
  final String category;
  final double price;
  final String? description;
  final int? preparationHours; // Fasting hours required

  TestItem({
    required this.testId,
    required this.testName,
    required this.category,
    required this.price,
    this.description,
    this.preparationHours,
  });

  factory TestItem.fromJson(Map<String, dynamic> json) {
    return TestItem(
      testId: json['testId'] ?? '',
      testName: json['testName'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'],
      preparationHours: json['preparationHours'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'testName': testName,
      'category': category,
      'price': price,
      'description': description,
      'preparationHours': preparationHours,
    };
  }
}

class AvailableLabTest {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final List<String> parameters;
  final int? preparationHours;
  final String? reportTime;

  AvailableLabTest({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.parameters,
    this.preparationHours,
    this.reportTime,
  });

  factory AvailableLabTest.fromJson(Map<String, dynamic> json, String id) {
    return AvailableLabTest(
      id: id,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      parameters: List<String>.from(json['parameters'] ?? []),
      preparationHours: json['preparationHours'],
      reportTime: json['reportTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'parameters': parameters,
      'preparationHours': preparationHours,
      'reportTime': reportTime,
    };
  }
}
