import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/widgets/entity_header.dart';

class EntityHeaderSectionRenderer extends StatelessWidget {
  const EntityHeaderSectionRenderer({
    required this.data,
    super.key,
    this.onProjectCheckboxChanged,
  });

  final SectionDataResult data;
  final void Function(bool? value)? onProjectCheckboxChanged;

  @override
  Widget build(BuildContext context) {
    return switch (data) {
      EntityHeaderProjectSectionResult(:final project, :final showCheckbox) =>
        EntityHeader.project(
          project: project,
          showCheckbox: showCheckbox,
          onCheckboxChanged: onProjectCheckboxChanged,
        ),
      EntityHeaderValueSectionResult(:final value, :final taskCount) =>
        EntityHeader.value(value: value, taskCount: taskCount),
      EntityHeaderMissingSectionResult(:final entityType) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Missing $entityType'),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
