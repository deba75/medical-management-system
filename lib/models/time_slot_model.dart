class TimeSlotModel {
  final String slotId;
  final String start;
  final String end;
  final bool isBooked;

  TimeSlotModel({
    required this.slotId,
    required this.start,
    required this.end,
    this.isBooked = false,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      slotId: json['slotId'] ?? '',
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      isBooked: json['isBooked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
      'start': start,
      'end': end,
      'isBooked': isBooked,
    };
  }

  String get displayTime => '$start - $end';
}

class DoctorScheduleModel {
  final String scheduleId;
  final String doctorId;
  final int dayOfWeek;
  final List<TimeSlotModel> timeSlots;

  DoctorScheduleModel({
    required this.scheduleId,
    required this.doctorId,
    required this.dayOfWeek,
    required this.timeSlots,
  });

  factory DoctorScheduleModel.fromJson(Map<String, dynamic> json, String id) {
    return DoctorScheduleModel(
      scheduleId: id,
      doctorId: json['doctorId'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 0,
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
      'timeSlots': timeSlots.map((slot) => slot.toJson()).toList(),
    };
  }
}
