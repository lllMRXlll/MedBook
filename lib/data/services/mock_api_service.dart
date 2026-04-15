import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/requests/book_appointment_request.dart';
import '../../domain/requests/login_request.dart';
import '../../domain/requests/register_request.dart';
import '../../domain/requests/reschedule_appointment_request.dart';
import '../../domain/requests/update_profile_request.dart';
import '../dtos/appointment_dto.dart';
import '../dtos/auth_session_dto.dart';
import '../dtos/doctor_dto.dart';
import '../dtos/specialization_dto.dart';
import '../dtos/time_slot_dto.dart';
import '../dtos/user_dto.dart';
import 'api_client.dart';

class MockApiService {
  MockApiService({
    required AssetBundle assetBundle,
    required ApiClient apiClient,
  }) : _assetBundle = assetBundle,
       _apiClient = apiClient;

  final AssetBundle _assetBundle;
  final ApiClient _apiClient;

  bool _initialized = false;
  late List<UserDto> _users;
  late List<SpecializationDto> _specializations;
  late List<DoctorDto> _doctors;
  late List<AppointmentDto> _appointments;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _apiClient;

    _users =
        (jsonDecode(await _assetBundle.loadString('assets/mock/users.json'))
                as List<dynamic>)
            .map((item) => UserDto.fromJson(item as Map<String, dynamic>))
            .toList();

    _specializations =
        (jsonDecode(
                  await _assetBundle.loadString(
                    'assets/mock/specializations.json',
                  ),
                )
                as List<dynamic>)
            .map(
              (item) =>
                  SpecializationDto.fromJson(item as Map<String, dynamic>),
            )
            .toList();

    _doctors =
        (jsonDecode(await _assetBundle.loadString('assets/mock/doctors.json'))
                as List<dynamic>)
            .map((item) => DoctorDto.fromJson(item as Map<String, dynamic>))
            .toList();

    _appointments =
        (jsonDecode(
                  await _assetBundle.loadString(
                    'assets/mock/appointments.json',
                  ),
                )
                as List<dynamic>)
            .map(
              (item) => AppointmentDto.fromJson(item as Map<String, dynamic>),
            )
            .toList();

    _initialized = true;
  }

  Future<AuthSessionDto> login(LoginRequest request) async {
    await initialize();
    await _delay();

    final lookup = request.identifier.trim().toLowerCase();
    final user = _users.where((candidate) {
      return candidate.email.toLowerCase() == lookup ||
          candidate.phone == lookup;
    }).firstOrNull;

    if (user == null || user.password != request.password) {
      throw StateError('Неверный логин или пароль.');
    }

    return AuthSessionDto(
      token: 'token-${user.id}-${DateTime.now().millisecondsSinceEpoch}',
      user: user,
    );
  }

  Future<AuthSessionDto> register(RegisterRequest request) async {
    await initialize();
    await _delay();

    final emailTaken = _users.any(
      (user) => user.email.toLowerCase() == request.email.trim().toLowerCase(),
    );
    final phoneTaken = _users.any((user) => user.phone == request.phone.trim());

    if (emailTaken || phoneTaken) {
      throw StateError('Пользователь с такими данными уже существует.');
    }

    final user = UserDto(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: request.fullName.trim(),
      email: request.email.trim(),
      phone: request.phone.trim(),
      password: request.password,
      city: 'Москва',
    );

    _users = [..._users, user];

    return AuthSessionDto(
      token: 'token-${user.id}-${DateTime.now().millisecondsSinceEpoch}',
      user: user,
    );
  }

  Future<List<SpecializationDto>> getSpecializations() async {
    await initialize();
    await _delay();
    return List.unmodifiable(_specializations);
  }

  Future<List<DoctorDto>> getDoctors({
    String? specializationId,
    String? query,
  }) async {
    await initialize();
    await _delay();

    final normalizedQuery = query?.trim().toLowerCase();
    return _doctors
        .where((doctor) {
          final matchesSpecialization =
              specializationId == null ||
              specializationId.isEmpty ||
              doctor.specializationId == specializationId;
          final matchesQuery =
              normalizedQuery == null ||
              normalizedQuery.isEmpty ||
              doctor.name.toLowerCase().contains(normalizedQuery);
          return matchesSpecialization && matchesQuery;
        })
        .toList(growable: false);
  }

  Future<DoctorDto> getDoctorById(String id) async {
    await initialize();
    await _delay();
    return _doctors.firstWhere((doctor) => doctor.id == id);
  }

  Future<List<TimeSlotDto>> getAvailableSlots(
    String doctorId,
    DateTime date, {
    String? ignoreAppointmentId,
  }) async {
    await initialize();
    await _delay();

    final doctor = _doctors.firstWhere((item) => item.id == doctorId);
    final schedule = doctor.schedule;
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (!schedule.workDays.contains(normalizedDate.weekday)) {
      return const [];
    }

    final bookedSlots = _appointments
        .where((appointment) {
          return appointment.doctorId == doctorId &&
              appointment.status != AppointmentStatus.cancelled &&
              appointment.id != ignoreAppointmentId &&
              appointment.scheduledAt.year == normalizedDate.year &&
              appointment.scheduledAt.month == normalizedDate.month &&
              appointment.scheduledAt.day == normalizedDate.day;
        })
        .map((appointment) => appointment.scheduledAt.toIso8601String())
        .toSet();

    final slots = <TimeSlotDto>[];
    final now = DateTime.now();
    var current = DateTime(
      normalizedDate.year,
      normalizedDate.month,
      normalizedDate.day,
      schedule.startHour,
    );
    final finish = DateTime(
      normalizedDate.year,
      normalizedDate.month,
      normalizedDate.day,
      schedule.endHour,
    );

    while (current.isBefore(finish)) {
      final isAvailable =
          !bookedSlots.contains(current.toIso8601String()) &&
          current.isAfter(now);
      slots.add(TimeSlotDto(startsAt: current, isAvailable: isAvailable));
      current = current.add(Duration(minutes: schedule.slotMinutes));
    }

    return slots;
  }

  Future<List<AppointmentDto>> getAppointments(String userId) async {
    await initialize();
    await _delay();

    final results =
        _appointments
            .where((appointment) => appointment.userId == userId)
            .toList()
          ..sort(
            (left, right) => left.scheduledAt.compareTo(right.scheduledAt),
          );
    return results;
  }

  Future<AppointmentDto> bookAppointment(
    BookAppointmentRequest request,
    String userId,
  ) async {
    await initialize();
    await _delay();

    final slots = await getAvailableSlots(
      request.doctorId,
      request.scheduledAt,
    );
    final matchingSlot = slots.where((slot) {
      return slot.startsAt.isAtSameMomentAs(request.scheduledAt);
    }).firstOrNull;

    if (matchingSlot == null || !matchingSlot.isAvailable) {
      throw StateError('Выбранное время уже занято.');
    }

    final doctor = _doctors.firstWhere((item) => item.id == request.doctorId);
    final specialization = _specializations.firstWhere(
      (item) => item.id == doctor.specializationId,
    );

    final appointment = AppointmentDto(
      id: 'appointment-${DateTime.now().millisecondsSinceEpoch}',
      doctorId: doctor.id,
      userId: userId,
      doctorName: doctor.name,
      specializationName: specialization.title,
      scheduledAt: request.scheduledAt,
      status: AppointmentStatus.scheduled,
      location: doctor.location,
      price: doctor.price,
    );

    _appointments = [..._appointments, appointment];
    return appointment;
  }

  Future<void> cancelAppointment(String appointmentId, String userId) async {
    await initialize();
    await _delay();

    _appointments = _appointments
        .map((appointment) {
          if (appointment.id == appointmentId && appointment.userId == userId) {
            return appointment.copyWith(status: AppointmentStatus.cancelled);
          }
          return appointment;
        })
        .toList(growable: false);
  }

  Future<AppointmentDto> rescheduleAppointment(
    String appointmentId,
    RescheduleAppointmentRequest request,
    String userId,
  ) async {
    await initialize();
    await _delay();

    final existing = _appointments.firstWhere(
      (appointment) =>
          appointment.id == appointmentId && appointment.userId == userId,
    );

    final slots = await getAvailableSlots(
      existing.doctorId,
      request.scheduledAt,
      ignoreAppointmentId: appointmentId,
    );
    final matchingSlot = slots.where((slot) {
      return slot.startsAt.isAtSameMomentAs(request.scheduledAt);
    }).firstOrNull;

    if (matchingSlot == null || !matchingSlot.isAvailable) {
      throw StateError('Выбранное время уже занято.');
    }

    late final AppointmentDto updated;
    _appointments = _appointments
        .map((appointment) {
          if (appointment.id == appointmentId) {
            updated = appointment.copyWith(
              scheduledAt: request.scheduledAt,
              status: AppointmentStatus.scheduled,
            );
            return updated;
          }
          return appointment;
        })
        .toList(growable: false);

    return updated;
  }

  Future<UserDto> getProfile(String userId) async {
    await initialize();
    await _delay();
    return _users.firstWhere((user) => user.id == userId);
  }

  Future<UserDto> updateProfile(
    String userId,
    UpdateProfileRequest request,
  ) async {
    await initialize();
    await _delay();

    late final UserDto updated;
    _users = _users
        .map((user) {
          if (user.id == userId) {
            updated = user.copyWith(
              fullName: request.fullName.trim(),
              email: request.email.trim(),
              phone: request.phone.trim(),
              birthDate: request.birthDate,
              city: request.city?.trim(),
            );
            return updated;
          }
          return user;
        })
        .toList(growable: false);

    return updated;
  }

  Future<void> _delay() async {
    final jitter = 280 + Random().nextInt(180);
    await Future<void>.delayed(Duration(milliseconds: jitter));
  }
}
