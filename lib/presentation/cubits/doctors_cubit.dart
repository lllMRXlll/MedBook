import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/enums/view_status.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/specialization.dart';
import '../../domain/repositories/doctor_repository.dart';

class DoctorsState extends Equatable {
  const DoctorsState({
    required this.status,
    this.doctors = const [],
    this.specializations = const [],
    this.selectedSpecializationId,
    this.query = '',
    this.message,
  });

  const DoctorsState.initial() : this(status: ViewStatus.initial);

  final ViewStatus status;
  final List<Doctor> doctors;
  final List<Specialization> specializations;
  final String? selectedSpecializationId;
  final String query;
  final String? message;

  DoctorsState copyWith({
    ViewStatus? status,
    List<Doctor>? doctors,
    List<Specialization>? specializations,
    String? selectedSpecializationId,
    String? query,
    String? message,
    bool clearSelectedSpecialization = false,
    bool clearMessage = false,
  }) {
    return DoctorsState(
      status: status ?? this.status,
      doctors: doctors ?? this.doctors,
      specializations: specializations ?? this.specializations,
      selectedSpecializationId: clearSelectedSpecialization
          ? null
          : selectedSpecializationId ?? this.selectedSpecializationId,
      query: query ?? this.query,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    doctors,
    specializations,
    selectedSpecializationId,
    query,
    message,
  ];
}

class DoctorsCubit extends Cubit<DoctorsState> {
  DoctorsCubit(this._doctorRepository) : super(const DoctorsState.initial());

  final DoctorRepository _doctorRepository;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, clearMessage: true));
    try {
      final specializations = await _doctorRepository.getSpecializations();
      final doctors = await _doctorRepository.getDoctors(
        specializationId: state.selectedSpecializationId,
        query: state.query,
      );
      emit(
        state.copyWith(
          status: doctors.isEmpty ? ViewStatus.empty : ViewStatus.success,
          doctors: doctors,
          specializations: specializations,
          clearMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ViewStatus.error,
          message: 'Не удалось загрузить список врачей.',
        ),
      );
    }
  }

  Future<void> setSpecialization(String? specializationId) async {
    emit(
      state.copyWith(
        selectedSpecializationId: specializationId,
        clearSelectedSpecialization: specializationId == null,
      ),
    );
    await load();
  }

  Future<void> setQuery(String query) async {
    emit(state.copyWith(query: query));
    await load();
  }
}
