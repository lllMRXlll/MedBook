import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/enums/view_status.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';

enum AppointmentSegment { upcoming, history }

class AppointmentsState extends Equatable {
  const AppointmentsState({
    required this.status,
    this.appointments = const [],
    this.segment = AppointmentSegment.upcoming,
    this.processingAppointmentId,
    this.message,
  });

  const AppointmentsState.initial() : this(status: ViewStatus.initial);

  final ViewStatus status;
  final List<Appointment> appointments;
  final AppointmentSegment segment;
  final String? processingAppointmentId;
  final String? message;

  List<Appointment> get visibleAppointments {
    if (segment == AppointmentSegment.upcoming) {
      return appointments
          .where((item) => item.isUpcoming)
          .toList(growable: false);
    }
    return appointments.where((item) => item.isHistory).toList(growable: false);
  }

  AppointmentsState copyWith({
    ViewStatus? status,
    List<Appointment>? appointments,
    AppointmentSegment? segment,
    String? processingAppointmentId,
    String? message,
    bool clearProcessing = false,
    bool clearMessage = false,
  }) {
    return AppointmentsState(
      status: status ?? this.status,
      appointments: appointments ?? this.appointments,
      segment: segment ?? this.segment,
      processingAppointmentId: clearProcessing
          ? null
          : processingAppointmentId ?? this.processingAppointmentId,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    appointments,
    segment,
    processingAppointmentId,
    message,
  ];
}

class AppointmentsCubit extends Cubit<AppointmentsState> {
  AppointmentsCubit(this._appointmentRepository)
    : super(const AppointmentsState.initial());

  final AppointmentRepository _appointmentRepository;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, clearMessage: true));
    try {
      final appointments = await _appointmentRepository.getAppointments();
      emit(
        state.copyWith(
          status: appointments.isEmpty ? ViewStatus.empty : ViewStatus.success,
          appointments: appointments,
          clearMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ViewStatus.error,
          message: 'Не удалось загрузить записи.',
        ),
      );
    }
  }

  void changeSegment(AppointmentSegment segment) {
    emit(state.copyWith(segment: segment, clearMessage: true));
  }

  Future<void> cancelAppointment(String appointmentId) async {
    emit(
      state.copyWith(
        processingAppointmentId: appointmentId,
        clearMessage: true,
      ),
    );
    try {
      await _appointmentRepository.cancelAppointment(appointmentId);
      final appointments = await _appointmentRepository.getAppointments();
      emit(
        state.copyWith(
          status: appointments.isEmpty ? ViewStatus.empty : ViewStatus.success,
          appointments: appointments,
          clearProcessing: true,
          message: 'Запись отменена',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          clearProcessing: true,
          message: 'Не удалось отменить запись.',
        ),
      );
    }
  }

  void clearMessage() {
    emit(state.copyWith(clearMessage: true));
  }

  void reset() => emit(const AppointmentsState.initial());
}
