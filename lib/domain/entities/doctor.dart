import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'doctor_schedule.dart';
import 'specialization.dart';

class Doctor extends Equatable {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.description,
    required this.experienceYears,
    required this.rating,
    required this.price,
    required this.location,
    required this.schedule,
    required this.featured,
  });

  final String id;
  final String name;
  final Specialization specialization;
  final String description;
  final int experienceYears;
  final double rating;
  final int price;
  final String location;
  final DoctorSchedule schedule;
  final bool featured;

  String get initials {
    final parts = name.split(' ').where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part.characters.first).join();
  }

  @override
  List<Object?> get props => [
    id,
    name,
    specialization,
    description,
    experienceYears,
    rating,
    price,
    location,
    schedule,
    featured,
  ];
}
