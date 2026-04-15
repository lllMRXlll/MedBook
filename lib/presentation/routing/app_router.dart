import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/go_router_refresh_stream.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/booking_cubit.dart';
import '../cubits/doctor_details_cubit.dart';
import '../screens/appointments/appointments_screen.dart';
import '../screens/appointments/booking_confirm_screen.dart';
import '../screens/appointments/booking_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/doctors/doctor_details_screen.dart';
import '../screens/doctors/doctors_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/layout/app_shell.dart';

class BookingRouteArgs {
  const BookingRouteArgs({required this.doctorId, this.existingAppointment});

  final String doctorId;
  final Appointment? existingAppointment;
}

class BookingConfirmationArgs {
  const BookingConfirmationArgs({
    required this.doctor,
    required this.selectedDate,
    required this.selectedSlot,
    this.existingAppointment,
  });

  final Doctor doctor;
  final DateTime selectedDate;
  final TimeSlot selectedSlot;
  final Appointment? existingAppointment;
}

class AppRouter {
  AppRouter({
    required AuthCubit authCubit,
    required DoctorRepository doctorRepository,
    required AppointmentRepository appointmentRepository,
  }) : router = GoRouter(
         initialLocation: '/',
         refreshListenable: GoRouterRefreshStream(authCubit.stream),
         redirect: (context, state) {
           final loggedIn = authCubit.state.isAuthenticated;
           final location = state.uri.toString();
           final isAuthRoute = location == '/login' || location == '/register';

           if (!loggedIn) {
             if (location == '/' || location.startsWith('/app')) {
               return '/login';
             }
             return null;
           }

           if (location == '/' || isAuthRoute) {
             return '/app/home';
           }

           return null;
         },
         routes: [
           GoRoute(
             path: '/',
             pageBuilder: (context, state) =>
                 _page(key: state.pageKey, child: const SizedBox.shrink()),
           ),
           GoRoute(
             path: '/login',
             pageBuilder: (context, state) =>
                 _page(key: state.pageKey, child: const LoginScreen()),
           ),
           GoRoute(
             path: '/register',
             pageBuilder: (context, state) =>
                 _page(key: state.pageKey, child: const RegisterScreen()),
           ),
           StatefulShellRoute.indexedStack(
             builder: (context, state, navigationShell) {
               return AppShell(navigationShell: navigationShell);
             },
             branches: [
               StatefulShellBranch(
                 routes: [
                   GoRoute(
                     path: '/app/home',
                     pageBuilder: (context, state) => _page(
                       key: state.pageKey,
                       child: const DashboardScreen(),
                     ),
                   ),
                 ],
               ),
               StatefulShellBranch(
                 routes: [
                   GoRoute(
                     path: '/app/doctors',
                     pageBuilder: (context, state) => _page(
                       key: state.pageKey,
                       child: const DoctorsScreen(),
                     ),
                   ),
                 ],
               ),
               StatefulShellBranch(
                 routes: [
                   GoRoute(
                     path: '/app/appointments',
                     pageBuilder: (context, state) => _page(
                       key: state.pageKey,
                       child: const AppointmentsScreen(),
                     ),
                   ),
                 ],
               ),
               StatefulShellBranch(
                 routes: [
                   GoRoute(
                     path: '/app/profile',
                     pageBuilder: (context, state) => _page(
                       key: state.pageKey,
                       child: const ProfileScreen(),
                     ),
                   ),
                 ],
               ),
             ],
           ),
           GoRoute(
             path: '/app/doctors/:id',
             pageBuilder: (context, state) => _page(
               key: state.pageKey,
               child: BlocProvider(
                 create: (context) =>
                     DoctorDetailsCubit(doctorRepository)
                       ..load(state.pathParameters['id']!),
                 child: DoctorDetailsScreen(
                   doctorId: state.pathParameters['id']!,
                 ),
               ),
             ),
           ),
           GoRoute(
             path: '/app/appointments/book',
             pageBuilder: (context, state) {
               final args = state.extra! as BookingRouteArgs;
               return _page(
                 key: state.pageKey,
                 child: BlocProvider(
                   create: (context) =>
                       BookingCubit(
                         doctorRepository: doctorRepository,
                         appointmentRepository: appointmentRepository,
                         existingAppointment: args.existingAppointment,
                       )..load(
                         args.doctorId,
                         preferredDate: args.existingAppointment?.scheduledAt,
                       ),
                   child: BookingScreen(args: args),
                 ),
               );
             },
           ),
           GoRoute(
             path: '/app/appointments/confirm',
             pageBuilder: (context, state) {
               final args = state.extra! as BookingConfirmationArgs;
               return _page(
                 key: state.pageKey,
                 child: BlocProvider(
                   create: (context) => BookingCubit(
                     doctorRepository: doctorRepository,
                     appointmentRepository: appointmentRepository,
                     initialDoctor: args.doctor,
                     initialDate: args.selectedDate,
                     initialSlot: args.selectedSlot,
                     existingAppointment: args.existingAppointment,
                   ),
                   child: BookingConfirmScreen(args: args),
                 ),
               );
             },
           ),
           GoRoute(
             path: '/app/profile/edit',
             pageBuilder: (context, state) =>
                 _page(key: state.pageKey, child: const EditProfileScreen()),
           ),
         ],
       );

  final GoRouter router;

  static CustomTransitionPage<void> _page({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
