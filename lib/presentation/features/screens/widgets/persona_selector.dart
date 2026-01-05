import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/presentation/features/next_action/widgets/persona_card.dart';

class PersonaSelector extends StatelessWidget {
  const PersonaSelector({
    required this.currentPersona,
    required this.onPersonaSelected,
    super.key,
  });
  final AllocationPersona currentPersona;
  final void Function(AllocationPersona) onPersonaSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180, // Adjust height as needed
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: AllocationPersona.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final persona = AllocationPersona.values[index];
          return SizedBox(
            width: 160, // Fixed width for cards
            child: PersonaCard(
              persona: persona,
              isSelected: persona == currentPersona,
              onTap: () => onPersonaSelected(persona),
              isRecommended:
                  persona == AllocationPersona.realist, // Logic can be improved
            ),
          );
        },
      ),
    );
  }
}
