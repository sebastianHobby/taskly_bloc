import 'package:flutter/material.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
// import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_tag_picker.dart'; // Removed
import 'package:taskly_bloc/presentation/shared/utils/date_display_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/debouncer.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/rich_text_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/rrule_label_utils.dart';
import 'package:taskly_bloc/presentation/shared/validation/form_builder_validator_adapter.dart';
import 'package:taskly_bloc/presentation/shared/widgets/form_footer_bar.dart';
import 'package:taskly_bloc/presentation/shared/widgets/anchored_dialog_layout_delegate.dart';
import 'package:taskly_bloc/presentation/shared/widgets/inline_date_editor_panel.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';
import 'package:taskly_bloc/presentation/widgets/values_alignment/values_alignment_sheet.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:provider/provider.dart';

/// A modern form for creating or editing projects.
///
/// Features:
/// - Action buttons in header (always visible)
/// - Unsaved changes confirmation on close
/// - Clear cancel/close affordance
class ProjectForm extends StatefulWidget {
  const ProjectForm({
    required this.formKey,
    required this.initialData,
    required this.onSubmit,
    required this.submitTooltip,
    this.onChanged,
    this.availableValues = const <Value>[],
    this.openToValues = false,
    this.isSubmitting = false,
    this.onClose,
    this.trailingActions = const <Widget>[],
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final Project? initialData;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final List<Value> availableValues;

  /// When true, scrolls to the values section and opens the values alignment
  /// sheet on first build.
  final bool openToValues;
  final bool isSubmitting;

  /// Called when the user wants to close the form.
  /// If null, no close button is shown.
  final VoidCallback? onClose;

  /// Optional action widgets to render in the header row (right side).
  final List<Widget> trailingActions;

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

enum _ProjectDateEditorTarget { due }

class _ProjectFormState extends State<ProjectForm> with FormDirtyStateMixin {
  static const _draftSyncDebounce = Duration(milliseconds: 400);

  @override
  VoidCallback? get onClose => widget.onClose;

  final _scrollController = ScrollController();
  final GlobalKey<State<StatefulWidget>> _valuesKey = GlobalKey();
  final FocusNode _notesFocusNode = FocusNode();
  final Debouncer _draftSyncDebouncer = Debouncer(_draftSyncDebounce);
  bool _didAutoOpen = false;
  bool _submitEnabled = false;
  String? _recurrenceLabel;
  String? _lastRecurrenceRrule;
  _ProjectDateEditorTarget? _activeDateEditor;

  void _updateRecurrenceLabel(String? rrule) {
    final normalized = (rrule ?? '').trim();
    if (normalized == _lastRecurrenceRrule) return;
    _lastRecurrenceRrule = normalized;

    if (normalized.isEmpty) {
      if (_recurrenceLabel == null) return;
      setState(() => _recurrenceLabel = null);
      return;
    }

    if (_recurrenceLabel != null) {
      setState(() => _recurrenceLabel = null);
    }

    final requestRrule = normalized;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final label = await resolveRruleLabel(context, requestRrule);
      if (!mounted || _lastRecurrenceRrule != requestRrule) return;
      setState(() => _recurrenceLabel = label);
    });
  }

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
    final next = _hasRequiredFields() && !widget.isSubmitting;
    if (next == _submitEnabled || !mounted) return;
    setState(() => _submitEnabled = next);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateRecurrenceLabel(widget.initialData?.repeatIcalRrule);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didAutoOpen) return;
      if (!widget.openToValues) return;
      _didAutoOpen = true;

      final ctx = _valuesKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.1,
          duration: const Duration(milliseconds: 220),
        );
        if (!ctx.mounted) return;
      }
      if (!mounted) return;

      final current = widget
          .formKey
          .currentState
          ?.fields[ProjectFieldKeys.valueIds.id]
          ?.value;
      final valueIds = List<String>.of(current as List<String>? ?? const []);

      final anchorContext = _valuesKey.currentContext;
      if (anchorContext == null || !mounted) return;

      final result = await _showValuesAlignmentPicker(
        anchorContext: anchorContext,
        valueIds: valueIds,
        target: ValuesAlignmentTarget.primary,
      );
      if (!mounted || result == null) return;

      widget.formKey.currentState?.fields[ProjectFieldKeys.valueIds.id]
          ?.didChange(result);
      markDirty();
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshSubmitEnabled();
    });
  }

  @override
  void dispose() {
    _draftSyncDebouncer.dispose();
    _scrollController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProjectForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData?.repeatIcalRrule !=
        widget.initialData?.repeatIcalRrule) {
      _updateRecurrenceLabel(widget.initialData?.repeatIcalRrule);
    }
    if (oldWidget.isSubmitting != widget.isSubmitting) {
      _refreshSubmitEnabled();
    }
  }

  bool _isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  Rect _anchorRect(BuildContext anchorContext) {
    final box = anchorContext.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  Future<T?> _showAnchoredDialog<T>(
    BuildContext context, {
    required BuildContext anchorContext,
    required WidgetBuilder builder,
    double maxWidth = 420,
    double maxHeight = 520,
  }) {
    final anchor = _anchorRect(anchorContext);
    final theme = Theme.of(context);

    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: theme.colorScheme.surface.withValues(alpha: 0),
      pageBuilder: (dialogContext, _, __) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(dialogContext).maybePop(),
              child: ColoredBox(
                color: theme.colorScheme.surface.withValues(alpha: 0),
              ),
            ),
            CustomSingleChildLayout(
              delegate: AnchoredDialogLayoutDelegate(
                anchor: anchor,
                margin: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: Material(
                elevation: 6,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    TasklyTokens.of(context).radiusMd,
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: builder(dialogContext),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<String>?> _showValuesAlignmentPicker({
    required BuildContext anchorContext,
    required List<String> valueIds,
    required ValuesAlignmentTarget target,
  }) {
    if (_isCompact(context)) {
      return showValuesAlignmentSheetForProject(
        context,
        availableValues: widget.availableValues,
        valueIds: valueIds,
        target: target,
      );
    }

    return _showAnchoredDialog<List<String>>(
      context,
      anchorContext: anchorContext,
      maxWidth: 520,
      maxHeight: 560,
      builder: (dialogContext) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ValuesAlignmentSheet.project(
          availableValues: widget.availableValues,
          valueIds: valueIds,
          target: target,
        ),
      ),
    );
  }

  void _toggleDateEditor(_ProjectDateEditorTarget target) {
    setState(() {
      _activeDateEditor = _activeDateEditor == target ? null : target;
    });
  }

  void _setDateForTarget(DateTime? value) {
    final fieldKey = ProjectFieldKeys.deadlineDate.id;
    widget.formKey.currentState?.fields[fieldKey]?.didChange(value);
    markDirty();
    setState(() => _activeDateEditor = null);
  }

  Future<RecurrencePickerResult?> _pickRecurrence({
    required BuildContext anchorContext,
    required String? initialRrule,
    required bool initialRepeatFromCompletion,
    required bool initialSeriesEnded,
  }) {
    final picker = RecurrencePicker(
      initialRRule: initialRrule,
      initialRepeatFromCompletion: initialRepeatFromCompletion,
      initialSeriesEnded: initialSeriesEnded,
    );

    if (_isCompact(context)) {
      return showModalBottomSheet<RecurrencePickerResult>(
        context: context,
        useSafeArea: true,
        showDragHandle: false,
        isScrollControlled: true,
        builder: (sheetContext) => picker,
      );
    }

    return _showAnchoredDialog<RecurrencePickerResult>(
      context,
      anchorContext: anchorContext,
      maxWidth: 520,
      maxHeight: 640,
      builder: (dialogContext) => picker,
    );
  }

  Future<_PrioritySelectionResult?> _pickPriority({
    required BuildContext anchorContext,
    required int? initialPriority,
  }) {
    if (_isCompact(context)) {
      return _showPriorityMenu(anchorContext: anchorContext);
    }

    return _showAnchoredDialog<_PrioritySelectionResult>(
      context,
      anchorContext: anchorContext,
      maxWidth: 280,
      maxHeight: 320,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        final current = initialPriority;
        final options = [
          (value: null as int?, label: l10n.sortFieldNoneLabel),
          (value: 1 as int?, label: l10n.priorityP1Label),
          (value: 2 as int?, label: l10n.priorityP2Label),
          (value: 3 as int?, label: l10n.priorityP3Label),
          (value: 4 as int?, label: l10n.priorityP4Label),
        ];

        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 240),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              for (final option in options)
                ListTile(
                  dense: true,
                  leading: Icon(
                    current == option.value
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                  ),
                  title: Text(option.label),
                  onTap: () => Navigator.of(dialogContext).pop(
                    _PrioritySelectionResult(priority: option.value),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<_PrioritySelectionResult?> _showPriorityMenu({
    required BuildContext anchorContext,
  }) async {
    final l10n = context.l10n;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final anchor = _anchorRect(anchorContext);
    final selected = await showMenu<int>(
      context: context,
      position: RelativeRect.fromRect(anchor, Offset.zero & overlay.size),
      items: [
        PopupMenuItem<int>(
          value: -1,
          child: Text(l10n.sortFieldNoneLabel),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Text(l10n.priorityP1Label),
        ),
        PopupMenuItem<int>(
          value: 2,
          child: Text(l10n.priorityP2Label),
        ),
        PopupMenuItem<int>(
          value: 3,
          child: Text(l10n.priorityP3Label),
        ),
        PopupMenuItem<int>(
          value: 4,
          child: Text(l10n.priorityP4Label),
        ),
      ],
    );
    if (selected == null) return null;
    return _PrioritySelectionResult(priority: selected == -1 ? null : selected);
  }

  bool _hasRequiredFields() {
    final form = widget.formKey.currentState;
    final name =
        ((form?.fields[ProjectFieldKeys.name.id]?.value as String?) ??
                widget.initialData?.name ??
                '')
            .trim();
    final valueIds =
        (form?.fields[ProjectFieldKeys.valueIds.id]?.value as List<dynamic>?)
            ?.whereType<String>()
            .where((id) => id.trim().isNotEmpty)
            .toList(growable: false) ??
        widget.initialData?.values
            .map((value) => value.id)
            .toList(growable: false) ??
        const <String>[];
    return name.isNotEmpty && valueIds.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final isCompact = _isCompact(context);
    final isCreating = widget.initialData == null;
    final now = context.read<NowService>().nowLocal();

    final availableValuesById = <String, Value>{
      for (final v in widget.availableValues) v.id: v,
    };

    final normalizedDescription = serializeParchmentDocument(
      parseParchmentDocument(widget.initialData?.description),
    );
    final initialValues = <String, dynamic>{
      ProjectFieldKeys.name.id: widget.initialData?.name.trim() ?? '',
      ProjectFieldKeys.description.id: normalizedDescription,
      ProjectFieldKeys.completed.id: widget.initialData?.completed ?? false,
      ProjectFieldKeys.startDate.id: widget.initialData?.startDate,
      ProjectFieldKeys.deadlineDate.id: widget.initialData?.deadlineDate,
      ProjectFieldKeys.priority.id: widget.initialData?.priority,
      ProjectFieldKeys.valueIds.id:
          (widget.initialData?.values ?? <Value>[]) // Use values property
              .map((e) => e.id)
              .take(1)
              .toList(growable: false),
      ProjectFieldKeys.repeatIcalRrule.id:
          widget.initialData?.repeatIcalRrule ?? '',
      ProjectFieldKeys.repeatFromCompletion.id:
          widget.initialData?.repeatFromCompletion ?? false,
      ProjectFieldKeys.seriesEnded.id: widget.initialData?.seriesEnded ?? false,
    };
    final initialDescription = normalizedDescription;

    final submitEnabled = _submitEnabled;

    final formPreset = TasklyFormPreset.standard(tokens);
    final sectionGap = isCompact
        ? formPreset.ux.sectionGapCompact
        : formPreset.ux.sectionGapRegular;
    final chipPreset = formPreset.chip;

    final headerTitle = Text(
      isCreating ? l10n.projectFormNewTitle : l10n.projectFormEditTitle,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    return FormShell(
      onSubmit: widget.onSubmit,
      submitTooltip: l10n.saveLabel,
      submitIcon: isCreating ? Icons.add : Icons.check,
      submitEnabled: submitEnabled,
      showHeaderSubmit: false,
      showFooterSubmit: false,
      closeOnLeft: false,
      onDelete: null,
      deleteTooltip: l10n.deleteProjectAction,
      onClose: widget.onClose == null ? null : handleClose,
      closeTooltip: l10n.closeLabel,
      scrollController: _scrollController,
      showHandleBar: false,
      headerTitle: headerTitle,
      centerHeaderTitle: true,
      trailingActions: widget.trailingActions,
      footer: FormFooterBar(
        submitLabel: widget.submitTooltip,
        submitEnabled: submitEnabled,
        onSubmit: widget.onSubmit,
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCreating)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: TasklyTokens.of(context).spaceSm,
                      ),
                      child: FormBuilderField<bool>(
                        name: ProjectFieldKeys.completed.id,
                        builder: (field) {
                          return SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: field.value ?? false,
                              onChanged: (value) {
                                field.didChange(value);
                                markDirty();
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  TasklyTokens.of(context).radiusSm,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!isCreating)
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                  Expanded(
                    child: TasklyFormTitleField(
                      name: ProjectFieldKeys.name.id,
                      hintText: l10n.projectFormTitleHint,
                      autofocus: isCreating,
                      onSubmitted: (_) => _notesFocusNode.requestFocus(),
                      validator: toFormBuilderValidator<String>(
                        ProjectValidators.name,
                        context,
                      ),
                    ),
                  ),
                ],
              ),

              if (isCreating)
                FormBuilderField<bool>(
                  name: ProjectFieldKeys.completed.id,
                  builder: (_) => SizedBox.shrink(),
                ),

              SizedBox(height: sectionGap),
              _ProjectNotesField(
                name: ProjectFieldKeys.description.id,
                initialValue: initialDescription,
                hintText: l10n.projectFormDescriptionHint,
                isCompact: isCompact,
                focusNode: _notesFocusNode,
                contentPadding: formPreset.ux.notesContentPadding,
                validator: toFormBuilderValidator<String>(
                  ProjectValidators.description,
                  context,
                ),
              ),
              SizedBox(height: sectionGap),

              // Meta chips row (values-first): Values, Planned Day, Due Date,
              // Priority, Repeat
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TasklyFormSectionLabel(text: l10n.projectValueTitle),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  FormBuilderField<List<String>>(
                    name: ProjectFieldKeys.valueIds.id,
                    validator: toFormBuilderValidator<List<String>>(
                      ProjectValidators.valueIds,
                      context,
                    ),
                    builder: (field) {
                      final valueIds = List<String>.of(
                        field.value ?? const <String>[],
                      ).take(1).toList(growable: false);
                      final primary = valueIds.isEmpty
                          ? null
                          : availableValuesById[valueIds.first];
                      final chip = primary?.toChipData(context);
                      final iconName = primary?.iconName;
                      final iconData = iconName == null
                          ? Icons.favorite_rounded
                          : (getIconDataFromName(iconName) ??
                                Icons.favorite_rounded);
                      final iconColor = chip?.color ?? colorScheme.primary;
                      final title =
                          primary?.name ?? l10n.projectValuePlaceholder;

                      return KeyedSubtree(
                        key: _valuesKey,
                        child: Builder(
                          builder: (chipContext) => TasklyFormValueCard(
                            title: title,
                            helperText: primary == null
                                ? l10n.projectValueHelper
                                : null,
                            icon: iconData,
                            iconColor: iconColor,
                            hasValue: primary != null,
                            onTap: () async {
                              final result = await _showValuesAlignmentPicker(
                                anchorContext: chipContext,
                                valueIds: valueIds,
                                target: ValuesAlignmentTarget.primary,
                              );
                              if (!mounted || result == null) return;
                              field.didChange(
                                result.take(1).toList(growable: false),
                              );
                              markDirty();
                              setState(() {});
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  Builder(
                    builder: (context) {
                      final errorText = widget
                          .formKey
                          .currentState
                          ?.fields[ProjectFieldKeys.valueIds.id]
                          ?.errorText;
                      if (errorText == null) return SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: TasklyTokens.of(context).spaceSm,
                        ),
                        child: Text(
                          errorText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: sectionGap),
                  Builder(
                    builder: (context) {
                      final deadlineDate =
                          (widget
                                  .formKey
                                  .currentState
                                  ?.fields[ProjectFieldKeys.deadlineDate.id]
                                  ?.value
                              as DateTime?) ??
                          (initialValues[ProjectFieldKeys.deadlineDate.id]
                              as DateTime?);
                      final recurrenceRrule =
                          (widget
                                  .formKey
                                  .currentState
                                  ?.fields[ProjectFieldKeys.repeatIcalRrule.id]
                                  ?.value
                              as String?) ??
                          (initialValues[ProjectFieldKeys.repeatIcalRrule.id]
                              as String?) ??
                          '';
                      final priority =
                          (widget
                                  .formKey
                                  .currentState
                                  ?.fields[ProjectFieldKeys.priority.id]
                                  ?.value
                              as int?) ??
                          (initialValues[ProjectFieldKeys.priority.id] as int?);
                      final hasRecurrence = recurrenceRrule.trim().isNotEmpty;

                      final dueLabel = deadlineDate == null
                          ? null
                          : DateDisplayUtils.formatMonthDayYear(deadlineDate);
                      final isOverdue = DateDisplayUtils.isOverdue(
                        deadlineDate,
                        now: now,
                      );

                      String? priorityLabel;
                      Color? priorityColor;
                      if (priority == 1) {
                        priorityLabel = l10n.priorityP1Label;
                        priorityColor = colorScheme.error;
                      } else if (priority == 2) {
                        priorityLabel = l10n.priorityP2Label;
                        priorityColor = colorScheme.tertiary;
                      } else if (priority == 3) {
                        priorityLabel = l10n.priorityP3Label;
                        priorityColor = colorScheme.primary;
                      } else if (priority == 4) {
                        priorityLabel = l10n.priorityP4Label;
                        priorityColor = colorScheme.onSurfaceVariant;
                      }

                      final repeatValueLabel = hasRecurrence
                          ? (_recurrenceLabel ?? l10n.loadingTitle)
                          : null;

                      final chips = <Widget>[
                        TasklyFormInlineChip(
                          label: l10n.dueLabel,
                          icon: Icons.flag_rounded,
                          valueLabel: dueLabel,
                          hasValue: dueLabel != null,
                          valueColor: isOverdue
                              ? colorScheme.error
                              : colorScheme.primary,
                          showLabelWhenEmpty: false,
                          preset: chipPreset,
                          onTap: () =>
                              _toggleDateEditor(_ProjectDateEditorTarget.due),
                        ),
                        TasklyFormInlineChip(
                          label: l10n.recurrenceRepeatTitle,
                          icon: Icons.repeat,
                          valueLabel: repeatValueLabel,
                          hasValue: hasRecurrence,
                          showLabelWhenEmpty: false,
                          preset: chipPreset,
                          onTap: () async {
                            if (_activeDateEditor != null) {
                              setState(() => _activeDateEditor = null);
                            }
                            final repeatFromCompletionField =
                                widget
                                    .formKey
                                    .currentState
                                    ?.fields[ProjectFieldKeys
                                    .repeatFromCompletion
                                    .id];
                            final seriesEndedField = widget
                                .formKey
                                .currentState
                                ?.fields[ProjectFieldKeys.seriesEnded.id];

                            final result = await _pickRecurrence(
                              anchorContext: context,
                              initialRrule: recurrenceRrule,
                              initialRepeatFromCompletion:
                                  (repeatFromCompletionField?.value as bool?) ??
                                  false,
                              initialSeriesEnded:
                                  (seriesEndedField?.value as bool?) ?? false,
                            );
                            if (!mounted || result == null) return;

                            widget
                                .formKey
                                .currentState
                                ?.fields[ProjectFieldKeys.repeatIcalRrule.id]
                                ?.didChange(result.rrule);
                            repeatFromCompletionField?.didChange(
                              result.repeatFromCompletion,
                            );
                            seriesEndedField?.didChange(
                              result.seriesEnded,
                            );
                            _updateRecurrenceLabel(result.rrule);
                            markDirty();
                            setState(() {});
                          },
                        ),
                        Builder(
                          builder: (chipContext) => TasklyFormInlineChip(
                            label: l10n.priorityLabel,
                            icon: Icons.priority_high_rounded,
                            valueLabel: priorityLabel,
                            hasValue: priority != null,
                            valueColor: priorityColor,
                            showLabelWhenEmpty: false,
                            preset: chipPreset,
                            onTap: () async {
                              if (_activeDateEditor != null) {
                                setState(() => _activeDateEditor = null);
                              }
                              final result = await _pickPriority(
                                anchorContext: chipContext,
                                initialPriority: priority,
                              );
                              if (!mounted || result == null) return;
                              widget
                                  .formKey
                                  .currentState
                                  ?.fields[ProjectFieldKeys.priority.id]
                                  ?.didChange(result.priority);
                              markDirty();
                              setState(() {});
                            },
                          ),
                        ),
                      ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TasklyFormChipRow(chips: chips),
                          if (_activeDateEditor != null) ...[
                            SizedBox(height: sectionGap),
                            InlineDateEditorPanel(
                              label: l10n.dueLabel,
                              icon: Icons.flag_rounded,
                              now: now,
                              selectedDate: deadlineDate,
                              onDateSelected: _setDateForTarget,
                              onClose: () {
                                setState(() => _activeDateEditor = null);
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  SizedBox(height: sectionGap),
                  FormBuilderField<DateTime?>(
                    name: ProjectFieldKeys.startDate.id,
                    builder: (_) => SizedBox.shrink(),
                  ),
                  FormBuilderField<DateTime?>(
                    name: ProjectFieldKeys.deadlineDate.id,
                    builder: (_) => SizedBox.shrink(),
                  ),
                  FormBuilderField<String?>(
                    name: ProjectFieldKeys.repeatIcalRrule.id,
                    builder: (_) => SizedBox.shrink(),
                  ),

                  // Hidden recurrence flags fields (set by the picker)
                  FormBuilderField<bool>(
                    name: ProjectFieldKeys.repeatFromCompletion.id,
                    builder: (_) => SizedBox.shrink(),
                  ),
                  FormBuilderField<bool>(
                    name: ProjectFieldKeys.seriesEnded.id,
                    builder: (_) => SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectNotesField extends StatefulWidget {
  const _ProjectNotesField({
    required this.name,
    required this.initialValue,
    required this.hintText,
    required this.isCompact,
    required this.focusNode,
    required this.contentPadding,
    required this.validator,
  });

  final String name;
  final String initialValue;
  final String hintText;
  final bool isCompact;
  final FocusNode focusNode;
  final EdgeInsets contentPadding;
  final FormFieldValidator<String>? validator;

  @override
  State<_ProjectNotesField> createState() => _ProjectNotesFieldState();
}

class _ProjectNotesFieldState extends State<_ProjectNotesField> {
  late FleatherController _controller;
  final ScrollController _scrollController = ScrollController();
  FormFieldState<String?>? _fieldState;
  bool _isEmpty = true;
  bool _isExpanded = false;
  bool _hasEditorFocus = false;
  bool _syncing = false;
  String? _lastSerialized;

  @override
  void initState() {
    super.initState();
    _controller = FleatherController(
      document: parseParchmentDocument(widget.initialValue),
    );
    _lastSerialized = serializeParchmentDocument(_controller.document);
    _isEmpty = _controller.document.toPlainText().trim().isEmpty;
    _controller.addListener(_handleDocumentChanged);
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _ProjectNotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _replaceDocument(widget.initialValue);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleDocumentChanged);
    _controller.dispose();
    _scrollController.dispose();
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleDocumentChanged() {
    if (_syncing) return;
    final serialized = serializeParchmentDocument(_controller.document);
    if (serialized != _lastSerialized) {
      _lastSerialized = serialized;
      _fieldState?.didChange(serialized);
    }
    final emptyNow = _controller.document.toPlainText().trim().isEmpty;
    if (emptyNow != _isEmpty && mounted) {
      setState(() {
        _isEmpty = emptyNow;
      });
    }
  }

  void _replaceDocument(String? raw) {
    if (raw == _lastSerialized) return;

    _syncing = true;
    _controller.removeListener(_handleDocumentChanged);
    _controller.dispose();
    _controller = FleatherController(
      document: parseParchmentDocument(raw),
    );
    _lastSerialized = serializeParchmentDocument(_controller.document);
    _isEmpty = _controller.document.toPlainText().trim().isEmpty;
    _controller.addListener(_handleDocumentChanged);
    _syncing = false;
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    final hasFocus = widget.focusNode.hasFocus;
    if (hasFocus) {
      if (!_hasEditorFocus) {
        setState(() => _hasEditorFocus = true);
      }
      return;
    }

    if (!_isExpanded) {
      if (_hasEditorFocus) {
        setState(() => _hasEditorFocus = false);
      }
      return;
    }

    setState(() {
      _hasEditorFocus = false;
      _isExpanded = false;
    });
  }

  void _expandEditor() {
    if (!_isExpanded && mounted) {
      setState(() => _isExpanded = true);
    }
  }

  void _collapseEditor() {
    widget.focusNode.unfocus();
    if (_isExpanded && mounted) {
      setState(() => _isExpanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final editorHeight = widget.isCompact ? 160.0 : 200.0;
    final previewText = _controller.document
        .toPlainText()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return FormBuilderField<String?>(
      name: widget.name,
      initialValue: widget.initialValue,
      validator: widget.validator,
      builder: (field) {
        _fieldState = field;
        if (field.value != _lastSerialized) {
          _replaceDocument(field.value);
        }

        final previewLabel = previewText.isEmpty
            ? widget.hintText
            : previewText;

        return PopScope(
          canPop: !_isExpanded,
          onPopInvoked: (didPop) {
            if (didPop || !_isExpanded) return;
            _collapseEditor();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isExpanded)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('project-notes-preview-card'),
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                    onTap: _expandEditor,
                    child: Ink(
                      padding: EdgeInsets.all(tokens.spaceSm),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(tokens.radiusMd),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: tokens.spaceMd2,
                            color: scheme.onSurfaceVariant,
                          ),
                          SizedBox(width: tokens.spaceSm),
                          Expanded(
                            child: Text(
                              previewLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: previewText.isEmpty
                                        ? scheme.onSurfaceVariant
                                        : scheme.onSurface.withValues(
                                            alpha: 0.9,
                                          ),
                                  ),
                            ),
                          ),
                          SizedBox(width: tokens.spaceXs),
                          Icon(
                            Icons.edit_rounded,
                            size: tokens.spaceMd2,
                            color: scheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_isExpanded) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const Key('project-notes-done-button'),
                    onPressed: _collapseEditor,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(context.l10n.doneLabel),
                  ),
                ),
                if (_hasEditorFocus) ...[
                  SizedBox(height: tokens.spaceXs),
                  FleatherToolbar.basic(
                    controller: _controller,
                    hideStrikeThrough: true,
                    hideBackgroundColor: true,
                    hideInlineCode: true,
                    hideIndentation: true,
                    hideCodeBlock: true,
                    hideHorizontalRule: true,
                    hideDirection: true,
                    hideAlignment: true,
                  ),
                ],
                SizedBox(height: tokens.spaceSm),
                TasklyFormNotesContainer(
                  height: editorHeight,
                  child: Stack(
                    children: [
                      FleatherEditor(
                        controller: _controller,
                        focusNode: widget.focusNode,
                        scrollController: _scrollController,
                        padding: widget.contentPadding,
                      ),
                      if (_isEmpty)
                        IgnorePointer(
                          child: Padding(
                            padding: widget.contentPadding,
                            child: Text(
                              widget.hintText,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (field.errorText != null) ...[
                SizedBox(height: tokens.spaceSm),
                Text(
                  field.errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

final class _PrioritySelectionResult {
  const _PrioritySelectionResult({required this.priority});

  final int? priority;
}
