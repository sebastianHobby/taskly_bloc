import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_fields.dart';

/// A modern form for creating or editing values.
///
/// Features:
/// - X close button in top right
/// - Action button in sticky footer at bottom right
/// - Unsaved changes confirmation on close
class ValueForm extends StatefulWidget {
  const ValueForm({
    required this.formKey,
    required this.initialData,
    required this.onSubmit,
    required this.submitTooltip,
    this.onChanged,
    this.onDelete,
    this.onClose,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final Value? initialData;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  /// Called when the user wants to close the form.
  /// If null, no close button is shown.
  final VoidCallback? onClose;

  static const _defaultColorHex = '#000000';
  static const _defaultValueEmoji = '⭐';

  @override
  State<ValueForm> createState() => _ValueFormState();
}

class _ValueFormState extends State<ValueForm> with FormDirtyStateMixin {
  @override
  VoidCallback? get onClose => widget.onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    final isCreating = widget.initialData == null;

    final initialValues = <String, dynamic>{
      ValueFieldKeys.name.id: widget.initialData?.name.trim() ?? '',
      ValueFieldKeys.colour.id: ColorUtils.fromHex(
        widget.initialData?.color ?? ValueForm._defaultColorHex,
      ),
      ValueFieldKeys.priority.id:
          widget.initialData?.priority ?? ValuePriority.medium,
      ValueFieldKeys.iconName.id:
          widget.initialData?.iconName ?? ValueForm._defaultValueEmoji,
    };

    const entityName = 'Value';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with title and close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                // Title with icon
                Icon(
                  Icons.sell,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCreating ? 'New $entityName' : 'Edit $entityName',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Delete button (if editing)
                if (widget.initialData != null && widget.onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    onPressed: widget.onDelete,
                    tooltip: l10n.deleteValue,
                    visualDensity: VisualDensity.compact,
                  ),

                // Close button (X) in top right
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: handleClose,
                    tooltip: l10n.closeLabel,
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 16),

          // Form content
          FormBuilder(
            key: widget.formKey,
            initialValue: initialValues,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: () {
              markDirty();
              final values = widget.formKey.currentState?.value;
              if (values != null) {
                widget.onChanged?.call(values);
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name field
                  FormBuilderTextField(
                    name: ValueFieldKeys.name.id,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Name',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      isDense: true,
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required<String>(
                        errorText: 'Name is required',
                      ),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  // Priority Picker
                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderDropdown<ValuePriority>(
                          name: ValueFieldKeys.priority.id,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            filled: true,
                            fillColor: colorScheme.surfaceContainerLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: ValuePriority.values
                              .map(
                                (priority) => DropdownMenuItem(
                                  value: priority,
                                  child: Text(
                                    priority.name[0].toUpperCase() +
                                        priority.name.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
                          validator:
                              FormBuilderValidators.required<ValuePriority>(
                                errorText: 'Priority is required',
                              ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Color and Emoji pickers
                  Row(
                    children: [
                      FormBuilderColorPickerModern(
                        name: ValueFieldKeys.colour.id,
                        showLabel: false,
                        compact: true,
                        validator: FormBuilderValidators.required<Color>(
                          errorText: 'Color is required',
                        ),
                      ),
                      const SizedBox(width: 8),
                      FormBuilderEmojiPickerModern(
                        name: ValueFieldKeys.iconName.id,
                        showLabel: false,
                        compact: true,
                        validator: FormBuilderValidators.required<String>(
                          errorText: 'Emoji is required',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Sticky footer with action button at bottom right
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: widget.onSubmit,
                  icon: Icon(
                    isCreating ? Icons.add : Icons.check,
                    size: 18,
                  ),
                  label: Text(
                    isCreating ? 'Create $entityName' : 'Save Changes',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
