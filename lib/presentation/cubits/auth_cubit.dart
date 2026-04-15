import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/enums/view_status.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/requests/login_request.dart';
import '../../domain/requests/register_request.dart';

enum AuthFlowStatus { authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    required this.authStatus,
    required this.status,
    this.user,
    this.message,
  });

  factory AuthState.initial(AuthSession? initialSession) {
    return AuthState(
      authStatus: initialSession == null
          ? AuthFlowStatus.unauthenticated
          : AuthFlowStatus.authenticated,
      status: ViewStatus.initial,
      user: initialSession?.user,
    );
  }

  final AuthFlowStatus authStatus;
  final ViewStatus status;
  final User? user;
  final String? message;

  bool get isAuthenticated =>
      authStatus == AuthFlowStatus.authenticated && user != null;

  AuthState copyWith({
    AuthFlowStatus? authStatus,
    ViewStatus? status,
    User? user,
    String? message,
    bool clearMessage = false,
  }) {
    return AuthState(
      authStatus: authStatus ?? this.authStatus,
      status: status ?? this.status,
      user: user ?? this.user,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [authStatus, status, user, message];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository authRepository,
    AuthSession? initialSession,
  }) : _authRepository = authRepository,
       super(AuthState.initial(initialSession));

  final AuthRepository _authRepository;

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    emit(state.copyWith(status: ViewStatus.submitting, clearMessage: true));
    try {
      final session = await _authRepository.login(
        LoginRequest(identifier: identifier, password: password),
      );
      emit(
        state.copyWith(
          authStatus: AuthFlowStatus.authenticated,
          status: ViewStatus.success,
          user: session.user,
          clearMessage: true,
        ),
      );
    } on StateError catch (error) {
      emit(
        state.copyWith(
          authStatus: AuthFlowStatus.unauthenticated,
          status: ViewStatus.error,
          user: null,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          authStatus: AuthFlowStatus.unauthenticated,
          status: ViewStatus.error,
          user: null,
          message: 'Не удалось выполнить вход.',
        ),
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    emit(state.copyWith(status: ViewStatus.submitting, clearMessage: true));
    try {
      final session = await _authRepository.register(
        RegisterRequest(
          fullName: fullName,
          email: email,
          phone: phone,
          password: password,
        ),
      );
      emit(
        state.copyWith(
          authStatus: AuthFlowStatus.authenticated,
          status: ViewStatus.success,
          user: session.user,
          clearMessage: true,
        ),
      );
    } on StateError catch (error) {
      emit(
        state.copyWith(
          authStatus: AuthFlowStatus.unauthenticated,
          status: ViewStatus.error,
          user: null,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          authStatus: AuthFlowStatus.unauthenticated,
          status: ViewStatus.error,
          user: null,
          message: 'Не удалось создать аккаунт.',
        ),
      );
    }
  }

  Future<void> logout() async {
    emit(state.copyWith(status: ViewStatus.submitting, clearMessage: true));
    await _authRepository.logout();
    emit(
      const AuthState(
        authStatus: AuthFlowStatus.unauthenticated,
        status: ViewStatus.initial,
      ),
    );
  }

  void updateUser(User user) {
    emit(
      state.copyWith(
        authStatus: AuthFlowStatus.authenticated,
        status: ViewStatus.success,
        user: user,
        clearMessage: true,
      ),
    );
  }

  void clearMessage() {
    emit(state.copyWith(clearMessage: true));
  }
}
