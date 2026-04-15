import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medbook_frontend/core/enums/view_status.dart';
import 'package:medbook_frontend/domain/entities/auth_session.dart';
import 'package:medbook_frontend/domain/entities/user.dart';
import 'package:medbook_frontend/domain/repositories/auth_repository.dart';
import 'package:medbook_frontend/domain/requests/login_request.dart';
import 'package:medbook_frontend/domain/requests/register_request.dart';
import 'package:medbook_frontend/presentation/cubits/auth_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  const user = User(
    id: 'user-1',
    fullName: 'Анна Смирнова',
    email: 'anna@example.com',
    phone: '+79991234567',
    city: 'Москва',
  );
  const session = AuthSession(token: 'token', user: user);

  setUpAll(() {
    registerFallbackValue(
      const LoginRequest(
        identifier: 'anna@example.com',
        password: 'password123',
      ),
    );
    registerFallbackValue(
      const RegisterRequest(
        fullName: 'Анна Смирнова',
        email: 'anna@example.com',
        phone: '+79991234567',
        password: 'password123',
      ),
    );
  });

  setUp(() {
    authRepository = MockAuthRepository();
  });

  test('initial state uses cached session when provided', () {
    final cubit = AuthCubit(
      authRepository: authRepository,
      initialSession: session,
    );

    expect(cubit.state.isAuthenticated, isTrue);
    expect(cubit.state.user, user);
  });

  blocTest<AuthCubit, AuthState>(
    'login emits authenticated state on success',
    build: () {
      when(() => authRepository.login(any())).thenAnswer((_) async => session);
      return AuthCubit(authRepository: authRepository);
    },
    act: (cubit) =>
        cubit.login(identifier: 'anna@example.com', password: 'password123'),
    expect: () => [
      isA<AuthState>().having(
        (state) => state.status,
        'status',
        equals(ViewStatus.submitting),
      ),
      isA<AuthState>()
          .having((state) => state.isAuthenticated, 'authenticated', isTrue)
          .having((state) => state.user, 'user', equals(user)),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'login emits error state on failure',
    build: () {
      when(
        () => authRepository.login(any()),
      ).thenThrow(StateError('Неверный логин или пароль.'));
      return AuthCubit(authRepository: authRepository);
    },
    act: (cubit) =>
        cubit.login(identifier: 'wrong@example.com', password: 'bad-password'),
    expect: () => [
      isA<AuthState>().having(
        (state) => state.status,
        'status',
        equals(ViewStatus.submitting),
      ),
      isA<AuthState>()
          .having((state) => state.status, 'status', equals(ViewStatus.error))
          .having(
            (state) => state.message,
            'message',
            equals('Неверный логин или пароль.'),
          ),
    ],
  );
}
