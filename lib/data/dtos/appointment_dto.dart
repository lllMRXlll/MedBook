import '../../domain/entities/appointment.dart';

class AppointmentDto {
  const AppointmentDto({
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

  factory AppointmentDto.fromJson(Map<String, dynamic> json) {
    return AppointmentDto(
      id: json['id'] as String,
      doctorId: json['doctorId'] as String,
      userId: json['userId'] as String,
      doctorName: json['doctorName'] as String,
      specializationName: json['specializationName'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      status: AppointmentStatus.values.firstWhere(
        (value) => value.name == json['status'],
      ),
      location: json['location'] as String,
      price: json['price'] as int,
    );
  }

  final String id;
  final String doctorId;
  final String userId;
  final String doctorName;
  final String specializationName;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final String location;
  final int price;

  Appointment toEntity() => Appointment(
    id: id,
    doctorId: doctorId,
    userId: userId,
    doctorName: doctorName,
    specializationName: specializationName,
    scheduledAt: scheduledAt,
    status: status,
    location: location,
    price: price,
  );

  AppointmentDto copyWith({DateTime? scheduledAt, AppointmentStatus? status}) {
    return AppointmentDto(
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
}
