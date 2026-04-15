import '../../domain/entities/doctor.dart';
import '../../domain/entities/specialization.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../services/mock_api_service.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  DoctorRepositoryImpl(this._apiService);

  final MockApiService _apiService;

  @override
  Future<List<Doctor>> getDoctors({
    String? specializationId,
    String? query,
  }) async {
    final specializations = await _apiService.getSpecializations();
    final items = await _apiService.getDoctors(
      specializationId: specializationId,
      query: query,
    );
    final byId = {for (final item in specializations) item.id: item.toEntity()};
    return items
        .map((doctor) => doctor.toEntity(byId[doctor.specializationId]!))
        .toList(growable: false);
  }

  @override
  Future<Doctor> getDoctorById(String id) async {
    final specializations = await _apiService.getSpecializations();
    final doctor = await _apiService.getDoctorById(id);
    final specialization = specializations.firstWhere(
      (item) => item.id == doctor.specializationId,
    );
    return doctor.toEntity(specialization.toEntity());
  }

  @override
  Future<List<Specialization>> getSpecializations() async {
    final items = await _apiService.getSpecializations();
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<TimeSlot>> getAvailableSlots(
    String doctorId,
    DateTime date, {
    String? ignoreAppointmentId,
  }) async {
    final items = await _apiService.getAvailableSlots(
      doctorId,
      date,
      ignoreAppointmentId: ignoreAppointmentId,
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }
}
