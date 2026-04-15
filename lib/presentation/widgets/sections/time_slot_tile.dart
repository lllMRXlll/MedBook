import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/time_slot.dart';

class TimeSlotTile extends StatelessWidget {
  const TimeSlotTile({
    super.key,
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = !slot.isAvailable
        ? colorScheme.surfaceContainerHighest
        : isSelected
        ? colorScheme.primary
        : Colors.white;
    final foregroundColor = !slot.isAvailable
        ? colorScheme.onSurfaceVariant
        : isSelected
        ? Colors.white
        : colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: slot.isAvailable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormatter.time(slot.startsAt),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: foregroundColor),
            ),
            const SizedBox(height: 4),
            Text(
              slot.isAvailable ? 'Свободно' : 'Занято',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: foregroundColor),
            ),
          ],
        ),
      ),
    );
  }
}
