import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

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
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceSm,
      ),
      child: FormBuilderField<List<String>>(
        name: name,
        enabled: enabled,
        validator: (value) {
          final customError = validator?.call(value);
          if (customError != null) return customError;
          if (!isRequired) return null;
          if (value == null || value.isEmpty) {
            return l10n.valuesPickerRequired;
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
                      title: Text(label ?? l10n.valuesLabel),
                      content: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 500,
                          maxHeight: 420,
                        ),
                        child: availableValues.isEmpty
                            ? Center(
                                child: Text(l10n.noValuesFound),
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
                          child: Text(l10n.cancelLabel),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(context).pop(workingSelection),
                          child: Text(l10n.doneLabel),
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
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                errorText: field.errorText,
                suffixIcon: const Icon(Icons.edit_outlined, size: 20),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceLg,
                  vertical: tokens.spaceSm,
                ),
              ),
              child: selectedValues.isEmpty
                  ? Text(
                      hint ?? l10n.selectValuesHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Wrap(
                      spacing: tokens.spaceSm,
                      runSpacing: tokens.spaceSm,
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
