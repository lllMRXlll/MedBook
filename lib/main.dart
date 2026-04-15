import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/appointment_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/doctor_repository_impl.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'data/services/api_client.dart';
import 'data/services/local_session_store.dart';
import 'data/services/mock_api_service.dart';
import 'data/services/session_manager.dart';
import 'presentation/cubits/appointments_cubit.dart';
import 'presentation/cubits/auth_cubit.dart';
import 'presentation/cubits/dashboard_cubit.dart';
import 'presentation/cubits/doctors_cubit.dart';
import 'presentation/cubits/profile_cubit.dart';
import 'presentation/routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU');

  final preferences = await SharedPreferences.getInstance();
  final sessionStore = LocalSessionStore(preferences);
  final sessionManager = SessionManager();
  final apiClient = ApiClient();
  final mockApiService = MockApiService(
    assetBundle: rootBundle,
    apiClient: apiClient,
  );
  await mockApiService.initialize();

  final cachedSession = await sessionStore.readSession();
  sessionManager.currentSession = cachedSession?.toEntity();

  final authRepository = AuthRepositoryImpl(
    apiService: mockApiService,
    sessionStore: sessionStore,
    sessionManager: sessionManager,
  );
  final doctorRepository = DoctorRepositoryImpl(mockApiService);
  final appointmentRepository = AppointmentRepositoryImpl(
    apiService: mockApiService,
    sessionManager: sessionManager,
  );
  final profileRepository = ProfileRepositoryImpl(
    apiService: mockApiService,
    sessionManager: sessionManager,
    sessionStore: sessionStore,
  );

  final authCubit = AuthCubit(
    authRepository: authRepository,
    initialSession: cachedSession?.toEntity(),
  );
  final dashboardCubit = DashboardCubit(
    authRepository: authRepository,
    doctorRepository: doctorRepository,
    appointmentRepository: appointmentRepository,
  );
  final doctorsCubit = DoctorsCubit(doctorRepository);
  final appointmentsCubit = AppointmentsCubit(appointmentRepository);
  final profileCubit = ProfileCubit(
    profileRepository: profileRepository,
    authCubit: authCubit,
  );

  await doctorsCubit.load();
  if (authCubit.state.isAuthenticated) {
    await Future.wait([
      dashboardCubit.load(),
      appointmentsCubit.load(),
      profileCubit.load(),
    ]);
  }

  final router = AppRouter(
    authCubit: authCubit,
    doctorRepository: doctorRepository,
    appointmentRepository: appointmentRepository,
  );

  runApp(
    MedBookApp(
      router: router,
      authCubit: authCubit,
      dashboardCubit: dashboardCubit,
      doctorsCubit: doctorsCubit,
      appointmentsCubit: appointmentsCubit,
      profileCubit: profileCubit,
    ),
  );
}
