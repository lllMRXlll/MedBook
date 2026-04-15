import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.birthDate,
    this.city,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final DateTime? birthDate;
  final String? city;

  User copyWith({
    String? fullName,
    String? email,
    String? phone,
    DateTime? birthDate,
    String? city,
  }) {
    return User(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, phone, birthDate, city];
}
