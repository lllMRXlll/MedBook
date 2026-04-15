import '../../domain/entities/specialization.dart';

class SpecializationDto {
  const SpecializationDto({required this.id, required this.title});

  factory SpecializationDto.fromJson(Map<String, dynamic> json) {
    return SpecializationDto(
      id: json['id'] as String,
      title: json['title'] as String,
    );
  }

  final String id;
  final String title;

  Specialization toEntity() => Specialization(id: id, title: title);
}
