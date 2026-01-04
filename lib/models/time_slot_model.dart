class TimeSlotModel {
  final String slotId;
  final String start;
  final String end;
  final bool isBooked;
  final String? hospitalId;
  final String? hospitalName;

  TimeSlotModel({
    required this.slotId,
    required this.start,
    required this.end,
    this.isBooked = false,
    this.hospitalId,
    this.hospitalName,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      slotId: json['slotId'] ?? '',
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      isBooked: json['isBooked'] ?? false,
      hospitalId: json['hospitalId'],
      hospitalName: json['hospitalName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
      'start': start,
      'end': end,
      'isBooked': isBooked,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
    };
  }

  String get displayTime => '$start - $end';
  String get displayWithHospital => hospitalName != null 
      ? '$start - $end at $hospitalName' 
      : '$start - $end';
}

class DoctorScheduleModel {
  final String scheduleId;
  final String doctorId;
  final int dayOfWeek;
  final String hospitalId;
  final String hospitalName;
  final List<TimeSlotModel> timeSlots;

  DoctorScheduleModel({
    required this.scheduleId,
    required this.doctorId,
    required this.dayOfWeek,
    required this.hospitalId,
    required this.hospitalName,
    required this.timeSlots,
  });

  factory DoctorScheduleModel.fromJson(Map<String, dynamic> json, String id) {
    return DoctorScheduleModel(
      scheduleId: id,
      doctorId: json['doctorId'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 0,
      hospitalId: json['hospitalId'] ?? '',
      hospitalName: json['hospitalName'] ?? '',
      timeSlots: (json['timeSlots'] as List?)
              ?.map((slot) => TimeSlotModel.fromJson(slot))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'dayOfWeek': dayOfWeek,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'timeSlots': timeSlots.map((slot) => slot.toJson()).toList(),
    };
  }
}
