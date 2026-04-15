import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/enums/view_status.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/doctor_repository.dart';

class DashboardState extends Equatable {
  const DashboardState({
    required this.status,
    this.user,
    this.nextAppointment,
    this.featuredDoctors = const [],
    this.upcomingCount = 0,
    this.historyCount = 0,
    this.message,
  });

  const DashboardState.initial() : this(status: ViewStatus.initial);

  final ViewStatus status;
  final User? user;
  final Appointment? nextAppointment;
  final List<Doctor> featuredDoctors;
  final int upcomingCount;
  final int historyCount;
  final String? message;

  DashboardState copyWith({
    ViewStatus? status,
    User? user,
    Appointment? nextAppointment,
    List<Doctor>? featuredDoctors,
    int? upcomingCount,
    int? historyCount,
    String? message,
    bool clearMessage = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      user: user ?? this.user,
      nextAppointment: nextAppointment ?? this.nextAppointment,
      featuredDoctors: featuredDoctors ?? this.featuredDoctors,
      upcomingCount: upcomingCount ?? this.upcomingCount,
      historyCount: historyCount ?? this.historyCount,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    nextAppointment,
    featuredDoctors,
    upcomingCount,
    historyCount,
    message,
  ];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required AuthRepository authRepository,
    required DoctorRepository doctorRepository,
    required AppointmentRepository appointmentRepository,
  }) : _authRepository = authRepository,
       _doctorRepository = doctorRepository,
       _appointmentRepository = appointmentRepository,
       super(const DashboardState.initial());

  final AuthRepository _authRepository;
  final DoctorRepository _doctorRepository;
  final AppointmentRepository _appointmentRepository;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, clearMessage: true));
    try {
      final user = await _authRepository.currentUser();
      if (user == null) {
        emit(const DashboardState.initial());
        return;
      }

      final doctors = await _doctorRepository.getDoctors();
      final appointments = await _appointmentRepository.getAppointments();
      final upcoming = appointments.where((item) => item.isUpcoming).toList()
        ..sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));
      final history = appointments.where((item) => item.isHistory).toList();

      emit(
        state.copyWith(
          status: ViewStatus.success,
          user: user,
          nextAppointment: upcoming.isEmpty ? null : upcoming.first,
          featuredDoctors: doctors
              .where((doctor) => doctor.featured)
              .take(3)
              .toList(),
          upcomingCount: upcoming.length,
          historyCount: history.length,
          clearMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ViewStatus.error,
          message: 'Не удалось загрузить главную страницу.',
        ),
      );
    }
  }

  void reset() => emit(const DashboardState.initial());
}
