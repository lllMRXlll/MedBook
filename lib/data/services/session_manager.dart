import '../../domain/entities/auth_session.dart';

class SessionManager {
  AuthSession? currentSession;

  bool get isAuthenticated => currentSession != null;

  String get userIdOrThrow {
    final session = currentSession;
    if (session == null) {
      throw StateError('Пользователь не авторизован.');
    }
    return session.user.id;
  }
}
