import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';

import 'package:taskly_bloc/presentation/features/screens/renderers/allocation_section_renderer.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/task_list_renderer.dart';

/// Widget that renders a section from ScreenBloc state.
///
/// Handles different section types (data, allocation, agenda) and
/// displays appropriate UI for each.
class SectionWidget extends StatefulWidget {
  /// Creates a SectionWidget.
  const SectionWidget({
    required this.section,
    super.key,
    this.displayConfig,
    this.persona,
    this.onEntityTap,
    this.onTaskComplete,
    this.onTaskCheckboxChanged,
    this.onProjectCheckboxChanged,
    this.onTaskDelete,
    this.onProjectDelete,
  });

  /// The section data to render
  final SectionDataWithMeta section;

  /// Optional display configuration override
  final DisplayConfig? displayConfig;

  /// Current persona (for allocation sections)
  final AllocationPersona? persona;

  /// Callback when an entity is tapped
  final void Function(dynamic entity)? onEntityTap;

  /// Callback when a task is completed (legacy)
  final void Function(Task task)? onTaskComplete;

  /// Callback when a task checkbox is changed
  final void Function(Task task, bool? value)? onTaskCheckboxChanged;

  /// Callback when a project checkbox is changed
  final void Function(Project project, bool? value)? onProjectCheckboxChanged;

  /// Callback when a task is deleted
  final void Function(Task task)? onTaskDelete;

  /// Callback when a project is deleted
  final void Function(Project project)? onProjectDelete;

  @override
  State<SectionWidget> createState() => _SectionWidgetState();
}

class _SectionWidgetState extends State<SectionWidget> {
  @override
  Widget build(BuildContext context) {
    final result = widget.section.result;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: switch (result) {
        final AllocationSectionResult d => AllocationSectionRenderer(
          data: d,
          onTaskToggle: (taskId, val) {
            final task = d.allocatedTasks.firstWhere((t) => t.id == taskId);
            widget.onTaskCheckboxChanged?.call(task, val);
          },
        ),
        final DataSectionResult d when d.primaryEntityType == 'task' =>
          TaskListRenderer(
            data: d,
            title: widget.section.title,
            onTaskToggle: (taskId, val) {
              final task = d.primaryEntities.whereType<Task>().firstWhere(
                (t) => t.id == taskId,
              );
              widget.onTaskCheckboxChanged?.call(task, val);
            },
          ),
        // Fallback for other types (Project lists, Agenda, etc.) - Keep existing logic or placeholder
        _ => _buildLegacySection(result),
      },
    );
  }

  Widget _buildLegacySection(SectionDataResult result) {
    // TODO: Port other renderers
    return Text(
      'Unsupported section type: ',
      style: const TextStyle(color: Colors.white),
    );
  }
}
