import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/view_status.dart';
import '../../cubits/dashboard_cubit.dart';
import '../../routing/app_router.dart';
import '../../widgets/common/state_placeholder.dart';
import '../../widgets/sections/appointment_card.dart';
import '../../widgets/sections/doctor_card.dart';
import '../../widgets/sections/section_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<DashboardCubit>();
      if (cubit.state.status == ViewStatus.initial) {
        cubit.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.status == ViewStatus.loading && state.user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ViewStatus.error && state.user == null) {
          return StatePlaceholder(
            icon: Icons.error_outline_rounded,
            title: 'Не удалось загрузить данные',
            subtitle: state.message ?? 'Попробуйте обновить экран.',
            actionLabel: 'Повторить',
            onAction: () => context.read<DashboardCubit>().load(),
          );
        }

        final user = state.user;
        if (user == null) {
          return const SizedBox.shrink();
        }

        return RefreshIndicator(
          onRefresh: () => context.read<DashboardCubit>().load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            children: [
              Text(
                'Здравствуйте, ${user.fullName.split(' ').first}',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Проверьте ближайший прием, найдите подходящего специалиста и управляйте записями без звонков в регистратуру.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(
                    title: 'Предстоящих приемов',
                    value: '${state.upcomingCount}',
                  ),
                  _MetricCard(
                    title: 'История посещений',
                    value: '${state.historyCount}',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SectionHeader(
                title: 'Ближайший прием',
                subtitle: 'Актуальная запись, которую можно быстро перенести.',
              ),
              const SizedBox(height: 14),
              if (state.nextAppointment != null)
                AppointmentCard(
                  appointment: state.nextAppointment!,
                  onReschedule: () => context.push(
                    '/app/appointments/book',
                    extra: BookingRouteArgs(
                      doctorId: state.nextAppointment!.doctorId,
                      existingAppointment: state.nextAppointment,
                    ),
                  ),
                  onCancel: () => context.go('/app/appointments'),
                )
              else
                const StatePlaceholder(
                  icon: Icons.calendar_today_outlined,
                  title: 'Нет запланированных приемов',
                  subtitle:
                      'Выберите специалиста и создайте первую запись прямо из приложения.',
                ),
              const SizedBox(height: 28),
              SectionHeader(
                title: 'Быстрые действия',
                subtitle: 'Основные разделы под рукой.',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ActionCard(
                    title: 'Подобрать врача',
                    icon: Icons.medical_services_outlined,
                    onTap: () => context.go('/app/doctors'),
                  ),
                  _ActionCard(
                    title: 'Мои приемы',
                    icon: Icons.event_note_outlined,
                    onTap: () => context.go('/app/appointments'),
                  ),
                  _ActionCard(
                    title: 'Профиль пациента',
                    icon: Icons.person_outline_rounded,
                    onTap: () => context.go('/app/profile'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SectionHeader(
                title: 'Рекомендуемые специалисты',
                subtitle: 'Популярные врачи с ближайшими окнами записи.',
              ),
              const SizedBox(height: 14),
              ...state.featuredDoctors.map(
                (doctor) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DoctorCard(
                    doctor: doctor,
                    compact: true,
                    onTap: () => context.push('/app/doctors/${doctor.id}'),
                    onBook: () => context.push(
                      '/app/appointments/book',
                      extra: BookingRouteArgs(doctorId: doctor.id),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const SizedBox(height: 18),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
