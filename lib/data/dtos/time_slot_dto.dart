import '../../domain/entities/time_slot.dart';

class TimeSlotDto {
  const TimeSlotDto({required this.startsAt, required this.isAvailable});

  final DateTime startsAt;
  final bool isAvailable;

  TimeSlot toEntity() => TimeSlot(startsAt: startsAt, isAvailable: isAvailable);
}
