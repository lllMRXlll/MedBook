import '../entities/auth_session.dart';
import '../entities/user.dart';
import '../requests/login_request.dart';
import '../requests/register_request.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login(LoginRequest request);
  Future<AuthSession> register(RegisterRequest request);
  Future<void> logout();
  Future<User?> currentUser();
}
