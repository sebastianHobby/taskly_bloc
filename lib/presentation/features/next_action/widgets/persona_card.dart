import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/theme/app_colors.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

class PersonaCard extends StatelessWidget {
  const PersonaCard({
    required this.persona,
    required this.isSelected,
    required this.onTap,
    super.key,
    this.isRecommended = false,
  });
  final AllocationPersona persona;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unselectedColor = colorScheme.onSurface;

    return TasklyCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      backgroundColor: isSelected ? colorScheme.primary.withOpacity(0.1) : null,
      borderColor: isSelected ? colorScheme.primary : null,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconForPersona(persona),
                      color: isSelected ? colorScheme.primary : unselectedColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        persona.name.toUpperCase(), // Or use l10n
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colorScheme.primary
                              : unselectedColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getDescriptionForPersona(persona),
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isRecommended)
            Positioned(
              top: 8,
              right: 8,
              child: TasklyBadge(
                label: 'RECOMMENDED',
                color: colorScheme.tertiary,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForPersona(AllocationPersona persona) {
    return switch (persona) {
      AllocationPersona.firefighter => Icons.local_fire_department,
      AllocationPersona.realist => Icons.balance,
      AllocationPersona.idealist => Icons.lightbulb_outline,
      AllocationPersona.reflector => Icons.history,
      AllocationPersona.custom => Icons.tune,
    };
  }

  String _getDescriptionForPersona(AllocationPersona persona) {
    // Ideally use l10n here
    return switch (persona) {
      AllocationPersona.firefighter => "Show me what's urgent right now.",
      AllocationPersona.realist =>
        'Show me what matters most, but warn me about urgent tasks.',
      AllocationPersona.idealist =>
        "Show me what matters most, not what's most urgent.",
      AllocationPersona.reflector => "Show me values I've been neglecting.",
      AllocationPersona.custom => 'Let me decide what you show me.',
    };
  }
}
