import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_fields.dart';

/// A modern form for creating or editing labels/values.
///
/// Features:
/// - X close button in top right
/// - Action button in sticky footer at bottom right
/// - Unsaved changes confirmation on close
class LabelForm extends StatefulWidget {
  const LabelForm({
    required this.formKey,
    required this.initialData,
    required this.onSubmit,
    required this.submitTooltip,
    this.initialType,
    this.lockType = false,
    this.onDelete,
    this.onClose,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final Label? initialData;
  final LabelType? initialType;
  final bool lockType;
  final VoidCallback? onDelete;

  /// Called when the user wants to close the form.
  /// If null, no close button is shown.
  final VoidCallback? onClose;

  static const _defaultColorHex = '#000000';
  static const _defaultValueEmoji = '⭐';

  @override
  State<LabelForm> createState() => _LabelFormState();
}

class _LabelFormState extends State<LabelForm> with FormDirtyStateMixin {
  @override
  VoidCallback? get onClose => widget.onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine the effective type for display purposes
    final effectiveType =
        widget.initialData?.type ?? widget.initialType ?? LabelType.label;
    final isValueType = effectiveType == LabelType.value;
    final isCreating = widget.initialData == null;

    final Map<String, dynamic> initialValues = {
      'name': widget.initialData?.name.trim() ?? '',
      'colour': ColorUtils.fromHex(
        widget.initialData?.color ?? LabelForm._defaultColorHex,
      ),
      'type': effectiveType,
      // Default emoji to heart for values, empty for labels
      'iconName':
          widget.initialData?.iconName ??
          (isValueType ? LabelForm._defaultValueEmoji : ''),
    };

    final entityName = isValueType ? 'Value' : 'Label';

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
                  isValueType ? Icons.sell : Icons.label,
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
                    tooltip: 'Delete $entityName',
                    visualDensity: VisualDensity.compact,
                  ),

                // Close button (X) in top right
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: handleClose,
                    tooltip: 'Close',
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
            onChanged: markDirty,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name field
                  FormBuilderTextField(
                    name: 'name',
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

                  // Type picker (only when creating and not locked)
                  if (widget.initialData == null && !widget.lockType)
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderLabelTypePickerModern(
                            name: 'type',
                            label: 'Type',
                            compact: true,
                            validator:
                                FormBuilderValidators.required<LabelType>(
                                  errorText: 'Type is required',
                                ),
                          ),
                        ),
                      ],
                    ),

                  if (widget.initialData == null && !widget.lockType)
                    const SizedBox(height: 12),

                  // Color and Emoji pickers
                  FormBuilderField<LabelType>(
                    name: 'type',
                    builder: (field) {
                      final isValue = field.value == LabelType.value;

                      return Row(
                        children: [
                          FormBuilderColorPickerModern(
                            name: 'colour',
                            showLabel: false,
                            compact: true,
                            validator: FormBuilderValidators.required<Color>(
                              errorText: 'Color is required',
                            ),
                          ),
                          if (isValue) ...[
                            const SizedBox(width: 8),
                            FormBuilderEmojiPickerModern(
                              name: 'iconName',
                              showLabel: false,
                              compact: true,
                              validator: FormBuilderValidators.required<String>(
                                errorText: 'Emoji is required',
                              ),
                            ),
                          ],
                        ],
                      );
                    },
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
