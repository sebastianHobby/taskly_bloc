import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/presentation/features/next_action/widgets/persona_card.dart';
import 'package:taskly_bloc/presentation/features/persona_wizard/view/custom_persona_config_page.dart';
import 'package:taskly_bloc/presentation/features/persona_wizard/view/safety_net_rules_page.dart';

class PersonaSelectionPage extends StatefulWidget {
  const PersonaSelectionPage({super.key});

  @override
  State<PersonaSelectionPage> createState() => _PersonaSelectionPageState();
}

class _PersonaSelectionPageState extends State<PersonaSelectionPage> {
  AllocationPersona? _selectedPersona;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Focus Style'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: AllocationPersona.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final persona = AllocationPersona.values[index];
                return PersonaCard(
                  persona: persona,
                  isSelected: persona == _selectedPersona,
                  onTap: () => setState(() => _selectedPersona = persona),
                  isRecommended: persona == AllocationPersona.realist,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedPersona == null
                    ? null
                    : () {
                        if (_selectedPersona == AllocationPersona.custom) {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const CustomPersonaConfigPage(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const SafetyNetRulesPage(),
                            ),
                          );
                        }
                      },
                child: const Text('Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
