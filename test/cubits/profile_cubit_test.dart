import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medbook_frontend/core/enums/view_status.dart';
import 'package:medbook_frontend/domain/entities/auth_session.dart';
import 'package:medbook_frontend/domain/entities/user.dart';
import 'package:medbook_frontend/domain/repositories/auth_repository.dart';
import 'package:medbook_frontend/domain/repositories/profile_repository.dart';
import 'package:medbook_frontend/domain/requests/login_request.dart';
import 'package:medbook_frontend/domain/requests/register_request.dart';
import 'package:medbook_frontend/domain/requests/update_profile_request.dart';
import 'package:medbook_frontend/presentation/cubits/auth_cubit.dart';
import 'package:medbook_frontend/presentation/cubits/profile_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockProfileRepository profileRepository;
  late MockAuthRepository authRepository;
  late AuthCubit authCubit;

  const initialUser = User(
    id: 'user-1',
    fullName: 'Анна Смирнова',
    email: 'anna@example.com',
    phone: '+79991234567',
    city: 'Москва',
  );
  const updatedUser = User(
    id: 'user-1',
    fullName: 'Анна Петрова',
    email: 'anna.pet@example.com',
    phone: '+79991234567',
    city: 'Санкт-Петербург',
  );

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
    registerFallbackValue(
      const UpdateProfileRequest(
        fullName: 'Анна Петрова',
        email: 'anna.pet@example.com',
        phone: '+79991234567',
        city: 'Санкт-Петербург',
      ),
    );
  });

  setUp(() {
    profileRepository = MockProfileRepository();
    authRepository = MockAuthRepository();
    authCubit = AuthCubit(
      authRepository: authRepository,
      initialSession: const AuthSession(token: 'token', user: initialUser),
    );
  });

  blocTest<ProfileCubit, ProfileState>(
    'updateProfile updates local profile and auth snapshot',
    build: () {
      when(
        () => profileRepository.updateProfile(any()),
      ).thenAnswer((_) async => updatedUser);
      return ProfileCubit(
        profileRepository: profileRepository,
        authCubit: authCubit,
      );
    },
    act: (cubit) => cubit.updateProfile(
      const UpdateProfileRequest(
        fullName: 'Анна Петрова',
        email: 'anna.pet@example.com',
        phone: '+79991234567',
        city: 'Санкт-Петербург',
      ),
    ),
    expect: () => [
      isA<ProfileState>().having(
        (state) => state.submissionStatus,
        'submissionStatus',
        equals(ViewStatus.submitting),
      ),
      isA<ProfileState>()
          .having(
            (state) => state.submissionStatus,
            'status',
            equals(ViewStatus.success),
          )
          .having((state) => state.user, 'user', equals(updatedUser)),
    ],
    verify: (_) {
      expect(authCubit.state.user, updatedUser);
    },
  );
}
