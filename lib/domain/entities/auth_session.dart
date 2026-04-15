import 'package:equatable/equatable.dart';

import 'user.dart';

class AuthSession extends Equatable {
  const AuthSession({required this.token, required this.user});

  final String token;
  final User user;

  AuthSession copyWith({String? token, User? user}) {
    return AuthSession(token: token ?? this.token, user: user ?? this.user);
  }

  @override
  List<Object?> get props => [token, user];
}
