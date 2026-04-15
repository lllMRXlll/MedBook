import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/view_status.dart';
import '../../cubits/appointments_cubit.dart';
import '../../cubits/dashboard_cubit.dart';
import '../../routing/app_router.dart';
import '../../widgets/common/state_placeholder.dart';
import '../../widgets/sections/appointment_card.dart';
import '../../widgets/sections/section_header.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<AppointmentsCubit>();
      if (cubit.state.status == ViewStatus.initial) {
        cubit.load();
      }
    });
  }

  Future<void> _confirmCancel(
    BuildContext context,
    String appointmentId,
  ) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Отменить запись?'),
          content: const Text(
            'Освободившееся окно снова станет доступным для записи.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Нет'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Да, отменить'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true && context.mounted) {
      await context.read<AppointmentsCubit>().cancelAppointment(appointmentId);
      if (context.mounted) {
        await context.read<DashboardCubit>().load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppointmentsCubit, AppointmentsState>(
      listenWhen: (previous, current) =>
          previous.message != current.message && current.message != null,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.message!)));
        context.read<AppointmentsCubit>().clearMessage();
      },
      builder: (context, state) {
        final cubit = context.read<AppointmentsCubit>();

        return RefreshIndicator(
          onRefresh: cubit.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            children: [
              const SectionHeader(
                title: 'Мои приемы',
                subtitle:
                    'Управляйте подтвержденными визитами, переносите время и отслеживайте историю.',
              ),
              const SizedBox(height: 16),
              SegmentedButton<AppointmentSegment>(
                segments: const [
                  ButtonSegment(
                    value: AppointmentSegment.upcoming,
                    label: Text('Предстоящие'),
                  ),
                  ButtonSegment(
                    value: AppointmentSegment.history,
                    label: Text('История'),
                  ),
                ],
                selected: {state.segment},
                onSelectionChanged: (selection) {
                  cubit.changeSegment(selection.first);
                },
              ),
              const SizedBox(height: 20),
              if (state.status == ViewStatus.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.status == ViewStatus.error)
                StatePlaceholder(
                  icon: Icons.error_outline_rounded,
                  title: 'Не удалось загрузить приемы',
                  subtitle: state.message ?? 'Попробуйте обновить экран.',
                  actionLabel: 'Повторить',
                  onAction: cubit.load,
                )
              else if (state.visibleAppointments.isEmpty)
                StatePlaceholder(
                  icon: Icons.event_busy_outlined,
                  title: state.segment == AppointmentSegment.upcoming
                      ? 'Нет предстоящих приемов'
                      : 'История пока пуста',
                  subtitle: state.segment == AppointmentSegment.upcoming
                      ? 'Откройте список врачей и выберите удобное время.'
                      : 'После завершенных или отмененных визитов они появятся здесь.',
                  actionLabel: state.segment == AppointmentSegment.upcoming
                      ? 'Выбрать врача'
                      : null,
                  onAction: state.segment == AppointmentSegment.upcoming
                      ? () => context.go('/app/doctors')
                      : null,
                )
              else
                ...state.visibleAppointments.map(
                  (appointment) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppointmentCard(
                      appointment: appointment,
                      isProcessing:
                          state.processingAppointmentId == appointment.id,
                      onCancel: appointment.isUpcoming
                          ? () => _confirmCancel(context, appointment.id)
                          : null,
                      onReschedule: appointment.isUpcoming
                          ? () => context.push(
                              '/app/appointments/book',
                              extra: BookingRouteArgs(
                                doctorId: appointment.doctorId,
                                existingAppointment: appointment,
                              ),
                            )
                          : null,
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
