import 'package:cloud_firestore/cloud_firestore.dart';

class Chamber {
  final String id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final double consultationFee;
  final Map<String, WorkingHours> workingHours; // day -> hours
  final bool isActive;
  final String? hospitalId;
  
  Chamber({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.consultationFee,
    required this.workingHours,
    this.isActive = true,
    this.hospitalId,
  });
  
  factory Chamber.fromJson(Map<String, dynamic> json, String id) {
    final workingHoursData = json['workingHours'] as Map<String, dynamic>? ?? {};
    final workingHours = <String, WorkingHours>{};
    
    workingHoursData.forEach((key, value) {
      workingHours[key] = WorkingHours.fromJson(value as Map<String, dynamic>);
    });
    
    return Chamber(
      id: id,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
      consultationFee: (json['consultationFee'] ?? 0).toDouble(),
      workingHours: workingHours,
      isActive: json['isActive'] ?? true,
      hospitalId: json['hospitalId'],
    );
  }
  
  Map<String, dynamic> toJson() {
    final workingHoursData = <String, dynamic>{};
    workingHours.forEach((key, value) {
      workingHoursData[key] = value.toJson();
    });
    
    return {
      'name': name,
      'address': address,
      'city': city,
      'phone': phone,
      'consultationFee': consultationFee,
      'workingHours': workingHoursData,
      'isActive': isActive,
      'hospitalId': hospitalId,
    };
  }
}

class WorkingHours {
  final String startTime;
  final String endTime;
  final bool isAvailable;
  
  WorkingHours({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });
  
  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
    };
  }
}

class DoctorAvailability {
  final String id;
  final String doctorId;
  final String chamberId;
  final DateTime date;
  final List<TimeSlotAvailability> slots;
  final bool isLeave;
  final String? leaveReason;
  
  DoctorAvailability({
    required this.id,
    required this.doctorId,
    required this.chamberId,
    required this.date,
    required this.slots,
    this.isLeave = false,
    this.leaveReason,
  });
  
  factory DoctorAvailability.fromJson(Map<String, dynamic> json, String id) {
    final slotsData = json['slots'] as List<dynamic>? ?? [];
    final slots = slotsData
        .map((e) => TimeSlotAvailability.fromJson(e as Map<String, dynamic>))
        .toList();
    
    return DoctorAvailability(
      id: id,
      doctorId: json['doctorId'] ?? '',
      chamberId: json['chamberId'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      slots: slots,
      isLeave: json['isLeave'] ?? false,
      leaveReason: json['leaveReason'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'chamberId': chamberId,
      'date': Timestamp.fromDate(date),
      'slots': slots.map((e) => e.toJson()).toList(),
      'isLeave': isLeave,
      'leaveReason': leaveReason,
    };
  }
}

class TimeSlotAvailability {
  final String startTime;
  final String endTime;
  final bool isBooked;
  final String? appointmentId;
  
  TimeSlotAvailability({
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
    this.appointmentId,
  });
  
  factory TimeSlotAvailability.fromJson(Map<String, dynamic> json) {
    return TimeSlotAvailability(
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isBooked: json['isBooked'] ?? false,
      appointmentId: json['appointmentId'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isBooked': isBooked,
      'appointmentId': appointmentId,
    };
  }
}

class DoctorEarnings {
  final String id;
  final String doctorId;
  final DateTime date;
  final double onlineEarnings;
  final double offlineEarnings;
  final int onlineConsultations;
  final int offlineConsultations;
  
  DoctorEarnings({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.onlineEarnings,
    required this.offlineEarnings,
    required this.onlineConsultations,
    required this.offlineConsultations,
  });
  
  double get totalEarnings => onlineEarnings + offlineEarnings;
  int get totalConsultations => onlineConsultations + offlineConsultations;
  
  factory DoctorEarnings.fromJson(Map<String, dynamic> json, String id) {
    return DoctorEarnings(
      id: id,
      doctorId: json['doctorId'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      onlineEarnings: (json['onlineEarnings'] ?? 0).toDouble(),
      offlineEarnings: (json['offlineEarnings'] ?? 0).toDouble(),
      onlineConsultations: json['onlineConsultations'] ?? 0,
      offlineConsultations: json['offlineConsultations'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'date': Timestamp.fromDate(date),
      'onlineEarnings': onlineEarnings,
      'offlineEarnings': offlineEarnings,
      'onlineConsultations': onlineConsultations,
      'offlineConsultations': offlineConsultations,
    };
  }
}

class DoctorStats {
  final int totalPatients;
  final double avgConsultationTime;
  final double satisfactionScore;
  final int todayPatients;
  final int upcomingAppointments;
  
  DoctorStats({
    required this.totalPatients,
    required this.avgConsultationTime,
    required this.satisfactionScore,
    required this.todayPatients,
    required this.upcomingAppointments,
  });
}
