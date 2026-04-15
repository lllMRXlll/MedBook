import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medbook_frontend/domain/repositories/auth_repository.dart';
import 'package:medbook_frontend/domain/requests/login_request.dart';
import 'package:medbook_frontend/domain/requests/register_request.dart';
import 'package:medbook_frontend/presentation/cubits/auth_cubit.dart';
import 'package:medbook_frontend/presentation/screens/auth/login_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

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

  testWidgets('login screen validates empty identifier', (tester) async {
    final authCubit = AuthCubit(authRepository: authRepository);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: authCubit, child: const LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Войти'));
    await tester.pump();

    expect(find.text('Введите email или телефон'), findsOneWidget);
    expect(find.text('Минимум 6 символов'), findsOneWidget);
  });
}
