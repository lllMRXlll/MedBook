import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/appointment.dart';
import '../common/primary_button.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onCancel,
    this.onReschedule,
    this.isProcessing = false,
  });

  final Appointment appointment;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCancelled = appointment.status == AppointmentStatus.cancelled;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.specializationName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? colorScheme.errorContainer
                        : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    isCancelled ? 'Отменена' : 'Подтверждена',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: DateFormatter.appointment(appointment.scheduledAt),
            ),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.place_outlined, label: appointment.location),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: DateFormatter.currency(appointment.price),
            ),
            if (!isCancelled && appointment.isUpcoming) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Перенести',
                      onPressed: onReschedule,
                      secondary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Отменить',
                      onPressed: onCancel,
                      isLoading: isProcessing,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
