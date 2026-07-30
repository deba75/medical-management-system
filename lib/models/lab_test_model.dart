import 'package:cloud_firestore/cloud_firestore.dart';

enum LabTestStatus {
  pending,
  approved,
  scheduled,
  collectorAssigned,
  sampleCollected,
  processing,
  completed,
  cancelled
}

enum SampleCollectionType { homeSample, centerWalkIn, visitLab }

enum LabPaymentMethod { online, manual, due }

enum LabPaymentStatus { pending, paid, due }

class LabTestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String? familyMemberId;
  final String? familyMemberName;
  final String? familyMemberRelationship;
  final String diagnosticCentreId;
  final String diagnosticCentreName;
  final List<TestItem> tests;
  final LabTestStatus status;
  final SampleCollectionType collectionType;
  final LabPaymentMethod paymentMethod;
  final LabPaymentStatus paymentStatus;
  final DateTime scheduledDate;
  final String? timeSlot;
  final String? address;
  final double totalAmount;
  final double homeCollectionFee;
  final double? discount;
  final String? couponCode;
  final String? prescriptionId;
  final String? doctorId;
  final String? doctorName;
  final String? reportUrl;
  final DateTime? reportGeneratedAt;
  final String? notes;
  final String? phlebotomistName;
  final String? phlebotomistPhone;
  final String? phlebotomistEquipment;
  final DateTime createdAt;

  LabTestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.familyMemberId,
    this.familyMemberName,
    this.familyMemberRelationship,
    required this.diagnosticCentreId,
    required this.diagnosticCentreName,
    required this.tests,
    required this.status,
    required this.collectionType,
    this.paymentMethod = LabPaymentMethod.online,
    this.paymentStatus = LabPaymentStatus.pending,
    required this.scheduledDate,
    this.timeSlot,
    this.address,
    required this.totalAmount,
    this.homeCollectionFee = 0.0,
    this.discount,
    this.couponCode,
    this.prescriptionId,
    this.doctorId,
    this.doctorName,
    this.reportUrl,
    this.reportGeneratedAt,
    this.notes,
    this.phlebotomistName,
    this.phlebotomistPhone,
    this.phlebotomistEquipment,
    required this.createdAt,
  });

  factory LabTestModel.fromJson(Map<String, dynamic> json, String id) {
    return LabTestModel(
      id: id,
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      familyMemberId: json['familyMemberId'],
      familyMemberName: json['familyMemberName'],
      familyMemberRelationship: json['familyMemberRelationship'],
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
        orElse: () => SampleCollectionType.centerWalkIn,
      ),
      paymentMethod: LabPaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => LabPaymentMethod.online,
      ),
      paymentStatus: LabPaymentStatus.values.firstWhere(
        (e) => e.name == json['paymentStatus'],
        orElse: () => LabPaymentStatus.pending,
      ),
      scheduledDate: json['scheduledDate'] is Timestamp
          ? (json['scheduledDate'] as Timestamp).toDate()
          : DateTime.parse(json['scheduledDate'] ?? DateTime.now().toIso8601String()),
      timeSlot: json['timeSlot'],
      address: json['address'],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      homeCollectionFee: (json['homeCollectionFee'] ?? 0).toDouble(),
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
      phlebotomistName: json['phlebotomistName'],
      phlebotomistPhone: json['phlebotomistPhone'],
      phlebotomistEquipment: json['phlebotomistEquipment'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'familyMemberId': familyMemberId,
      'familyMemberName': familyMemberName,
      'familyMemberRelationship': familyMemberRelationship,
      'diagnosticCentreId': diagnosticCentreId,
      'diagnosticCentreName': diagnosticCentreName,
      'tests': tests.map((e) => e.toJson()).toList(),
      'status': status.name,
      'collectionType': collectionType.name,
      'paymentMethod': paymentMethod.name,
      'paymentStatus': paymentStatus.name,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'timeSlot': timeSlot,
      'address': address,
      'totalAmount': totalAmount,
      'homeCollectionFee': homeCollectionFee,
      'discount': discount,
      'couponCode': couponCode,
      'prescriptionId': prescriptionId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'reportUrl': reportUrl,
      'reportGeneratedAt': reportGeneratedAt != null ? Timestamp.fromDate(reportGeneratedAt!) : null,
      'notes': notes,
      'phlebotomistName': phlebotomistName,
      'phlebotomistPhone': phlebotomistPhone,
      'phlebotomistEquipment': phlebotomistEquipment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  double get finalAmount => (totalAmount + homeCollectionFee) - (discount ?? 0);

  bool get isForFamilyMember => familyMemberName != null && familyMemberName!.isNotEmpty;

  String get targetPatientDisplay => isForFamilyMember 
      ? '$familyMemberName ($familyMemberRelationship)' 
      : '$patientName (Self)';

  String get collectionTypeDisplay {
    switch (collectionType) {
      case SampleCollectionType.homeSample:
        return 'Home Specimen Collection';
      case SampleCollectionType.centerWalkIn:
      case SampleCollectionType.visitLab:
        return 'Diagnostic Center Walk-In';
    }
  }

  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case LabPaymentMethod.online:
        return 'Online Payment';
      case LabPaymentMethod.manual:
        return 'Pay Manually (Cash on Collection)';
      case LabPaymentMethod.due:
        return 'Pay Later / Due';
    }
  }

  String get statusDisplay {
    switch (status) {
      case LabTestStatus.pending:
        return 'Pending Verification';
      case LabTestStatus.approved:
        return 'Center Approved';
      case LabTestStatus.scheduled:
        return 'Scheduled';
      case LabTestStatus.collectorAssigned:
        return 'Technician Assigned';
      case LabTestStatus.sampleCollected:
        return 'Sample Collected (In Transit)';
      case LabTestStatus.processing:
        return 'Lab Processing';
      case LabTestStatus.completed:
        return 'Report Uploaded';
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
  final String? diagnosticCentreId;
  final String? diagnosticCentreName;

  TestItem({
    required this.testId,
    required this.testName,
    required this.category,
    required this.price,
    this.description,
    this.preparationHours,
    this.diagnosticCentreId,
    this.diagnosticCentreName,
  });

  factory TestItem.fromJson(Map<String, dynamic> json) {
    return TestItem(
      testId: json['testId'] ?? '',
      testName: json['testName'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'],
      preparationHours: json['preparationHours'],
      diagnosticCentreId: json['diagnosticCentreId'] ?? json['centreId'],
      diagnosticCentreName: json['diagnosticCentreName'] ?? json['centreName'],
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
      'diagnosticCentreId': diagnosticCentreId,
      'diagnosticCentreName': diagnosticCentreName,
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
  final String? centreId;
  final String? centreName;

  AvailableLabTest({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.parameters,
    this.preparationHours,
    this.reportTime,
    this.centreId,
    this.centreName,
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
      centreId: json['centreId'],
      centreName: json['centreName'] ?? json['diagnosticCentreName'],
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
      'centreId': centreId,
      'centreName': centreName,
    };
  }
}
