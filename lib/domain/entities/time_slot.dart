import 'package:equatable/equatable.dart';

class TimeSlot extends Equatable {
  const TimeSlot({required this.startsAt, required this.isAvailable});

  final DateTime startsAt;
  final bool isAvailable;

  TimeSlot copyWith({DateTime? startsAt, bool? isAvailable}) {
    return TimeSlot(
      startsAt: startsAt ?? this.startsAt,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  List<Object?> get props => [startsAt, isAvailable];
}
