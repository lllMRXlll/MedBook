import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/view_status.dart';
import '../../cubits/doctor_details_cubit.dart';
import '../../routing/app_router.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/state_placeholder.dart';

class DoctorDetailsScreen extends StatelessWidget {
  const DoctorDetailsScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Карточка врача')),
      body: BlocBuilder<DoctorDetailsCubit, DoctorDetailsState>(
        builder: (context, state) {
          if (state.status == ViewStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ViewStatus.error || state.doctor == null) {
            return StatePlaceholder(
              icon: Icons.error_outline_rounded,
              title: 'Не удалось открыть карточку врача',
              subtitle: state.message ?? 'Попробуйте повторить позже.',
              actionLabel: 'Повторить',
              onAction: () => context.read<DoctorDetailsCubit>().load(doctorId),
            );
          }

          final doctor = state.doctor!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            child: Text(doctor.initials),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  doctor.specialization.title,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        doctor.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _DetailChip(
                            label: '${doctor.experienceYears} лет стажа',
                          ),
                          _DetailChip(
                            label:
                                'Рейтинг ${doctor.rating.toStringAsFixed(1)}',
                          ),
                          _DetailChip(label: 'Прием от ${doctor.price} ₽'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'График приема',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Рабочие дни: ${doctor.schedule.workDays.join(', ')}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Часы приема: ${doctor.schedule.startHour}:00 - ${doctor.schedule.endHour}:00',
                      ),
                      const SizedBox(height: 8),
                      Text('Адрес: ${doctor.location}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Выбрать время приема',
                icon: Icons.calendar_month_rounded,
                onPressed: () => context.push(
                  '/app/appointments/book',
                  extra: BookingRouteArgs(doctorId: doctor.id),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label),
    );
  }
}
