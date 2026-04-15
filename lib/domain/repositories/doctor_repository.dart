import '../entities/doctor.dart';
import '../entities/specialization.dart';
import '../entities/time_slot.dart';

abstract interface class DoctorRepository {
  Future<List<Doctor>> getDoctors({String? specializationId, String? query});

  Future<List<Specialization>> getSpecializations();
  Future<Doctor> getDoctorById(String id);
  Future<List<TimeSlot>> getAvailableSlots(
    String doctorId,
    DateTime date, {
    String? ignoreAppointmentId,
  });
}
