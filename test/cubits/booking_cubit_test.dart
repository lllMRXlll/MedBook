import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medbook_frontend/core/enums/view_status.dart';
import 'package:medbook_frontend/domain/entities/appointment.dart';
import 'package:medbook_frontend/domain/entities/doctor.dart';
import 'package:medbook_frontend/domain/entities/doctor_schedule.dart';
import 'package:medbook_frontend/domain/entities/specialization.dart';
import 'package:medbook_frontend/domain/entities/time_slot.dart';
import 'package:medbook_frontend/domain/repositories/appointment_repository.dart';
import 'package:medbook_frontend/domain/repositories/doctor_repository.dart';
import 'package:medbook_frontend/domain/requests/book_appointment_request.dart';
import 'package:medbook_frontend/presentation/cubits/booking_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockDoctorRepository extends Mock implements DoctorRepository {}

class MockAppointmentRepository extends Mock implements AppointmentRepository {}

void main() {
  late MockDoctorRepository doctorRepository;
  late MockAppointmentRepository appointmentRepository;

  final specialization = const Specialization(id: 'cardio', title: 'Кардиолог');
  final schedule = DoctorSchedule(
    workDays: [DateTime.now().weekday],
    startHour: 9,
    endHour: 18,
    slotMinutes: 30,
  );
  final doctor = Doctor(
    id: 'doctor-1',
    name: 'Илья Орлов',
    specialization: specialization,
    description: 'Кардиолог клиники',
    experienceYears: 12,
    rating: 4.8,
    price: 3500,
    location: 'Клиника MedBook',
    schedule: schedule,
    featured: true,
  );
  final selectedDate = DateTime.now();
  final slot = TimeSlot(
    startsAt: DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      10,
    ),
    isAvailable: true,
  );

  setUpAll(() {
    registerFallbackValue(
      BookAppointmentRequest(doctorId: doctor.id, scheduledAt: slot.startsAt),
    );
  });

  setUp(() {
    doctorRepository = MockDoctorRepository();
    appointmentRepository = MockAppointmentRepository();
  });

  blocTest<BookingCubit, BookingState>(
    'load fetches doctor and time slots',
    build: () {
      when(
        () => doctorRepository.getDoctorById(doctor.id),
      ).thenAnswer((_) async => doctor);
      when(
        () => doctorRepository.getAvailableSlots(
          doctor.id,
          any(),
          ignoreAppointmentId: any(named: 'ignoreAppointmentId'),
        ),
      ).thenAnswer((_) async => [slot]);

      return BookingCubit(
        doctorRepository: doctorRepository,
        appointmentRepository: appointmentRepository,
      );
    },
    act: (cubit) => cubit.load(doctor.id, preferredDate: selectedDate),
    expect: () => [
      isA<BookingState>().having(
        (state) => state.status,
        'status',
        equals(ViewStatus.loading),
      ),
      isA<BookingState>()
          .having((state) => state.doctor, 'doctor', equals(doctor))
          .having((state) => state.slots.length, 'slots', equals(1)),
    ],
  );

  blocTest<BookingCubit, BookingState>(
    'confirm creates appointment for selected slot',
    build: () {
      when(() => appointmentRepository.bookAppointment(any())).thenAnswer(
        (_) async => Appointment(
          id: 'appointment-1',
          doctorId: doctor.id,
          userId: 'user-1',
          doctorName: doctor.name,
          specializationName: doctor.specialization.title,
          scheduledAt: slot.startsAt,
          status: AppointmentStatus.scheduled,
          location: doctor.location,
          price: doctor.price,
        ),
      );

      return BookingCubit(
        doctorRepository: doctorRepository,
        appointmentRepository: appointmentRepository,
        initialDoctor: doctor,
        initialDate: selectedDate,
        initialSlot: slot,
      );
    },
    act: (cubit) => cubit.confirm(),
    expect: () => [
      isA<BookingState>().having(
        (state) => state.submissionStatus,
        'submissionStatus',
        equals(ViewStatus.submitting),
      ),
      isA<BookingState>().having(
        (state) => state.submissionStatus,
        'submissionStatus',
        equals(ViewStatus.success),
      ),
    ],
    verify: (_) {
      verify(
        () => appointmentRepository.bookAppointment(
          any(
            that: isA<BookAppointmentRequest>().having(
              (request) => request.doctorId,
              'doctorId',
              equals(doctor.id),
            ),
          ),
        ),
      ).called(1);
    },
  );
}
