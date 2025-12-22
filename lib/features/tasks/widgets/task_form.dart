import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';

class TaskForm extends StatelessWidget {
  const TaskForm({
    required this.formKey,
    required this.onSubmit,
    required this.submitTooltip,
    this.initialData,
    this.availableProjects = const [],
    this.availableLabels = const [],
    this.defaultProjectId,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final Task? initialData;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final List<Project> availableProjects;
  final List<Label> availableLabels;
  final String? defaultProjectId;

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
      'name': initialData?.name ?? '',
      'description': initialData?.description ?? '',
      'completed': initialData?.completed ?? false,
      'startDate': initialData?.startDate,
      'deadlineDate': initialData?.deadlineDate,
      'projectId': initialData?.projectId ?? defaultProjectId ?? '',
      'labelIds': (initialData?.labels ?? <Label>[])
          .map((Label e) => e.id)
          .toList(),
      'repeatIcalRrule': initialData?.repeatIcalRrule ?? '',
    };

    final labelTypeLabels = availableLabels
        .where((l) => l.type == LabelType.label)
        .toList();
    final labelTypeValues = availableLabels
        .where((l) => l.type == LabelType.value)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            key: const Key('task-form-scroll'),
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
                      decoration: const InputDecoration(
                        hintText: 'Task Name',
                        border: InputBorder.none,
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Name is required',
                        ),
                        FormBuilderValidators.minLength(
                          1,
                          errorText: 'Name must not be empty',
                        ),
                        FormBuilderValidators.maxLength(
                          120,
                          errorText: 'Name must be 120 characters or fewer',
                        ),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderTextField(
                      name: 'description',
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Description',
                        border: InputBorder.none,
                      ),
                      minLines: 2,
                      maxLines: 5,
                      validator: FormBuilderValidators.maxLength(
                        200,
                        errorText: 'Description is too long',
                        checkNullOrEmpty: false,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderDateTimePicker(
                      name: 'startDate',
                      inputType: InputType.date,
                      decoration: const InputDecoration(
                        hintText: 'Start date (optional)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.play_arrow_outlined),
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
                      decoration: const InputDecoration(
                        hintText: 'Deadline date (optional)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.flag_outlined),
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
                            return 'Deadline must be after start date';
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
                      title: const Text('Completed'),
                      initialValue:
                          initialValues['completed'] as bool? ?? false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderDropdown<String>(
                      name: 'projectId',
                      decoration: const InputDecoration(
                        hintText: 'Project (optional)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      initialValue: initialValues['projectId'] as String?,
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: SizedBox.shrink(),
                        ),
                        for (final project in availableProjects)
                          DropdownMenuItem(
                            value: project.id,
                            child: Text(project.name),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: FormBuilderField<List<String>>(
                      name: 'labelIds',
                      initialValue: initialValues['labelIds'] as List<String>?,
                      builder: (field) {
                        final selected = List<String>.from(
                          field.value ?? const <String>[],
                        );

                        void toggle(String id, bool isSelected) {
                          final updated = List<String>.from(selected);
                          if (isSelected) {
                            if (!updated.contains(id)) {
                              updated.add(id);
                            }
                          } else {
                            updated.remove(id);
                          }
                          field.didChange(updated);
                        }

                        Widget buildSection(
                          String heading,
                          List<Label> items,
                        ) {
                          if (items.isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                heading,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final label in items)
                                    FilterChip(
                                      selected: selected.contains(label.id),
                                      avatar: Icon(
                                        Icons.label_outline,
                                        size: 16,
                                        color: _colorFromHexOrFallback(
                                          label.color,
                                        ),
                                      ),
                                      label: Text(label.name),
                                      onSelected: (isSelected) =>
                                          toggle(label.id, isSelected),
                                    ),
                                ],
                              ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildSection(
                              l10n.labelTypeValueHeading,
                              labelTypeValues,
                            ),
                            const SizedBox(height: 16),
                            buildSection(
                              l10n.labelTypeLabelHeading,
                              labelTypeLabels,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FormBuilderTextField(
                      name: 'repeatIcalRrule',
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Repeat rule (RRULE, optional)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      validator: FormBuilderValidators.maxLength(
                        255,
                        errorText: 'Repeat rule is too long',
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
