import '../../domain/entities/user.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    this.birthDate,
    this.city,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      password: json['password'] as String? ?? '',
      birthDate: json['birthDate'] == null
          ? null
          : DateTime.parse(json['birthDate'] as String),
      city: json['city'] as String?,
    );
  }

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final DateTime? birthDate;
  final String? city;

  User toEntity() => User(
    id: id,
    fullName: fullName,
    email: email,
    phone: phone,
    birthDate: birthDate,
    city: city,
  );

  UserDto copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? password,
    DateTime? birthDate,
    String? city,
  }) {
    return UserDto(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'password': password,
    'birthDate': birthDate?.toIso8601String(),
    'city': city,
  };
}
