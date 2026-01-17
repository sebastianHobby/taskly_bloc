import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_domain/domain/domain.dart';

/// A multi-select picker for selecting one or more Values.
///
/// The selected order is preserved; the first selected value is treated as the
/// "primary" by persistence code that uses `valueIds.first`.
class FormBuilderValuePicker extends StatelessWidget {
  const FormBuilderValuePicker({
    required this.name,
    required this.availableValues,
    this.label,
    this.hint,
    this.enabled = true,
    this.isRequired = false,
    this.validator,
    super.key,
  });

  final String name;
  final List<Value> availableValues;
  final String? label;
  final String? hint;
  final bool enabled;
  final bool isRequired;
  final String? Function(List<String>?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FormBuilderField<List<String>>(
        name: name,
        enabled: enabled,
        validator: (value) {
          final customError = validator?.call(value);
          if (customError != null) return customError;
          if (!isRequired) return null;
          if (value == null || value.isEmpty) {
            return 'Select at least one value.';
          }
          return null;
        },
        builder: (field) {
          final selectedIds = (field.value ?? const <String>[]).toList();
          final selectedValues = <Value>[
            for (final id in selectedIds)
              ...availableValues.where((v) => v.id == id),
          ];

          Future<void> openPicker() async {
            if (!enabled) return;

            final result = await showDialog<List<String>>(
              context: context,
              builder: (context) {
                var workingSelection = selectedIds.toList();

                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: Text(label ?? 'Values'),
                      content: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 500,
                          maxHeight: 420,
                        ),
                        child: availableValues.isEmpty
                            ? const Center(
                                child: Text('No values found.'),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: availableValues.length,
                                itemBuilder: (context, index) {
                                  final value = availableValues[index];
                                  final isSelected = workingSelection.contains(
                                    value.id,
                                  );

                                  return CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked ?? false) {
                                          if (!workingSelection.contains(
                                            value.id,
                                          )) {
                                            workingSelection = [
                                              ...workingSelection,
                                              value.id,
                                            ];
                                          }
                                        } else {
                                          workingSelection = [
                                            for (final id in workingSelection)
                                              if (id != value.id) id,
                                          ];
                                        }
                                      });
                                    },
                                    title: Text(value.name),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                  );
                                },
                              ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(context).pop(workingSelection),
                          child: const Text('Done'),
                        ),
                      ],
                    );
                  },
                );
              },
            );

            if (result == null) return;

            field.didChange(result);
            field.validate();
          }

          return InkWell(
            onTap: openPicker,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                errorText: field.errorText,
                suffixIcon: const Icon(Icons.edit_outlined, size: 20),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              child: selectedValues.isEmpty
                  ? Text(
                      hint ?? 'Select values',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final value in selectedValues)
                          InputChip(
                            label: Text(value.name),
                            onDeleted: enabled
                                ? () {
                                    final next = [
                                      for (final id in selectedIds)
                                        if (id != value.id) id,
                                    ];
                                    field.didChange(next);
                                    field.validate();
                                  }
                                : null,
                          ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
