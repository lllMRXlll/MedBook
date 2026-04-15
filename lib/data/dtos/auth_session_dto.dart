import '../../domain/entities/auth_session.dart';
import 'user_dto.dart';

class AuthSessionDto {
  const AuthSessionDto({required this.token, required this.user});

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    return AuthSessionDto(
      token: json['token'] as String,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String token;
  final UserDto user;

  AuthSession toEntity() => AuthSession(token: token, user: user.toEntity());

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};
}
