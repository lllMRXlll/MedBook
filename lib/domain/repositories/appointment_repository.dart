import '../entities/appointment.dart';
import '../requests/book_appointment_request.dart';
import '../requests/reschedule_appointment_request.dart';

abstract interface class AppointmentRepository {
  Future<List<Appointment>> getAppointments();
  Future<Appointment> bookAppointment(BookAppointmentRequest request);
  Future<void> cancelAppointment(String appointmentId);
  Future<Appointment> rescheduleAppointment(
    String appointmentId,
    RescheduleAppointmentRequest request,
  );
}
