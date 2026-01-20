import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_color_picker.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_icon_picker.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';

/// A modern form for creating or editing values.
///
/// Features:
/// - Action buttons in header (always visible)
/// - Unsaved changes confirmation on close
class ValueForm extends StatefulWidget {
  const ValueForm({
    required this.formKey,
    required this.initialData,
    required this.onSubmit,
    required this.submitTooltip,
    this.initialDraft,
    this.onChanged,
    this.onDelete,
    this.onClose,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final Value? initialData;

  /// Optional initial values for the create flow.
  ///
  /// When [initialData] is null (creating), these values seed the form.
  final ValueDraft? initialDraft;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  /// Called when the user wants to close the form.
  /// If null, no close button is shown.
  final VoidCallback? onClose;

  static const _defaultColorHex = '#000000';
  static const maxNameLength = 50;

  @override
  State<ValueForm> createState() => _ValueFormState();
}

class _ValueFormState extends State<ValueForm> with FormDirtyStateMixin {
  @override
  VoidCallback? get onClose => widget.onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final isCompact = MediaQuery.sizeOf(context).width < 600;

    final isCreating = widget.initialData == null;

    final createDraft = widget.initialData == null
        ? (widget.initialDraft ?? ValueDraft.empty())
        : null;

    final initialValues = <String, dynamic>{
      ValueFieldKeys.name.id:
          widget.initialData?.name.trim() ?? createDraft?.name.trim() ?? '',
      ValueFieldKeys.colour.id: ColorUtils.fromHex(
        widget.initialData?.color ??
            createDraft?.color ??
            ValueForm._defaultColorHex,
      ),
      ValueFieldKeys.priority.id:
          widget.initialData?.priority ??
          createDraft?.priority ??
          ValuePriority.medium,
      ValueFieldKeys.iconName.id:
          widget.initialData?.iconName ?? createDraft?.iconName,
    };

    final submitEnabled =
        isDirty && (widget.formKey.currentState?.isValid ?? false);

    final denseFieldPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 12 : 16,
      vertical: isCompact ? 10 : 12,
    );

    final sectionGap = isCompact ? 12.0 : 16.0;

    return FormShell(
      onSubmit: widget.onSubmit,
      submitTooltip: widget.submitTooltip,
      submitIcon: isCreating ? Icons.add : Icons.check,
      submitEnabled: submitEnabled,
      showHeaderSubmit: true,
      showFooterSubmit: false,
      closeOnLeft: true,
      onDelete: widget.initialData != null ? widget.onDelete : null,
      deleteTooltip: l10n.deleteValue,
      onClose: widget.onClose != null ? handleClose : null,
      closeTooltip: l10n.closeLabel,
      child: Padding(
        padding: EdgeInsets.only(bottom: isCompact ? 16 : 24),
        child: FormBuilder(
          key: widget.formKey,
          initialValue: initialValues,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: () {
            markDirty();
            setState(() {});
            final values = widget.formKey.currentState?.value;
            if (values != null) {
              widget.onChanged?.call(values);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderTextField(
                  name: ValueFieldKeys.name.id,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: ValueForm.maxNameLength,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.valueFormNameHint,
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: denseFieldPadding,
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: l10n.valueFormNameRequired,
                    ),
                    FormBuilderValidators.minLength(
                      1,
                      errorText: l10n.valueFormNameEmpty,
                    ),
                    FormBuilderValidators.maxLength(
                      ValueForm.maxNameLength,
                      errorText: l10n.valueFormNameTooLong(
                        ValueForm.maxNameLength,
                      ),
                    ),
                  ]),
                ),
              ),
              SizedBox(height: sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderField<ValuePriority>(
                  name: ValueFieldKeys.priority.id,
                  validator: FormBuilderValidators.required<ValuePriority>(),
                  builder: (field) {
                    final value = field.value ?? ValuePriority.medium;
                    return Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<ValuePriority>(
                            segments: [
                              ButtonSegment(
                                value: ValuePriority.low,
                                label: Text(l10n.valuePriorityLowLabel),
                              ),
                              ButtonSegment(
                                value: ValuePriority.medium,
                                label: Text(l10n.valuePriorityMediumLabel),
                              ),
                              ButtonSegment(
                                value: ValuePriority.high,
                                label: Text(l10n.valuePriorityHighLabel),
                              ),
                            ],
                            selected: {value},
                            onSelectionChanged: (selection) {
                              field.didChange(selection.first);
                              markDirty();
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderIconPicker(
                  name: ValueFieldKeys.iconName.id,
                ),
              ),
              SizedBox(height: sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderColorPicker(
                  name: ValueFieldKeys.colour.id,
                  showLabel: false,
                  compact: true,
                  validator: FormBuilderValidators.required<Color>(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
