import 'package:flutter/material.dart';

import '../../../domain/entities/specialization.dart';

class SpecializationFilterChips extends StatelessWidget {
  const SpecializationFilterChips({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Specialization> items;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Все'),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(item.title),
                selected: selectedId == item.id,
                onSelected: (_) => onSelected(item.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
