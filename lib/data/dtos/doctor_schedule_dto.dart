import '../../domain/entities/doctor_schedule.dart';

class DoctorScheduleDto {
  const DoctorScheduleDto({
    required this.workDays,
    required this.startHour,
    required this.endHour,
    required this.slotMinutes,
  });

  factory DoctorScheduleDto.fromJson(Map<String, dynamic> json) {
    return DoctorScheduleDto(
      workDays: (json['workDays'] as List<dynamic>).cast<int>(),
      startHour: json['startHour'] as int,
      endHour: json['endHour'] as int,
      slotMinutes: json['slotMinutes'] as int,
    );
  }

  final List<int> workDays;
  final int startHour;
  final int endHour;
  final int slotMinutes;

  DoctorSchedule toEntity() => DoctorSchedule(
    workDays: workDays,
    startHour: startHour,
    endHour: endHour,
    slotMinutes: slotMinutes,
  );
}
