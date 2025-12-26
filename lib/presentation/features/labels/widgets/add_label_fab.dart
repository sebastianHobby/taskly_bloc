import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/labels/view/label_detail_view.dart';

/// A FAB that opens a label/value creation modal sheet.
///
/// Encapsulates all modal handling internally, consistent with
/// `AddTaskFab` and `AddProjectFab`.
///
/// Unlike the Task and Project FABs, this FAB supports both Label and Value
/// creation through the [initialType] parameter, requiring explicit [tooltip]
/// and [heroTag] values.
class AddLabelFab extends StatelessWidget {
  const AddLabelFab({
    required this.labelRepository,
    required this.initialType,
    required this.lockType,
    required this.tooltip,
    required this.heroTag,
    super.key,
  });

  final LabelRepositoryContract labelRepository;
  final LabelType initialType;
  final bool lockType;
  final String tooltip;
  final String heroTag;

  @override
  Widget build(BuildContext fabContext) {
    return FloatingActionButton(
      tooltip: tooltip,
      onPressed: () async {
        await showDetailModal<void>(
          context: fabContext,
          childBuilder: (modalSheetContext) => LabelDetailSheetPage(
            labelRepository: labelRepository,
            initialType: initialType,
            lockType: lockType,
          ),
        );
      },
      heroTag: heroTag,
      child: const Icon(Icons.add),
    );
  }
}
