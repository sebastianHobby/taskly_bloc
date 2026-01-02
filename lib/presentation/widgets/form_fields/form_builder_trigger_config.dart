import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';

/// A FormBuilder field for configuring workflow triggers.
///
/// Provides presets for common schedules (daily, weekly, monthly)
/// and allows manual-only workflows.
class FormBuilderTriggerConfig
    extends FormBuilderFieldDecoration<TriggerConfig> {
  FormBuilderTriggerConfig({
    required super.name,
    super.key,
    super.validator,
    super.initialValue,
    super.onChanged,
    super.enabled = true,
    super.decoration = const InputDecoration(border: InputBorder.none),
  }) : super(
         builder: (FormFieldState<TriggerConfig> field) {
           final state =
               field
                   as FormBuilderFieldDecorationState<
                     FormBuilderTriggerConfig,
                     TriggerConfig
                   >;

           return InputDecorator(
             decoration: state.decoration,
             child: _TriggerConfigSelector(
               value: state.value,
               enabled: state.enabled,
               onChanged: state.didChange,
             ),
           );
         },
       );

  @override
  FormBuilderFieldDecorationState<FormBuilderTriggerConfig, TriggerConfig>
  createState() => FormBuilderFieldDecorationState();
}

/// Preset trigger options for easy selection.
enum TriggerPreset {
  manual('Manual only', null),
  daily('Daily', 'FREQ=DAILY'),
  weekdays('Weekdays', 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'),
  weekly('Weekly', 'FREQ=WEEKLY'),
  weeklySunday('Weekly (Sunday)', 'FREQ=WEEKLY;BYDAY=SU'),
  weeklyMonday('Weekly (Monday)', 'FREQ=WEEKLY;BYDAY=MO'),
  biweekly('Every 2 weeks', 'FREQ=WEEKLY;INTERVAL=2'),
  monthly('Monthly', 'FREQ=MONTHLY'),
  quarterly('Quarterly', 'FREQ=MONTHLY;INTERVAL=3');

  const TriggerPreset(this.label, this.rrule);

  final String label;
  final String? rrule;

  TriggerConfig toConfig() {
    if (rrule == null) {
      return const TriggerConfig.manual();
    }
    return TriggerConfig.schedule(rrule: rrule!);
  }

  static TriggerPreset? fromConfig(TriggerConfig? config) {
    if (config == null) return manual;

    return config.when(
      schedule: (rrule, _) {
        for (final preset in TriggerPreset.values) {
          if (preset.rrule == rrule) return preset;
        }
        return null; // Custom RRULE
      },
      notReviewedSince: (_) => null,
      manual: () => manual,
    );
  }
}

class _TriggerConfigSelector extends StatefulWidget {
  const _TriggerConfigSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final TriggerConfig? value;
  final bool enabled;
  final ValueChanged<TriggerConfig?> onChanged;

  @override
  State<_TriggerConfigSelector> createState() => _TriggerConfigSelectorState();
}

class _TriggerConfigSelectorState extends State<_TriggerConfigSelector> {
  late TriggerPreset? _selectedPreset;
  late TextEditingController _customRruleController;
  bool _showCustom = false;

  @override
  void initState() {
    super.initState();
    _selectedPreset = TriggerPreset.fromConfig(widget.value);
    _showCustom = _selectedPreset == null && widget.value != null;

    final customRrule = widget.value?.whenOrNull(
      schedule: (rrule, _) => _selectedPreset == null ? rrule : null,
    );
    _customRruleController = TextEditingController(text: customRrule ?? '');
  }

  @override
  void dispose() {
    _customRruleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preset buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in TriggerPreset.values)
              _PresetChip(
                preset: preset,
                isSelected: _selectedPreset == preset && !_showCustom,
                enabled: widget.enabled,
                onSelected: () {
                  setState(() {
                    _selectedPreset = preset;
                    _showCustom = false;
                  });
                  widget.onChanged(preset.toConfig());
                },
              ),
            // Custom option
            ChoiceChip(
              label: const Text('Custom'),
              selected: _showCustom,
              onSelected: widget.enabled
                  ? (selected) {
                      setState(() {
                        _showCustom = selected;
                        if (!selected && _selectedPreset != null) {
                          widget.onChanged(_selectedPreset!.toConfig());
                        }
                      });
                    }
                  : null,
            ),
          ],
        ),

        // Custom RRULE input
        if (_showCustom) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _customRruleController,
            enabled: widget.enabled,
            decoration: InputDecoration(
              labelText: 'RRULE',
              hintText: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
              helperText: 'Enter a valid iCalendar RRULE',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: widget.enabled
                    ? () {
                        final rrule = _customRruleController.text.trim();
                        if (rrule.isNotEmpty) {
                          widget.onChanged(
                            TriggerConfig.schedule(rrule: rrule),
                          );
                        }
                      }
                    : null,
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                widget.onChanged(TriggerConfig.schedule(rrule: value.trim()));
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Examples: FREQ=DAILY, FREQ=WEEKLY;BYDAY=SU, FREQ=MONTHLY;BYMONTHDAY=1',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.isSelected,
    required this.enabled,
    required this.onSelected,
  });

  final TriggerPreset preset;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(preset.label),
      selected: isSelected,
      onSelected: enabled ? (_) => onSelected() : null,
    );
  }
}
