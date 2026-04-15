import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/requests/login_request.dart';
import '../../domain/requests/register_request.dart';
import '../dtos/auth_session_dto.dart';
import '../services/local_session_store.dart';
import '../services/mock_api_service.dart';
import '../services/session_manager.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required MockApiService apiService,
    required LocalSessionStore sessionStore,
    required SessionManager sessionManager,
  }) : _apiService = apiService,
       _sessionStore = sessionStore,
       _sessionManager = sessionManager;

  final MockApiService _apiService;
  final LocalSessionStore _sessionStore;
  final SessionManager _sessionManager;

  @override
  Future<AuthSession> login(LoginRequest request) async {
    final session = await _apiService.login(request);
    await _persistSession(session);
    return session.toEntity();
  }

  @override
  Future<AuthSession> register(RegisterRequest request) async {
    final session = await _apiService.register(request);
    await _persistSession(session);
    return session.toEntity();
  }

  @override
  Future<void> logout() async {
    _sessionManager.currentSession = null;
    await _sessionStore.clearSession();
  }

  @override
  Future<User?> currentUser() async {
    if (_sessionManager.currentSession != null) {
      return _sessionManager.currentSession!.user;
    }

    final cached = await _sessionStore.readSession();
    if (cached == null) {
      return null;
    }

    _sessionManager.currentSession = cached.toEntity();
    return cached.user.toEntity();
  }

  Future<void> _persistSession(AuthSessionDto session) async {
    _sessionManager.currentSession = session.toEntity();
    await _sessionStore.saveSession(session);
  }
}
