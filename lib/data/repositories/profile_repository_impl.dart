import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/requests/update_profile_request.dart';
import '../dtos/auth_session_dto.dart';
import '../dtos/user_dto.dart';
import '../services/local_session_store.dart';
import '../services/mock_api_service.dart';
import '../services/session_manager.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required MockApiService apiService,
    required SessionManager sessionManager,
    required LocalSessionStore sessionStore,
  }) : _apiService = apiService,
       _sessionManager = sessionManager,
       _sessionStore = sessionStore;

  final MockApiService _apiService;
  final SessionManager _sessionManager;
  final LocalSessionStore _sessionStore;

  @override
  Future<User> getProfile() async {
    final user = await _apiService.getProfile(_sessionManager.userIdOrThrow);
    return user.toEntity();
  }

  @override
  Future<User> updateProfile(UpdateProfileRequest request) async {
    final updated = await _apiService.updateProfile(
      _sessionManager.userIdOrThrow,
      request,
    );

    final current = _sessionManager.currentSession;
    if (current != null) {
      final nextSession = AuthSession(
        token: current.token,
        user: updated.toEntity(),
      );
      _sessionManager.currentSession = nextSession;
      await _sessionStore.saveSession(
        AuthSessionDto(
          token: nextSession.token,
          user: UserDto(
            id: updated.id,
            fullName: updated.fullName,
            email: updated.email,
            phone: updated.phone,
            password: '',
            birthDate: updated.birthDate,
            city: updated.city,
          ),
        ),
      );
    }

    return updated.toEntity();
  }
}
