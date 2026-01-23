import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
// import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_tag_picker.dart'; // Removed
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/widgets/form_date_chip.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';
import 'package:taskly_bloc/presentation/widgets/rrule_form_recurrence_chip.dart';
import 'package:taskly_bloc/presentation/widgets/values_alignment/values_alignment_sheet.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';

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
    this.onDelete,
    this.onTogglePinned,
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
  final VoidCallback? onDelete;

  /// Called when the user toggles pinned state from the header.
  ///
  /// Only shown when editing (initialData != null).
  final ValueChanged<bool>? onTogglePinned;

  /// Called when the user wants to close the form.
  /// If null, no close button is shown.
  final VoidCallback? onClose;

  /// Optional action widgets to render in the header row (right side).
  final List<Widget> trailingActions;

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> with FormDirtyStateMixin {
  @override
  VoidCallback? get onClose => widget.onClose;

  final _scrollController = ScrollController();
  final GlobalKey<State<StatefulWidget>> _valuesKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _plannedKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _dueKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _priorityKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _recurrenceKey = GlobalKey();
  bool _didAutoOpen = false;

  @override
  void initState() {
    super.initState();

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
      );
      if (!mounted || result == null) return;

      widget.formKey.currentState?.fields[ProjectFieldKeys.valueIds.id]
          ?.didChange(result);
      markDirty();
      setState(() {});
    });
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
              delegate: _AnchoredDialogLayoutDelegate(
                anchor: anchor,
                margin: const EdgeInsets.all(8),
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: Material(
                elevation: 6,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
  }) {
    if (_isCompact(context)) {
      return showValuesAlignmentSheetForProject(
        context,
        availableValues: widget.availableValues,
        valueIds: valueIds,
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
        ),
      ),
    );
  }

  Future<_NullableDateDecision?> _pickDate({
    required BuildContext anchorContext,
    required String title,
    required DateTime? initialDate,
  }) {
    if (_isCompact(context)) {
      return showModalBottomSheet<_NullableDateDecision>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => _ProjectDatePickerPanel(
          title: title,
          initialDate: initialDate,
        ),
      );
    }

    return _showAnchoredDialog<_NullableDateDecision>(
      context,
      anchorContext: anchorContext,
      maxWidth: 360,
      maxHeight: 520,
      builder: (dialogContext) => _ProjectDatePickerPanel(
        title: title,
        initialDate: initialDate,
      ),
    );
  }

  Future<_NullableIntDecision?> _pickPriority({
    required BuildContext anchorContext,
    required int? current,
  }) {
    if (_isCompact(context)) {
      return showModalBottomSheet<_NullableIntDecision>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) => _PriorityPickerPanel(current: current),
      );
    }

    return _showAnchoredDialog<_NullableIntDecision>(
      context,
      anchorContext: anchorContext,
      maxWidth: 320,
      maxHeight: 420,
      builder: (dialogContext) => _PriorityPickerPanel(current: current),
    );
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
        showDragHandle: true,
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = _isCompact(context);
    final isCreating = widget.initialData == null;

    final availableValuesById = <String, Value>{
      for (final v in widget.availableValues) v.id: v,
    };

    final initialValues = <String, dynamic>{
      ProjectFieldKeys.name.id: widget.initialData?.name.trim() ?? '',
      ProjectFieldKeys.description.id: widget.initialData?.description ?? '',
      ProjectFieldKeys.completed.id: widget.initialData?.completed ?? false,
      ProjectFieldKeys.startDate.id: widget.initialData?.startDate,
      ProjectFieldKeys.deadlineDate.id: widget.initialData?.deadlineDate,
      ProjectFieldKeys.priority.id: widget.initialData?.priority,
      ProjectFieldKeys.valueIds.id:
          (widget.initialData?.values ?? <Value>[]) // Use values property
              .map((Value e) => e.id)
              .toList(growable: false),
      ProjectFieldKeys.repeatIcalRrule.id:
          widget.initialData?.repeatIcalRrule ?? '',
      ProjectFieldKeys.repeatFromCompletion.id:
          widget.initialData?.repeatFromCompletion ?? false,
      ProjectFieldKeys.seriesEnded.id: widget.initialData?.seriesEnded ?? false,
    };

    final effectiveStartDate =
        (widget
                .formKey
                .currentState
                ?.fields[ProjectFieldKeys.startDate.id]
                ?.value
            as DateTime?) ??
        (initialValues[ProjectFieldKeys.startDate.id] as DateTime?);
    final effectiveDeadlineDate =
        (widget
                .formKey
                .currentState
                ?.fields[ProjectFieldKeys.deadlineDate.id]
                ?.value
            as DateTime?) ??
        (initialValues[ProjectFieldKeys.deadlineDate.id] as DateTime?);
    final showScheduleHelper =
        effectiveStartDate == null && effectiveDeadlineDate == null;

    final submitEnabled =
        isDirty && (widget.formKey.currentState?.isValid ?? false);

    final denseFieldPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 12 : 16,
      vertical: isCompact ? 10 : 12,
    );

    return FormShell(
      onSubmit: widget.onSubmit,
      submitTooltip: isCreating ? l10n.actionCreate : l10n.actionUpdate,
      submitIcon: isCreating ? Icons.add : Icons.check,
      submitEnabled: submitEnabled,
      showHeaderSubmit: true,
      showFooterSubmit: false,
      closeOnLeft: true,
      onDelete: widget.initialData != null ? widget.onDelete : null,
      deleteTooltip: l10n.deleteProjectAction,
      onClose: widget.onClose != null ? handleClose : null,
      closeTooltip: l10n.closeLabel,
      scrollController: _scrollController,
      leadingActions: [
        if (widget.initialData != null && widget.onTogglePinned != null)
          IconButton(
            onPressed: () {
              final nextPinned = !(widget.initialData?.isPinned ?? false);
              widget.onTogglePinned?.call(nextPinned);
            },
            icon: Icon(
              (widget.initialData?.isPinned ?? false)
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
              color: (widget.initialData?.isPinned ?? false)
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            tooltip: (widget.initialData?.isPinned ?? false)
                ? l10n.unpinAction
                : l10n.pinAction,
          ),
      ],
      trailingActions: widget.trailingActions,
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
              // Project Name
              FormBuilderTextField(
                name: ProjectFieldKeys.name.id,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  hintText: l10n.projectFormTitleHint,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
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
                    errorText: l10n.projectFormTitleRequired,
                  ),
                  FormBuilderValidators.minLength(
                    1,
                    errorText: l10n.projectFormTitleEmpty,
                  ),
                  FormBuilderValidators.maxLength(
                    120,
                    errorText: l10n.projectFormTitleTooLong,
                  ),
                ]),
              ),

              // Project Description
              FormBuilderTextField(
                name: ProjectFieldKeys.description.id,
                textInputAction: TextInputAction.newline,
                maxLines: isCompact ? 2 : 3,
                minLines: isCompact ? 1 : 2,
                decoration: InputDecoration(
                  hintText: l10n.projectFormDescriptionHint,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
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
                validator: FormBuilderValidators.maxLength(
                  200,
                  errorText: l10n.projectFormDescriptionTooLong,
                  checkNullOrEmpty: false,
                ),
              ),

              SizedBox(height: isCompact ? 6 : 8),

              // Completed
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderField<bool>(
                  name: ProjectFieldKeys.completed.id,
                  builder: (field) {
                    return CheckboxListTile.adaptive(
                      value: field.value ?? false,
                      onChanged: (value) {
                        field.didChange(value);
                        markDirty();
                      },
                      title: Text(l10n.projectCompletedLabel),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),

              // Meta chips row (values-first): Values, Planned Day, Due Date,
              // Priority, Repeat
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FormBuilderField<List<String>>(
                          name: ProjectFieldKeys.valueIds.id,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.projectFormValuesRequired;
                            }
                            return null;
                          },
                          builder: (field) {
                            final valueIds = List<String>.of(
                              field.value ?? const <String>[],
                            );
                            final effectiveIds = valueIds
                                .take(2)
                                .toList(
                                  growable: false,
                                );
                            final primary = effectiveIds.isEmpty
                                ? null
                                : availableValuesById[effectiveIds.first];
                            final secondary = effectiveIds.length < 2
                                ? null
                                : availableValuesById[effectiveIds[1]];

                            return Builder(
                              builder: (chipContext) {
                                Future<void> open() async {
                                  final result =
                                      await _showValuesAlignmentPicker(
                                        anchorContext: chipContext,
                                        valueIds: valueIds,
                                      );
                                  if (!mounted || result == null) return;
                                  field.didChange(result);
                                  markDirty();
                                  setState(() {});
                                }

                                return KeyedSubtree(
                                  key: _valuesKey,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _PrimaryValueChip(
                                        value: primary,
                                        onTap: open,
                                      ),
                                      if (secondary != null) ...[
                                        const SizedBox(width: 8),
                                        _SecondaryValueChip(
                                          value: secondary,
                                          onTap: open,
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        FormBuilderField<DateTime?>(
                          name: ProjectFieldKeys.startDate.id,
                          builder: (field) {
                            return KeyedSubtree(
                              key: _plannedKey,
                              child: Builder(
                                builder: (chipContext) =>
                                    FormDateChip.startDate(
                                      label: l10n.dateChipAddPlannedDay,
                                      date: field.value,
                                      onTap: () async {
                                        final decision = await _pickDate(
                                          anchorContext: chipContext,
                                          title: l10n.dateChipAddPlannedDay,
                                          initialDate: field.value,
                                        );
                                        if (!mounted || decision == null) {
                                          return;
                                        }
                                        if (decision.keep) return;
                                        field.didChange(decision.date);
                                        markDirty();
                                        setState(() {});
                                      },
                                      onClear: field.value != null
                                          ? () {
                                              field.didChange(null);
                                              markDirty();
                                              setState(() {});
                                            }
                                          : null,
                                    ),
                              ),
                            );
                          },
                        ),

                        FormBuilderField<DateTime?>(
                          name: ProjectFieldKeys.deadlineDate.id,
                          builder: (field) {
                            return KeyedSubtree(
                              key: _dueKey,
                              child: Builder(
                                builder: (chipContext) => FormDateChip.deadline(
                                  label: l10n.dateChipAddDueDate,
                                  date: field.value,
                                  onTap: () async {
                                    final decision = await _pickDate(
                                      anchorContext: chipContext,
                                      title: l10n.dateChipAddDueDate,
                                      initialDate: field.value,
                                    );
                                    if (!mounted || decision == null) {
                                      return;
                                    }
                                    if (decision.keep) return;
                                    field.didChange(decision.date);
                                    markDirty();
                                    setState(() {});
                                  },
                                  onClear: field.value != null
                                      ? () {
                                          field.didChange(null);
                                          markDirty();
                                          setState(() {});
                                        }
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),

                        FormBuilderField<int?>(
                          name: ProjectFieldKeys.priority.id,
                          builder: (field) {
                            return KeyedSubtree(
                              key: _priorityKey,
                              child: Builder(
                                builder: (chipContext) => _PriorityChip(
                                  priority: field.value,
                                  onTap: () async {
                                    final decision = await _pickPriority(
                                      anchorContext: chipContext,
                                      current: field.value,
                                    );
                                    if (!mounted || decision == null) return;
                                    if (decision.keep) return;
                                    field.didChange(decision.value);
                                    markDirty();
                                    setState(() {});
                                  },
                                  onClear: field.value != null
                                      ? () {
                                          field.didChange(null);
                                          markDirty();
                                          setState(() {});
                                        }
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),

                        FormBuilderField<String?>(
                          name: ProjectFieldKeys.repeatIcalRrule.id,
                          builder: (field) {
                            final rrule = field.value?.isEmpty ?? true
                                ? null
                                : field.value;

                            return KeyedSubtree(
                              key: _recurrenceKey,
                              child: Builder(
                                builder: (chipContext) =>
                                    RruleFormRecurrenceChip(
                                      rrule: rrule,
                                      emptyLabel: l10n.recurrenceRepeatTitle,
                                      onTap: () async {
                                        final repeatFromCompletionField =
                                            widget
                                                .formKey
                                                .currentState
                                                ?.fields[ProjectFieldKeys
                                                .repeatFromCompletion
                                                .id];
                                        final seriesEndedField =
                                            widget
                                                .formKey
                                                .currentState
                                                ?.fields[ProjectFieldKeys
                                                .seriesEnded
                                                .id];

                                        final result = await _pickRecurrence(
                                          anchorContext: chipContext,
                                          initialRrule:
                                              field.value?.isEmpty ?? true
                                              ? null
                                              : field.value,
                                          initialRepeatFromCompletion:
                                              (repeatFromCompletionField?.value
                                                  as bool?) ??
                                              false,
                                          initialSeriesEnded:
                                              (seriesEndedField?.value
                                                  as bool?) ??
                                              false,
                                        );
                                        if (!mounted || result == null) return;

                                        field.didChange(result.rrule);
                                        repeatFromCompletionField?.didChange(
                                          result.repeatFromCompletion,
                                        );
                                        seriesEndedField?.didChange(
                                          result.seriesEnded,
                                        );
                                        markDirty();
                                        setState(() {});
                                      },
                                      onClear: field.value?.isNotEmpty ?? false
                                          ? () {
                                              field.didChange(null);
                                              widget
                                                  .formKey
                                                  .currentState
                                                  ?.fields[ProjectFieldKeys
                                                      .repeatFromCompletion
                                                      .id]
                                                  ?.didChange(false);
                                              widget
                                                  .formKey
                                                  .currentState
                                                  ?.fields[ProjectFieldKeys
                                                      .seriesEnded
                                                      .id]
                                                  ?.didChange(false);
                                              markDirty();
                                              setState(() {});
                                            }
                                          : null,
                                    ),
                              ),
                            );
                          },
                        ),

                        // Hidden recurrence flags fields (set by the picker)
                        FormBuilderField<bool>(
                          name: ProjectFieldKeys.repeatFromCompletion.id,
                          builder: (_) => const SizedBox.shrink(),
                        ),
                        FormBuilderField<bool>(
                          name: ProjectFieldKeys.seriesEnded.id,
                          builder: (_) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    Builder(
                      builder: (context) {
                        final errorText = widget
                            .formKey
                            .currentState
                            ?.fields[ProjectFieldKeys.valueIds.id]
                            ?.errorText;
                        if (errorText == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
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
                  ],
                ),
              ),

              if (showScheduleHelper)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                  child: Text(
                    l10n.scheduleHelperText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

final class _NullableDateDecision {
  const _NullableDateDecision.keep() : keep = true, date = null;

  const _NullableDateDecision.set(this.date) : keep = false;

  final bool keep;
  final DateTime? date;
}

final class _NullableIntDecision {
  const _NullableIntDecision.keep() : keep = true, value = null;

  const _NullableIntDecision.set(this.value) : keep = false;

  final bool keep;
  final int? value;
}

class _AnchoredDialogLayoutDelegate extends SingleChildLayoutDelegate {
  _AnchoredDialogLayoutDelegate({
    required this.anchor,
    required this.margin,
    required this.maxWidth,
    required this.maxHeight,
  });

  final Rect anchor;
  final EdgeInsets margin;
  final double maxWidth;
  final double maxHeight;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxW = (constraints.maxWidth - margin.horizontal).clamp(
      0.0,
      maxWidth,
    );
    final maxH = (constraints.maxHeight - margin.vertical).clamp(
      0.0,
      maxHeight,
    );
    return BoxConstraints(
      maxWidth: maxW,
      maxHeight: maxH,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final availableBelow = size.height - anchor.bottom - margin.bottom;
    final availableAbove = anchor.top - margin.top;

    final showBelow =
        availableBelow >= childSize.height || availableBelow >= availableAbove;

    final y = showBelow
        ? (anchor.bottom + 6).clamp(margin.top, size.height - margin.bottom)
        : (anchor.top - childSize.height - 6).clamp(
            margin.top,
            size.height - margin.bottom,
          );

    final desiredX = anchor.left;
    final x = desiredX.clamp(
      margin.left,
      size.width - margin.right - childSize.width,
    );

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant _AnchoredDialogLayoutDelegate oldDelegate) {
    return anchor != oldDelegate.anchor ||
        margin != oldDelegate.margin ||
        maxWidth != oldDelegate.maxWidth ||
        maxHeight != oldDelegate.maxHeight;
  }
}

class _ProjectDatePickerPanel extends StatefulWidget {
  const _ProjectDatePickerPanel({
    required this.title,
    required this.initialDate,
  });

  final String title;
  final DateTime? initialDate;

  @override
  State<_ProjectDatePickerPanel> createState() =>
      _ProjectDatePickerPanelState();
}

class _ProjectDatePickerPanelState extends State<_ProjectDatePickerPanel> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = getIt<NowService>().nowLocal();
    _selected = widget.initialDate ?? now;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final now = getIt<NowService>().nowLocal();
    final today = dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickPickChip(
                label: l10n.dateToday,
                onTap: () => Navigator.of(context).pop(
                  _NullableDateDecision.set(today),
                ),
              ),
              _QuickPickChip(
                label: l10n.dateTomorrow,
                onTap: () => Navigator.of(context).pop(
                  _NullableDateDecision.set(tomorrow),
                ),
              ),
              _QuickPickChip(
                label: l10n.dateNextWeek,
                onTap: () => Navigator.of(context).pop(
                  _NullableDateDecision.set(nextWeek),
                ),
              ),
              _QuickPickChip(
                label: l10n.sortFieldNoneLabel,
                emphasized: true,
                onTap: () => Navigator.of(context).pop(
                  const _NullableDateDecision.set(null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: CalendarDatePicker(
              initialDate: _selected,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              onDateChanged: (date) {
                setState(() => _selected = date);
                Navigator.of(context).pop(
                  _NullableDateDecision.set(dateOnly(date)),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              const _NullableDateDecision.keep(),
            ),
            child: Text(l10n.cancelLabel),
          ),
        ],
      ),
    );
  }
}

class _QuickPickChip extends StatelessWidget {
  const _QuickPickChip({
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = emphasized
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLow;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: emphasized ? FontWeight.w700 : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityPickerPanel extends StatelessWidget {
  const _PriorityPickerPanel({required this.current});

  final int? current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    Widget item({
      required String label,
      required int? value,
      required bool emphasized,
    }) {
      final selected = current == value;
      return ListTile(
        title: Text(label),
        leading: Icon(
          emphasized ? Icons.flag_rounded : Icons.flag_outlined,
          color: emphasized
              ? scheme.primary
              : scheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        trailing: selected ? const Icon(Icons.check) : null,
        onTap: () => Navigator.of(context).pop(
          _NullableIntDecision.set(selected ? null : value),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.priorityLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        item(label: 'P1', value: 1, emphasized: true),
        item(label: 'P2', value: 2, emphasized: true),
        item(label: 'P3', value: 3, emphasized: false),
        item(label: 'P4', value: 4, emphasized: false),
        const Divider(height: 1),
        ListTile(
          title: Text(l10n.cancelLabel),
          onTap: () =>
              Navigator.of(context).pop(const _NullableIntDecision.keep()),
        ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.priority,
    required this.onTap,
    this.onClear,
  });

  final int? priority;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final label = priority == null ? l10n.priorityLabel : 'P$priority';

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.only(
            left: 10,
            right: onClear != null && priority != null ? 4 : 10,
            top: 6,
            bottom: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                priority == null ? Icons.flag_outlined : Icons.flag_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: priority != null ? FontWeight.w600 : null,
                ),
              ),
              if (onClear != null && priority != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  tooltip: l10n.clearLabel,
                  onPressed: onClear,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryValueChip extends StatelessWidget {
  const _PrimaryValueChip({required this.value, required this.onTap});

  final Value? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (value == null) {
      return Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_outline,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.valuesAlignedToTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final valueColor = ColorUtils.fromHexWithThemeFallback(
      context,
      value!.color,
    );
    final bg = valueColor.withValues(alpha: 0.18);
    final fg = valueColor.withValues(alpha: 0.95);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SmallValueIcon(value: value!),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  value!.name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
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

class _SecondaryValueChip extends StatelessWidget {
  const _SecondaryValueChip({required this.value, required this.onTap});

  final Value value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueColor = ColorUtils.fromHexWithThemeFallback(
      context,
      value.color,
    );

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SmallValueIcon(value: value),
              const SizedBox(width: 6),
              Icon(
                Icons.circle_outlined,
                size: 10,
                color: valueColor.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallValueIcon extends StatelessWidget {
  const _SmallValueIcon({required this.value});

  final Value value;

  @override
  Widget build(BuildContext context) {
    final iconData = getIconDataFromName(value.iconName) ?? Icons.star;
    final valueColor = ColorUtils.fromHexWithThemeFallback(
      context,
      value.color,
    );
    final color = valueColor.withValues(alpha: 0.95);

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1.25),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: 12,
          color: color,
          semanticLabel: value.name,
        ),
      ),
    );
  }
}
