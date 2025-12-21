import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/domain.dart';

class ProjectForm extends StatelessWidget {
  const ProjectForm({
    required this.formKey,
    required this.initialData,
    required this.onSubmit,
    required this.submitTooltip,
    this.availableLabels = const <Label>[],
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final Project? initialData;
  final List<Label> availableLabels;

  Color _colorFromHexOrFallback(String? hex) {
    final normalized = (hex ?? '').replaceAll('#', '');
    if (normalized.length != 6) return Colors.black;
    final value = int.tryParse('FF$normalized', radix: 16);
    if (value == null) return Colors.black;
    return Color(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Map<String, dynamic> initialValues = {
      'name': initialData?.name.trim() ?? '',
      'description': initialData?.description ?? '',
      'completed': initialData?.completed ?? false,
      'startDate': initialData?.startDate,
      'deadlineDate': initialData?.deadlineDate,
      'labelIds': (initialData?.labels ?? <Label>[])
          .map((Label e) => e.id)
          .toList(growable: false),
      'repeatIcalRrule': initialData?.repeatIcalRrule ?? '',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: FormBuilder(
              key: formKey,
              initialValue: initialValues,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderTextField(
                      name: 'name',
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: l10n.projectFormTitleHint,
                        border: InputBorder.none,
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
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderTextField(
                      name: 'description',
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: l10n.projectFormDescriptionHint,
                        border: InputBorder.none,
                      ),
                      minLines: 2,
                      maxLines: 5,
                      validator: FormBuilderValidators.maxLength(
                        200,
                        errorText: l10n.projectFormDescriptionTooLong,
                        checkNullOrEmpty: false,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderDateTimePicker(
                      name: 'startDate',
                      inputType: InputType.date,
                      decoration: InputDecoration(
                        hintText: l10n.projectFormStartDateHint,
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.play_arrow_outlined),
                      ),
                      initialValue: dateOnlyOrNull(
                        initialValues['startDate'] as DateTime?,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderDateTimePicker(
                      name: 'deadlineDate',
                      inputType: InputType.date,
                      decoration: InputDecoration(
                        hintText: l10n.projectFormDeadlineDateHint,
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.flag_outlined),
                      ),
                      initialValue: dateOnlyOrNull(
                        initialValues['deadlineDate'] as DateTime?,
                      ),
                      validator: (valueCandidate) {
                        final start =
                            formKey.currentState?.fields['startDate']?.value
                                as DateTime?;
                        if (valueCandidate != null && start != null) {
                          if (dateOnly(
                            valueCandidate,
                          ).isBefore(dateOnly(start))) {
                            return l10n.projectFormDeadlineAfterStartError;
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderCheckbox(
                      name: 'completed',
                      title: Text(l10n.projectFormCompletedLabel),
                      initialValue:
                          initialValues['completed'] as bool? ?? false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: FormBuilderFilterChips<String>(
                      name: 'labelIds',
                      initialValue: initialValues['labelIds'] as List<String>?,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: l10n.projectFormLabelsLabel,
                      ),
                      options: availableLabels
                          .map(
                            (l) => FormBuilderChipOption(
                              value: l.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.label_outline,
                                    size: 16,
                                    color: _colorFromHexOrFallback(l.color),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(l.name),
                                ],
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderTextField(
                      name: 'repeatIcalRrule',
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: l10n.projectFormRepeatRuleHint,
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.repeat),
                      ),
                      validator: FormBuilderValidators.maxLength(
                        255,
                        errorText: l10n.projectFormRepeatRuleTooLong,
                        checkNullOrEmpty: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: submitTooltip,
                  onPressed: onSubmit,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
