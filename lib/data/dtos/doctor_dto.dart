import '../../domain/entities/doctor.dart';
import '../../domain/entities/specialization.dart';
import 'doctor_schedule_dto.dart';

class DoctorDto {
  const DoctorDto({
    required this.id,
    required this.name,
    required this.specializationId,
    required this.description,
    required this.experienceYears,
    required this.rating,
    required this.price,
    required this.location,
    required this.featured,
    required this.schedule,
  });

  factory DoctorDto.fromJson(Map<String, dynamic> json) {
    return DoctorDto(
      id: json['id'] as String,
      name: json['name'] as String,
      specializationId: json['specializationId'] as String,
      description: json['description'] as String,
      experienceYears: json['experienceYears'] as int,
      rating: (json['rating'] as num).toDouble(),
      price: json['price'] as int,
      location: json['location'] as String,
      featured: json['featured'] as bool,
      schedule: DoctorScheduleDto.fromJson(
        json['schedule'] as Map<String, dynamic>,
      ),
    );
  }

  final String id;
  final String name;
  final String specializationId;
  final String description;
  final int experienceYears;
  final double rating;
  final int price;
  final String location;
  final bool featured;
  final DoctorScheduleDto schedule;

  Doctor toEntity(Specialization specialization) => Doctor(
    id: id,
    name: name,
    specialization: specialization,
    description: description,
    experienceYears: experienceYears,
    rating: rating,
    price: price,
    location: location,
    schedule: schedule.toEntity(),
    featured: featured,
  );
}
