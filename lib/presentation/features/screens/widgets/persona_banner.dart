import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/presentation/features/persona_wizard/view/persona_selection_page.dart';

class PersonaBanner extends StatelessWidget {
  const PersonaBanner({
    required this.persona,
    super.key,
  });

  final AllocationPersona persona;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PersonaSelectionPage(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _iconForPersona(persona),
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameForPersona(l10n, persona),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _descriptionForPersona(l10n, persona),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer.withOpacity(
                            0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onPrimaryContainer,
                ),
              ],
            ),
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
