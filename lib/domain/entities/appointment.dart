import 'package:equatable/equatable.dart';

enum AppointmentStatus { scheduled, cancelled, completed }

class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.doctorName,
    required this.specializationName,
    required this.scheduledAt,
    required this.status,
    required this.location,
    required this.price,
  });

  final String id;
  final String doctorId;
  final String userId;
  final String doctorName;
  final String specializationName;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final String location;
  final int price;

  bool get isUpcoming =>
      status != AppointmentStatus.cancelled &&
      scheduledAt.isAfter(DateTime.now());

  bool get isHistory =>
      status == AppointmentStatus.cancelled ||
      scheduledAt.isBefore(DateTime.now());

  Appointment copyWith({DateTime? scheduledAt, AppointmentStatus? status}) {
    return Appointment(
      id: id,
      doctorId: doctorId,
      userId: userId,
      doctorName: doctorName,
      specializationName: specializationName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      location: location,
      price: price,
    );
  }

  @override
  List<Object?> get props => [
    id,
    doctorId,
    userId,
    doctorName,
    specializationName,
    scheduledAt,
    status,
    location,
    price,
  ];
}
