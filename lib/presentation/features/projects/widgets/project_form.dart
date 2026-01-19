import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_priority_picker.dart';
// import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_tag_picker.dart'; // Removed
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/widgets/form_date_chip.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';
import 'package:taskly_bloc/presentation/widgets/rrule_form_recurrence_chip.dart';
import 'package:taskly_bloc/presentation/widgets/values_alignment/values_alignment_sheet.dart';
import 'package:taskly_domain/core.dart';
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
      }
      if (!mounted) return;

      final current = widget
          .formKey
          .currentState
          ?.fields[ProjectFieldKeys.valueIds.id]
          ?.value;
      final valueIds = List<String>.of(current as List<String>? ?? const []);

      final result = await showValuesAlignmentSheetForProject(
        context,
        availableValues: widget.availableValues,
        valueIds: valueIds,
      );
      if (!mounted || result == null) return;

      widget.formKey.currentState?.fields[ProjectFieldKeys.valueIds.id]
          ?.didChange(result);
      markDirty();
      setState(() {});
    });
  }

  Future<void> _showDatePicker(
    BuildContext context,
    DateTime? initialDate,
    ValueChanged<DateTime?> onDateSelected,
  ) async {
    final now = getIt<NowService>().nowLocal();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateSelected(picked);
      markDirty();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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

    return FormShell(
      onSubmit: widget.onSubmit,
      submitTooltip: isCreating ? l10n.actionCreate : l10n.actionUpdate,
      submitIcon: isCreating ? Icons.add : Icons.check,
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
        padding: const EdgeInsets.only(bottom: 24),
        child: FormBuilder(
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
                maxLines: 3,
                minLines: 2,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: FormBuilderValidators.maxLength(
                  200,
                  errorText: l10n.projectFormDescriptionTooLong,
                  checkNullOrEmpty: false,
                ),
              ),

              const SizedBox(height: 8),

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

              // Date chips row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Start Date chip
                    FormBuilderField<DateTime?>(
                      name: ProjectFieldKeys.startDate.id,
                      builder: (field) {
                        return FormDateChip.startDate(
                          date: field.value,
                          onTap: () => _showDatePicker(
                            context,
                            field.value,
                            (date) => field.didChange(date),
                          ),
                          onClear: field.value != null
                              ? () => field.didChange(null)
                              : null,
                        );
                      },
                    ),
                    // Deadline Date chip
                    FormBuilderField<DateTime?>(
                      name: ProjectFieldKeys.deadlineDate.id,
                      builder: (field) {
                        return FormDateChip.deadline(
                          date: field.value,
                          onTap: () => _showDatePicker(
                            context,
                            field.value,
                            (date) => field.didChange(date),
                          ),
                          onClear: field.value != null
                              ? () => field.didChange(null)
                              : null,
                        );
                      },
                    ),
                    // Recurrence chip
                    FormBuilderField<String?>(
                      name: ProjectFieldKeys.repeatIcalRrule.id,
                      builder: (field) {
                        final rrule = field.value?.isEmpty ?? true
                            ? null
                            : field.value;

                        return RruleFormRecurrenceChip(
                          rrule: rrule,
                          emptyLabel: context.l10n.recurrenceRepeatTitle,
                          onTap: () async {
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

                            final result =
                                await showDialog<RecurrencePickerResult>(
                                  context: context,
                                  builder: (context) => Dialog(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 500,
                                        maxHeight: 600,
                                      ),
                                      child: RecurrencePicker(
                                        initialRRule:
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
                                      ),
                                    ),
                                  ),
                                );
                            if (result != null) {
                              field.didChange(result.rrule);
                              repeatFromCompletionField?.didChange(
                                result.repeatFromCompletion,
                              );
                              seriesEndedField?.didChange(
                                result.seriesEnded,
                              );
                              markDirty();
                            }
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
                                      ?.fields[ProjectFieldKeys.seriesEnded.id]
                                      ?.didChange(false);
                                  markDirty();
                                }
                              : null,
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
              ),
              const SizedBox(height: 16),

              // Priority
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderPriorityPicker(
                  name: ProjectFieldKeys.priority.id,
                ),
              ),

              const SizedBox(height: 16),

              // Values
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderField<List<String>>(
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
                    final primaryId = valueIds.isEmpty ? null : valueIds.first;
                    final primaryName = primaryId == null
                        ? null
                        : availableValuesById[primaryId]?.name;

                    final summary = primaryName == null
                        ? l10n.valuesNoneSelected
                        : valueIds.length <= 1
                        ? primaryName
                        : '$primaryName + ${valueIds.length - 1}';

                    return KeyedSubtree(
                      key: _valuesKey,
                      child: Card(
                        elevation: 0,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        child: ListTile(
                          title: Text(l10n.projectFormValuesLabel),
                          subtitle: Text(
                            summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: const Icon(Icons.star_border),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final result =
                                await showValuesAlignmentSheetForProject(
                                  context,
                                  availableValues: widget.availableValues,
                                  valueIds: valueIds,
                                );
                            if (result != null) {
                              field.didChange(result);
                              markDirty();
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
