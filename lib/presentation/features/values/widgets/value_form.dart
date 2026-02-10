import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/debouncer.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/shared/validation/form_builder_validator_adapter.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_color_picker.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_icon_picker.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

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

  static const String _defaultColorHex = ColorUtils.valueBlueId;
  static const int maxNameLength = ValueValidators.maxNameLength;

  @override
  State<ValueForm> createState() => _ValueFormState();
}

class _ValueFormState extends State<ValueForm> with FormDirtyStateMixin {
  static const _draftSyncDebounce = Duration(milliseconds: 400);

  @override
  VoidCallback? get onClose => widget.onClose;

  final _scrollController = ScrollController();
  final Debouncer _draftSyncDebouncer = Debouncer(_draftSyncDebounce);
  bool _submitEnabled = false;

  void _handleFormChanged() {
    markDirty();
    _scheduleDraftSync();
    _refreshSubmitEnabled();
  }

  void _scheduleDraftSync() {
    final onChanged = widget.onChanged;
    if (onChanged == null) return;
    _draftSyncDebouncer.schedule(() {
      if (!mounted) return;
      final values = widget.formKey.currentState?.value;
      if (values != null) {
        onChanged(values);
      }
    });
  }

  void _refreshSubmitEnabled() {
    final next = isDirty && (widget.formKey.currentState?.isValid ?? false);
    if (next == _submitEnabled || !mounted) return;
    setState(() => _submitEnabled = next);
  }

  @override
  void dispose() {
    _draftSyncDebouncer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final isCreating = widget.initialData == null;

    final ValueDraft? createDraft = widget.initialData == null
        ? (widget.initialDraft ?? ValueDraft.empty())
        : null;

    final initialValues = <String, dynamic>{
      ValueFieldKeys.name.id:
          widget.initialData?.name.trim() ?? createDraft?.name.trim() ?? '',
      ValueFieldKeys.colour.id: ColorUtils.valueColorForTheme(
        context,
        widget.initialData?.color ??
            createDraft?.color ??
            ValueForm._defaultColorHex,
        fallback: scheme.primary,
      ),
      ValueFieldKeys.iconName.id:
          widget.initialData?.iconName ?? createDraft?.iconName,
    };

    final submitEnabled = _submitEnabled;

    final sectionGap = isCompact ? 12.0 : 16.0;

    final headerActionStyle = TextButton.styleFrom(
      textStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    final headerTitle = Text(
      isCreating ? l10n.createValueOption : l10n.editValue,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    return FormShell(
      onSubmit: widget.onSubmit,
      submitTooltip: widget.submitTooltip,
      submitIcon: isCreating ? Icons.add : Icons.check,
      submitEnabled: submitEnabled,
      showHeaderSubmit: false,
      showFooterSubmit: false,
      closeOnLeft: false,
      onDelete: null,
      deleteTooltip: l10n.deleteValue,
      onClose: null,
      closeTooltip: l10n.closeLabel,
      scrollController: _scrollController,
      headerTitle: headerTitle,
      centerHeaderTitle: true,
      leadingActions: [
        if (widget.onClose != null)
          TextButton(
            onPressed: handleClose,
            style: headerActionStyle,
            child: Text(l10n.cancelLabel),
          ),
      ],
      trailingActions: [
        if (widget.initialData != null && widget.onDelete != null)
          PopupMenuButton<int>(
            tooltip: l10n.moreOptionsLabel,
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 0,
                child: Text(
                  l10n.deleteValue,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ],
            onSelected: (_) => widget.onDelete?.call(),
          ),
        Tooltip(
          message: widget.submitTooltip,
          child: TextButton(
            onPressed: submitEnabled ? widget.onSubmit : null,
            style: headerActionStyle.copyWith(
              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                (states) => states.contains(WidgetState.disabled)
                    ? scheme.onSurfaceVariant
                    : scheme.primary,
              ),
            ),
            child: Text(l10n.saveLabel),
          ),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.only(
          bottom: isCompact
              ? TasklyTokens.of(context).spaceLg
              : TasklyTokens.of(context).spaceXl,
        ),
        child: FormBuilder(
          key: widget.formKey,
          initialValue: initialValues,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _handleFormChanged,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: TasklyTokens.of(context).spaceLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                FormBuilderTextField(
                  name: ValueFieldKeys.name.id,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: ValueForm.maxNameLength,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration:
                      const InputDecoration(
                        border: InputBorder.none,
                        hintText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ).copyWith(
                        hintText: l10n.valueFormNameHint,
                      ),
                  validator: toFormBuilderValidator<String>(
                    ValueValidators.name,
                    context,
                  ),
                ),
                SizedBox(height: sectionGap),
                TasklyFormSectionLabel(text: l10n.valueFormIconLabel),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                FormBuilderIconPicker(
                  name: ValueFieldKeys.iconName.id,
                  searchHintText: l10n.valueFormIconSearchHint,
                  noIconsFoundLabel: l10n.valueFormIconNoResults,
                  gridHeight: isCompact ? 200 : 240,
                ),
                SizedBox(height: sectionGap),
                TasklyFormSectionLabel(text: l10n.valueFormColorLabel),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                FormBuilderColorPicker(
                  name: ValueFieldKeys.colour.id,
                  title: l10n.valueFormColorLabel,
                  showLabel: false,
                  compact: true,
                  validator: toFormBuilderValidator<Color>(
                    (value) => ValueValidators.color(
                      value == null ? null : ColorUtils.toHex(value),
                    ),
                    context,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
