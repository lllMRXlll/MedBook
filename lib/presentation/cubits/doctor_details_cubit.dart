import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/enums/view_status.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/repositories/doctor_repository.dart';

class DoctorDetailsState extends Equatable {
  const DoctorDetailsState({required this.status, this.doctor, this.message});

  const DoctorDetailsState.initial() : this(status: ViewStatus.initial);

  final ViewStatus status;
  final Doctor? doctor;
  final String? message;

  DoctorDetailsState copyWith({
    ViewStatus? status,
    Doctor? doctor,
    String? message,
    bool clearMessage = false,
  }) {
    return DoctorDetailsState(
      status: status ?? this.status,
      doctor: doctor ?? this.doctor,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, doctor, message];
}

class DoctorDetailsCubit extends Cubit<DoctorDetailsState> {
  DoctorDetailsCubit(this._doctorRepository)
    : super(const DoctorDetailsState.initial());

  final DoctorRepository _doctorRepository;

  Future<void> load(String doctorId) async {
    emit(state.copyWith(status: ViewStatus.loading, clearMessage: true));
    try {
      final doctor = await _doctorRepository.getDoctorById(doctorId);
      emit(
        state.copyWith(
          status: ViewStatus.success,
          doctor: doctor,
          clearMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ViewStatus.error,
          message: 'Не удалось загрузить карточку врача.',
        ),
      );
    }
  }
}
