/// Model class representing a Diagnostic Test
class DiagnosticTest {
  final String testId;
  final String testName;
  final String category;
  final double price;
  final String? description;
  final String? preparationInstructions;
  final String reportDeliveryTime;

  DiagnosticTest({
    required this.testId,
    required this.testName,
    required this.category,
    required this.price,
    this.description,
    this.preparationInstructions,
    this.reportDeliveryTime = 'Same Day',
  });

  factory DiagnosticTest.fromJson(Map<String, dynamic> json) {
    return DiagnosticTest(
      testId: json['testId'] ?? '',
      testName: json['testName'] ?? '',
      category: json['category'] ?? 'General',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'],
      preparationInstructions: json['preparationInstructions'],
      reportDeliveryTime: json['reportDeliveryTime'] ?? '24 hours',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'testName': testName,
      'category': category,
      'price': price,
      'description': description,
      'preparationInstructions': preparationInstructions,
      'reportDeliveryTime': reportDeliveryTime,
    };
  }
}

/// Model class representing a Diagnostic Centre
class DiagnosticCentreModel {
  final String centreId;
  final String name;
  final String address;
  final String city;
  final String contactNumber;
  final String? email;
  final String? website;
  final String openingTime;
  final String closingTime;
  final bool isOpen24Hours;
  final List<String> workingDays;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final double rating;
  final int totalReviews;
  final List<String> services;
  final List<DiagnosticTest> tests;
  final bool isHomeCollectionAvailable;
  final String? description;
  final DiagnosticCentreStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DiagnosticCentreModel({
    required this.centreId,
    required this.name,
    required this.address,
    required this.city,
    required this.contactNumber,
    this.email,
    this.website,
    this.openingTime = '08:00 AM',
    this.closingTime = '08:00 PM',
    this.isOpen24Hours = false,
    this.workingDays = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.services = const [],
    this.tests = const [],
    this.isHomeCollectionAvailable = false,
    this.description,
    this.status = DiagnosticCentreStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  factory DiagnosticCentreModel.fromJson(Map<String, dynamic> json, String id) {
    List<DiagnosticTest> testsList = [];
    if (json['tests'] != null) {
      testsList = (json['tests'] as List)
          .map((test) => DiagnosticTest.fromJson(test))
          .toList();
    }

    List<String> servicesList = [];
    if (json['services'] != null) {
      servicesList = List<String>.from(json['services']);
    }

    List<String> workingDaysList = [];
    if (json['workingDays'] != null) {
      workingDaysList = List<String>.from(json['workingDays']);
    } else {
      workingDaysList = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    }

    return DiagnosticCentreModel(
      centreId: id,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      email: json['email'],
      website: json['website'],
      openingTime: json['openingTime'] ?? '08:00 AM',
      closingTime: json['closingTime'] ?? '08:00 PM',
      isOpen24Hours: json['isOpen24Hours'] ?? false,
      workingDays: workingDaysList,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      imageUrl: json['imageUrl'],
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      services: servicesList,
      tests: testsList,
      isHomeCollectionAvailable: json['isHomeCollectionAvailable'] ?? false,
      description: json['description'],
      status: DiagnosticCentreStatus.values.firstWhere(
        (e) => e.toString() == 'DiagnosticCentreStatus.${json['status']}',
        orElse: () => DiagnosticCentreStatus.active,
      ),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'contactNumber': contactNumber,
      'email': email,
      'website': website,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'isOpen24Hours': isOpen24Hours,
      'workingDays': workingDays,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'rating': rating,
      'totalReviews': totalReviews,
      'services': services,
      'tests': tests.map((t) => t.toJson()).toList(),
      'isHomeCollectionAvailable': isHomeCollectionAvailable,
      'description': description,
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Check if the centre is currently open
  bool get isCurrentlyOpen {
    if (isOpen24Hours) return true;
    
    final now = DateTime.now();
    final currentDay = _getDayName(now.weekday);
    
    if (!workingDays.contains(currentDay)) return false;
    
    // Parse opening and closing times
    final openTime = _parseTime(openingTime);
    final closeTime = _parseTime(closingTime);
    final currentTime = TimeOfDay.fromDateTime(now);
    
    if (openTime == null || closeTime == null) return false;
    
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final openMinutes = openTime.hour * 60 + openTime.minute;
    final closeMinutes = closeTime.hour * 60 + closeTime.minute;
    
    return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return null;
      
      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;
      
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final period = parts[1].toUpperCase();
      
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  /// Get formatted timing string
  String get formattedTiming {
    if (isOpen24Hours) return 'Open 24 Hours';
    return '$openingTime - $closingTime';
  }

  /// Get test categories available
  List<String> get testCategories {
    return tests.map((t) => t.category).toSet().toList();
  }

  /// Get tests by category
  List<DiagnosticTest> getTestsByCategory(String category) {
    return tests.where((t) => t.category == category).toList();
  }
}

/// Status enum for Diagnostic Centre
enum DiagnosticCentreStatus {
  active,
  inactive,
  underMaintenance,
}

/// Helper class for TimeOfDay (needed since we can't import Flutter material here)
class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }
}
