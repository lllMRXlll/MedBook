import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'presentation/cubits/appointments_cubit.dart';
import 'presentation/cubits/auth_cubit.dart';
import 'presentation/cubits/dashboard_cubit.dart';
import 'presentation/cubits/doctors_cubit.dart';
import 'presentation/cubits/profile_cubit.dart';
import 'presentation/routing/app_router.dart';

class MedBookApp extends StatelessWidget {
  const MedBookApp({
    super.key,
    required this.router,
    required this.authCubit,
    required this.dashboardCubit,
    required this.doctorsCubit,
    required this.appointmentsCubit,
    required this.profileCubit,
  });

  final AppRouter router;
  final AuthCubit authCubit;
  final DashboardCubit dashboardCubit;
  final DoctorsCubit doctorsCubit;
  final AppointmentsCubit appointmentsCubit;
  final ProfileCubit profileCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<DashboardCubit>.value(value: dashboardCubit),
        BlocProvider<DoctorsCubit>.value(value: doctorsCubit),
        BlocProvider<AppointmentsCubit>.value(value: appointmentsCubit),
        BlocProvider<ProfileCubit>.value(value: profileCubit),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous.authStatus != current.authStatus ||
            previous.user != current.user,
        listener: (context, state) {
          if (state.isAuthenticated) {
            context.read<DashboardCubit>().load();
            context.read<AppointmentsCubit>().load();
            context.read<ProfileCubit>().load();
            context.read<DoctorsCubit>().load();
          } else {
            context.read<DashboardCubit>().reset();
            context.read<AppointmentsCubit>().reset();
            context.read<ProfileCubit>().reset();
          }
        },
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: AppStrings.appName,
          theme: AppTheme.lightTheme,
          routerConfig: router.router,
        ),
      ),
    );
  }
}
