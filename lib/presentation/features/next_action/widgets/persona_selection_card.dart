import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';

/// A selectable card representing an allocation persona.
///
/// Displays:
/// - Persona name and icon
/// - Short description
/// - Optional "Recommended" badge
/// - Expandable "How it works" section
class PersonaSelectionCard extends StatelessWidget {
  const PersonaSelectionCard({
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
    final l10n = context.l10n;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _iconForPersona(persona),
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _nameForPersona(l10n, persona),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isRecommended)
                    Chip(
                      label: Text(
                        l10n.personaRecommended,
                        style: theme.textTheme.labelSmall,
                      ),
                      backgroundColor: colorScheme.primaryContainer,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.check_circle,
                        color: colorScheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _descriptionForPersona(l10n, persona),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _HowItWorksExpansion(persona: persona),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForPersona(AllocationPersona persona) {
    return switch (persona) {
      AllocationPersona.idealist => Icons.star_outline,
      AllocationPersona.reflector => Icons.history,
      AllocationPersona.realist => Icons.balance,
      AllocationPersona.firefighter => Icons.local_fire_department,
      AllocationPersona.custom => Icons.tune,
    };
  }

  String _nameForPersona(AppLocalizations l10n, AllocationPersona persona) {
    return switch (persona) {
      AllocationPersona.idealist => l10n.personaIdealist,
      AllocationPersona.reflector => l10n.personaReflector,
      AllocationPersona.realist => l10n.personaRealist,
      AllocationPersona.firefighter => l10n.personaFirefighter,
      AllocationPersona.custom => l10n.personaCustom,
    };
  }

  String _descriptionForPersona(
    AppLocalizations l10n,
    AllocationPersona persona,
  ) {
    return switch (persona) {
      AllocationPersona.idealist => l10n.personaIdealistDescription,
      AllocationPersona.reflector => l10n.personaReflectorDescription,
      AllocationPersona.realist => l10n.personaRealistDescription,
      AllocationPersona.firefighter => l10n.personaFirefighterDescription,
      AllocationPersona.custom => l10n.personaCustomDescription,
    };
  }
}

class _HowItWorksExpansion extends StatelessWidget {
  const _HowItWorksExpansion({required this.persona});

  final AllocationPersona persona;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ExpansionTile(
      title: Text(
        l10n.personaHowItWorks,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        Text(
          _howItWorksForPersona(l10n, persona),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _howItWorksForPersona(
    AppLocalizations l10n,
    AllocationPersona persona,
  ) {
    return switch (persona) {
      AllocationPersona.idealist => l10n.personaIdealistHowItWorks,
      AllocationPersona.reflector => l10n.personaReflectorHowItWorks,
      AllocationPersona.realist => l10n.personaRealistHowItWorks,
      AllocationPersona.firefighter => l10n.personaFirefighterHowItWorks,
      AllocationPersona.custom => l10n.personaCustomHowItWorks,
    };
  }
}
