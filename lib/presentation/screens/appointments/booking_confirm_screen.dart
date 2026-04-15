import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/view_status.dart';
import '../../../core/utils/date_formatter.dart';
import '../../cubits/appointments_cubit.dart';
import '../../cubits/booking_cubit.dart';
import '../../cubits/dashboard_cubit.dart';
import '../../routing/app_router.dart';
import '../../widgets/common/primary_button.dart';

class BookingConfirmScreen extends StatelessWidget {
  const BookingConfirmScreen({super.key, required this.args});

  final BookingConfirmationArgs args;

  @override
  Widget build(BuildContext context) {
    final isReschedule = args.existingAppointment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isReschedule ? 'Подтвердите перенос' : 'Подтвердите запись',
        ),
      ),
      body: BlocConsumer<BookingCubit, BookingState>(
        listenWhen: (previous, current) =>
            previous.submissionStatus != current.submissionStatus ||
            previous.message != current.message,
        listener: (context, state) async {
          if (state.submissionStatus == ViewStatus.success) {
            final appointmentsCubit = context.read<AppointmentsCubit>();
            final dashboardCubit = context.read<DashboardCubit>();
            await appointmentsCubit.load();
            await dashboardCubit.load();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isReschedule ? 'Запись перенесена' : 'Запись подтверждена',
                ),
              ),
            );
            context.go('/app/appointments');
          }

          if (state.submissionStatus == ViewStatus.error &&
              state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        args.doctor.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(args.doctor.specialization.title),
                      const SizedBox(height: 20),
                      _RowItem(
                        icon: Icons.schedule_rounded,
                        label: DateFormatter.appointment(
                          args.selectedSlot.startsAt,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _RowItem(
                        icon: Icons.location_on_outlined,
                        label: args.doctor.location,
                      ),
                      const SizedBox(height: 12),
                      _RowItem(
                        icon: Icons.payments_outlined,
                        label: DateFormatter.currency(args.doctor.price),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    isReschedule
                        ? 'Старое время приема будет заменено новым сразу после подтверждения.'
                        : 'После подтверждения запись появится в разделе "Приемы".',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: isReschedule
                    ? 'Подтвердить перенос'
                    : 'Подтвердить запись',
                onPressed: () => context.read<BookingCubit>().confirm(),
                isLoading: state.submissionStatus == ViewStatus.submitting,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Назад',
                onPressed: () => context.pop(),
                secondary: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    );
  }
}
