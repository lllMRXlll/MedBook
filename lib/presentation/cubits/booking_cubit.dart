import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/enums/view_status.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../../domain/requests/book_appointment_request.dart';
import '../../domain/requests/reschedule_appointment_request.dart';

class BookingState extends Equatable {
  const BookingState({
    required this.status,
    required this.submissionStatus,
    this.doctor,
    this.availableDates = const [],
    this.selectedDate,
    this.slots = const [],
    this.selectedSlot,
    this.existingAppointment,
    this.message,
  });

  factory BookingState.initial({
    Doctor? doctor,
    DateTime? selectedDate,
    TimeSlot? selectedSlot,
    Appointment? existingAppointment,
  }) {
    return BookingState(
      status: doctor == null ? ViewStatus.initial : ViewStatus.success,
      submissionStatus: ViewStatus.initial,
      doctor: doctor,
      selectedDate: selectedDate,
      selectedSlot: selectedSlot,
      existingAppointment: existingAppointment,
    );
  }

  final ViewStatus status;
  final ViewStatus submissionStatus;
  final Doctor? doctor;
  final List<DateTime> availableDates;
  final DateTime? selectedDate;
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final Appointment? existingAppointment;
  final String? message;

  bool get canContinue => selectedSlot != null;

  BookingState copyWith({
    ViewStatus? status,
    ViewStatus? submissionStatus,
    Doctor? doctor,
    List<DateTime>? availableDates,
    DateTime? selectedDate,
    List<TimeSlot>? slots,
    TimeSlot? selectedSlot,
    Appointment? existingAppointment,
    String? message,
    bool clearSelectedSlot = false,
    bool clearMessage = false,
  }) {
    return BookingState(
      status: status ?? this.status,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      doctor: doctor ?? this.doctor,
      availableDates: availableDates ?? this.availableDates,
      selectedDate: selectedDate ?? this.selectedDate,
      slots: slots ?? this.slots,
      selectedSlot: clearSelectedSlot
          ? null
          : selectedSlot ?? this.selectedSlot,
      existingAppointment: existingAppointment ?? this.existingAppointment,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    submissionStatus,
    doctor,
    availableDates,
    selectedDate,
    slots,
    selectedSlot,
    existingAppointment,
    message,
  ];
}

class BookingCubit extends Cubit<BookingState> {
  BookingCubit({
    required DoctorRepository doctorRepository,
    required AppointmentRepository appointmentRepository,
    Doctor? initialDoctor,
    DateTime? initialDate,
    TimeSlot? initialSlot,
    Appointment? existingAppointment,
  }) : _doctorRepository = doctorRepository,
       _appointmentRepository = appointmentRepository,
       super(
         BookingState.initial(
           doctor: initialDoctor,
           selectedDate: initialDate,
           selectedSlot: initialSlot,
           existingAppointment: existingAppointment,
         ),
       );

  final DoctorRepository _doctorRepository;
  final AppointmentRepository _appointmentRepository;

  Future<void> load(String doctorId, {DateTime? preferredDate}) async {
    emit(state.copyWith(status: ViewStatus.loading, clearMessage: true));
    try {
      final doctor =
          state.doctor ?? await _doctorRepository.getDoctorById(doctorId);
      final dates = _computeUpcomingDates(doctor);
      final requestedDate = preferredDate ?? state.selectedDate;
      final selectedDate = requestedDate != null
          ? _matchDate(requestedDate, dates) ?? dates.first
          : dates.first;
      final slots = await _doctorRepository.getAvailableSlots(
        doctor.id,
        selectedDate,
        ignoreAppointmentId: state.existingAppointment?.id,
      );
      TimeSlot? selectedSlot;
      if (state.selectedSlot != null) {
        for (final slot in slots) {
          if (slot.startsAt.isAtSameMomentAs(state.selectedSlot!.startsAt)) {
            selectedSlot = slot;
            break;
          }
        }
      }

      emit(
        state.copyWith(
          status: slots.isEmpty ? ViewStatus.empty : ViewStatus.success,
          doctor: doctor,
          availableDates: dates,
          selectedDate: selectedDate,
          slots: slots,
          selectedSlot: selectedSlot,
          clearMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ViewStatus.error,
          message: 'Не удалось загрузить доступное расписание.',
        ),
      );
    }
  }

  Future<void> selectDate(DateTime date) async {
    final doctor = state.doctor;
    if (doctor == null) {
      return;
    }

    emit(
      state.copyWith(
        status: ViewStatus.loading,
        selectedDate: date,
        clearSelectedSlot: true,
        clearMessage: true,
      ),
    );

    try {
      final slots = await _doctorRepository.getAvailableSlots(
        doctor.id,
        date,
        ignoreAppointmentId: state.existingAppointment?.id,
      );
      emit(
        state.copyWith(
          status: slots.isEmpty ? ViewStatus.empty : ViewStatus.success,
          slots: slots,
          clearSelectedSlot: true,
          clearMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ViewStatus.error,
          message: 'Не удалось обновить свободные слоты.',
        ),
      );
    }
  }

  void selectSlot(TimeSlot slot) {
    if (!slot.isAvailable) {
      return;
    }
    emit(state.copyWith(selectedSlot: slot, clearMessage: true));
  }

  Future<void> confirm() async {
    final doctor = state.doctor;
    final selectedSlot = state.selectedSlot;
    if (doctor == null || selectedSlot == null) {
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: ViewStatus.submitting,
        clearMessage: true,
      ),
    );

    try {
      if (state.existingAppointment == null) {
        await _appointmentRepository.bookAppointment(
          BookAppointmentRequest(
            doctorId: doctor.id,
            scheduledAt: selectedSlot.startsAt,
          ),
        );
      } else {
        await _appointmentRepository.rescheduleAppointment(
          state.existingAppointment!.id,
          RescheduleAppointmentRequest(scheduledAt: selectedSlot.startsAt),
        );
      }

      emit(
        state.copyWith(
          submissionStatus: ViewStatus.success,
          clearMessage: true,
        ),
      );
    } on StateError catch (error) {
      emit(
        state.copyWith(
          submissionStatus: ViewStatus.error,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          submissionStatus: ViewStatus.error,
          message: 'Не удалось сохранить запись.',
        ),
      );
    }
  }

  List<DateTime> _computeUpcomingDates(Doctor doctor) {
    final dates = <DateTime>[];
    var cursor = DateTime.now();

    while (dates.length < 14) {
      final normalized = DateTime(cursor.year, cursor.month, cursor.day);
      if (doctor.schedule.worksOn(normalized)) {
        dates.add(normalized);
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return dates;
  }

  DateTime? _matchDate(DateTime candidate, List<DateTime> dates) {
    for (final date in dates) {
      if (date.year == candidate.year &&
          date.month == candidate.month &&
          date.day == candidate.day) {
        return date;
      }
    }
    return null;
  }
}
