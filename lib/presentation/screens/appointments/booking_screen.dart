import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/view_status.dart';
import '../../../core/utils/date_formatter.dart';
import '../../cubits/booking_cubit.dart';
import '../../routing/app_router.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/state_placeholder.dart';
import '../../widgets/sections/section_header.dart';
import '../../widgets/sections/time_slot_tile.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key, required this.args});

  final BookingRouteArgs args;

  Future<void> _pickDate(BuildContext context, BookingState state) async {
    final doctor = state.doctor;
    if (doctor == null) {
      return;
    }

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('ru', 'RU'),
      initialDate: state.selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
      selectableDayPredicate: (date) {
        final normalized = DateTime(date.year, date.month, date.day);
        return doctor.schedule.worksOn(normalized);
      },
    );

    if (picked != null && context.mounted) {
      await context.read<BookingCubit>().selectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          args.existingAppointment == null
              ? 'Запись на прием'
              : 'Перенос записи',
        ),
      ),
      body: BlocConsumer<BookingCubit, BookingState>(
        listenWhen: (previous, current) =>
            previous.message != current.message && current.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        },
        builder: (context, state) {
          if (state.status == ViewStatus.loading && state.doctor == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ViewStatus.error || state.doctor == null) {
            return StatePlaceholder(
              icon: Icons.error_outline_rounded,
              title: 'Не удалось загрузить расписание',
              subtitle: state.message ?? 'Попробуйте открыть экран еще раз.',
              actionLabel: 'Повторить',
              onAction: () => context.read<BookingCubit>().load(
                args.doctorId,
                preferredDate: args.existingAppointment?.scheduledAt,
              ),
            );
          }

          final doctor = state.doctor!;
          final selectedDate = state.selectedDate;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(doctor.specialization.title),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: selectedDate == null
                            ? 'Выбрать дату'
                            : 'Дата: ${DateFormatter.fullDate(selectedDate)}',
                        onPressed: () => _pickDate(context, state),
                        secondary: true,
                        icon: Icons.calendar_today_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const SectionHeader(
                title: 'Ближайшие доступные даты',
                subtitle: 'Выберите день приема или откройте календарь.',
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: state.availableDates.map((date) {
                    final isSelected =
                        selectedDate != null &&
                        date.year == selectedDate.year &&
                        date.month == selectedDate.month &&
                        date.day == selectedDate.day;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(
                          '${DateFormatter.weekdayShort(date)}\n${DateFormatter.dayMonth(date)}',
                          textAlign: TextAlign.center,
                        ),
                        selected: isSelected,
                        onSelected: (_) =>
                            context.read<BookingCubit>().selectDate(date),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 22),
              SectionHeader(
                title: 'Время приема',
                subtitle: selectedDate == null
                    ? 'Сначала выберите дату.'
                    : 'Свободные и занятые окна на ${DateFormatter.fullDate(selectedDate)}.',
              ),
              const SizedBox(height: 14),
              if (state.status == ViewStatus.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.slots.isEmpty)
                const StatePlaceholder(
                  icon: Icons.schedule_outlined,
                  title: 'На этот день нет свободных окон',
                  subtitle: 'Попробуйте выбрать другую дату приема.',
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 520 ? 4 : 3;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.slots.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                      ),
                      itemBuilder: (context, index) {
                        final slot = state.slots[index];
                        return TimeSlotTile(
                          slot: slot,
                          isSelected: state.selectedSlot == slot,
                          onTap: () =>
                              context.read<BookingCubit>().selectSlot(slot),
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: args.existingAppointment == null
                    ? 'Продолжить'
                    : 'Перейти к подтверждению',
                onPressed: state.canContinue
                    ? () {
                        context.push(
                          '/app/appointments/confirm',
                          extra: BookingConfirmationArgs(
                            doctor: doctor,
                            selectedDate: state.selectedDate!,
                            selectedSlot: state.selectedSlot!,
                            existingAppointment: args.existingAppointment,
                          ),
                        );
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
