import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../domain/requests/book_appointment_request.dart';
import '../../domain/requests/reschedule_appointment_request.dart';
import '../services/mock_api_service.dart';
import '../services/session_manager.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl({
    required MockApiService apiService,
    required SessionManager sessionManager,
  }) : _apiService = apiService,
       _sessionManager = sessionManager;

  final MockApiService _apiService;
  final SessionManager _sessionManager;

  @override
  Future<Appointment> bookAppointment(BookAppointmentRequest request) async {
    final appointment = await _apiService.bookAppointment(
      request,
      _sessionManager.userIdOrThrow,
    );
    return appointment.toEntity();
  }

  @override
  Future<void> cancelAppointment(String appointmentId) {
    return _apiService.cancelAppointment(
      appointmentId,
      _sessionManager.userIdOrThrow,
    );
  }

  @override
  Future<List<Appointment>> getAppointments() async {
    final items = await _apiService.getAppointments(
      _sessionManager.userIdOrThrow,
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<Appointment> rescheduleAppointment(
    String appointmentId,
    RescheduleAppointmentRequest request,
  ) async {
    final appointment = await _apiService.rescheduleAppointment(
      appointmentId,
      request,
      _sessionManager.userIdOrThrow,
    );
    return appointment.toEntity();
  }
}
