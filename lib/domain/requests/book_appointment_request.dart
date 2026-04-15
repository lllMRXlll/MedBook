class BookAppointmentRequest {
  const BookAppointmentRequest({
    required this.doctorId,
    required this.scheduledAt,
  });

  final String doctorId;
  final DateTime scheduledAt;
}
