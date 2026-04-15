import 'package:equatable/equatable.dart';

class DoctorSchedule extends Equatable {
  const DoctorSchedule({
    required this.workDays,
    required this.startHour,
    required this.endHour,
    required this.slotMinutes,
  });

  final List<int> workDays;
  final int startHour;
  final int endHour;
  final int slotMinutes;

  bool worksOn(DateTime date) => workDays.contains(date.weekday);

  @override
  List<Object?> get props => [workDays, startHour, endHour, slotMinutes];
}
