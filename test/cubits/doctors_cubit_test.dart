import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medbook_frontend/core/enums/view_status.dart';
import 'package:medbook_frontend/domain/entities/doctor.dart';
import 'package:medbook_frontend/domain/entities/doctor_schedule.dart';
import 'package:medbook_frontend/domain/entities/specialization.dart';
import 'package:medbook_frontend/domain/repositories/doctor_repository.dart';
import 'package:medbook_frontend/presentation/cubits/doctors_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockDoctorRepository extends Mock implements DoctorRepository {}

void main() {
  late MockDoctorRepository doctorRepository;

  const therapy = Specialization(id: 'therapy', title: 'Терапевт');
  const cardio = Specialization(id: 'cardio', title: 'Кардиолог');
  const schedule = DoctorSchedule(
    workDays: [1, 2, 3, 4, 5],
    startHour: 9,
    endHour: 18,
    slotMinutes: 30,
  );
  const doctors = [
    Doctor(
      id: 'doctor-1',
      name: 'Мария Кузнецова',
      specialization: therapy,
      description: 'Терапевт',
      experienceYears: 10,
      rating: 4.9,
      price: 2800,
      location: 'Клиника',
      schedule: schedule,
      featured: true,
    ),
    Doctor(
      id: 'doctor-2',
      name: 'Илья Орлов',
      specialization: cardio,
      description: 'Кардиолог',
      experienceYears: 12,
      rating: 4.8,
      price: 3500,
      location: 'Клиника',
      schedule: schedule,
      featured: true,
    ),
  ];

  setUp(() {
    doctorRepository = MockDoctorRepository();
    when(
      () => doctorRepository.getSpecializations(),
    ).thenAnswer((_) async => [therapy, cardio]);
    when(
      () => doctorRepository.getDoctors(
        specializationId: any(named: 'specializationId'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((invocation) async {
      final specializationId =
          invocation.namedArguments[#specializationId] as String?;
      final query = invocation.namedArguments[#query] as String? ?? '';
      return doctors.where((doctor) {
        final matchesSpecialization =
            specializationId == null ||
            doctor.specialization.id == specializationId;
        final matchesQuery =
            query.isEmpty || doctor.name.toLowerCase().contains(query);
        return matchesSpecialization && matchesQuery;
      }).toList();
    });
  });

  blocTest<DoctorsCubit, DoctorsState>(
    'load returns doctors and specializations',
    build: () => DoctorsCubit(doctorRepository),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<DoctorsState>().having(
        (state) => state.status,
        'status',
        equals(ViewStatus.loading),
      ),
      isA<DoctorsState>()
          .having((state) => state.status, 'status', equals(ViewStatus.success))
          .having((state) => state.doctors.length, 'length', equals(2)),
    ],
  );

  blocTest<DoctorsCubit, DoctorsState>(
    'setSpecialization filters doctor list',
    build: () => DoctorsCubit(doctorRepository),
    seed: () => const DoctorsState(
      status: ViewStatus.success,
      specializations: [therapy, cardio],
      doctors: doctors,
    ),
    act: (cubit) => cubit.setSpecialization('cardio'),
    expect: () => [
      isA<DoctorsState>().having(
        (state) => state.selectedSpecializationId,
        'selectedSpecializationId',
        equals('cardio'),
      ),
      isA<DoctorsState>().having(
        (state) => state.status,
        'status',
        equals(ViewStatus.loading),
      ),
      isA<DoctorsState>().having(
        (state) => state.doctors.single.specialization.id,
        'filtered specialization',
        equals('cardio'),
      ),
    ],
  );
}
