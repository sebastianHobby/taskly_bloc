import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/shared/validation/form_builder_validator_adapter.dart';
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
  static const int maxNameLength = ValueValidators.maxNameLength;

  @override
  State<ValueForm> createState() => _ValueFormState();
}

class _ValueFormState extends State<ValueForm> with FormDirtyStateMixin {
  @override
  VoidCallback? get onClose => widget.onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final isCompact = MediaQuery.sizeOf(context).width < 600;

    final isCreating = widget.initialData == null;

    final ValueDraft? createDraft = widget.initialData == null
        ? (widget.initialDraft ?? ValueDraft.empty())
        : null;

    final initialValues = <String, dynamic>{
      ValueFieldKeys.name.id:
          widget.initialData?.name.trim() ?? createDraft?.name.trim() ?? '',
      ValueFieldKeys.colour.id: ColorUtils.fromHex(
        widget.initialData?.color ??
            createDraft?.color ??
            ValueForm._defaultColorHex,
        fallback: scheme.primary,
      ),
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
                child: _LiveValuePreviewCard(isCompact: isCompact),
              ),
              SizedBox(height: sectionGap),
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
                  validator: toFormBuilderValidator<String>(
                    ValueValidators.name,
                    context,
                  ),
                ),
              ),
              SizedBox(height: sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderIconPicker(
                  name: ValueFieldKeys.iconName.id,
                  title: l10n.valueFormIconLabel,
                  hintText: l10n.valueFormIconHint,
                ),
              ),
              SizedBox(height: sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderColorPicker(
                  name: ValueFieldKeys.colour.id,
                  title: l10n.valueFormColorLabel,
                  compact: true,
                  validator: toFormBuilderValidator<Color>(
                    (value) => ValueValidators.color(
                      value == null ? null : ColorUtils.toHex(value),
                    ),
                    context,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveValuePreviewCard extends StatelessWidget {
  const _LiveValuePreviewCard({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;

    final form = FormBuilder.of(context);
    final values = form?.instantValue ?? const <String, dynamic>{};

    final rawName = values[ValueFieldKeys.name.id] as String?;
    final name = (rawName ?? '').trim().isEmpty
        ? l10n.valueFormNameHint
        : rawName!.trim();

    final color = (values[ValueFieldKeys.colour.id] as Color?) ?? cs.primary;

    final iconName = values[ValueFieldKeys.iconName.id] as String?;
    final iconData =
        FormBuilderIconPicker.getIconData(iconName) ?? Icons.star_rounded;

    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? cs.surface
        : cs.onSurface;

    final cardPadding = isCompact
        ? const EdgeInsets.all(14)
        : const EdgeInsets.all(18);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.22),
            cs.surfaceContainerLow,
          ],
        ),
      ),
      child: Padding(
        padding: cardPadding,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(iconData, color: onColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.valueFormPreviewLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
