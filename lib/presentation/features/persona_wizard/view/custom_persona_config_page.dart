import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/presentation/features/persona_wizard/view/safety_net_rules_page.dart';

class CustomPersonaConfigPage extends StatefulWidget {
  const CustomPersonaConfigPage({super.key});

  @override
  State<CustomPersonaConfigPage> createState() =>
      _CustomPersonaConfigPageState();
}

class _CustomPersonaConfigPageState extends State<CustomPersonaConfigPage> {
  late StrategySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = const StrategySettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Persona Configuration'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Urgency Settings'),
          DropdownButtonFormField<UrgentTaskBehavior>(
            value: _settings.urgentTaskBehavior,
            decoration: const InputDecoration(
              labelText: 'Urgent Task Behavior',
            ),
            items: UrgentTaskBehavior.values.map((e) {
              return DropdownMenuItem(
                value: e,
                child: Text(e.name),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _settings = _settings.copyWith(urgentTaskBehavior: val);
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _settings.taskUrgencyThresholdDays.toString(),
            decoration: const InputDecoration(
              labelText: 'Task Urgency Threshold (Days)',
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final days = int.tryParse(val);
              if (days != null) {
                setState(() {
                  _settings = _settings.copyWith(
                    taskUrgencyThresholdDays: days,
                  );
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Urgency Boost Multiplier: ${_settings.urgencyBoostMultiplier.toStringAsFixed(1)}x',
          ),
          Slider(
            value: _settings.urgencyBoostMultiplier,
            min: 1,
            max: 5,
            divisions: 40,
            label: _settings.urgencyBoostMultiplier.toStringAsFixed(1),
            onChanged: (val) {
              setState(() {
                _settings = _settings.copyWith(urgencyBoostMultiplier: val);
              });
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('Neglect Settings'),
          SwitchListTile(
            title: const Text('Enable Neglect Weighting'),
            value: _settings.enableNeglectWeighting,
            onChanged: (val) {
              setState(() {
                _settings = _settings.copyWith(enableNeglectWeighting: val);
              });
            },
          ),
          if (_settings.enableNeglectWeighting) ...[
            TextFormField(
              initialValue: _settings.neglectLookbackDays.toString(),
              decoration: const InputDecoration(
                labelText: 'Neglect Lookback (Days)',
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final days = int.tryParse(val);
                if (days != null) {
                  setState(() {
                    _settings = _settings.copyWith(neglectLookbackDays: days);
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Neglect Influence: ${_settings.neglectInfluence.toStringAsFixed(1)}',
            ),
            Slider(
              value: _settings.neglectInfluence,
              min: 0,
              max: 1,
              divisions: 10,
              label: _settings.neglectInfluence.toStringAsFixed(1),
              onChanged: (val) {
                setState(() {
                  _settings = _settings.copyWith(neglectInfluence: val);
                });
              },
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SafetyNetRulesPage(),
                  ),
                );
              },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
