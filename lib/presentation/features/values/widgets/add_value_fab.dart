import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_detail_view.dart';

/// A FAB that opens a value creation modal sheet.
///
/// Encapsulates all modal handling internally, consistent with
/// `AddTaskFab` and `AddProjectFab`.
class AddValueFab extends StatelessWidget {
  const AddValueFab({
    required this.valueRepository,
    required this.tooltip,
    required this.heroTag,
    super.key,
  });

  final ValueRepositoryContract valueRepository;
  final String tooltip;
  final String heroTag;

  @override
  Widget build(BuildContext fabContext) {
    return FloatingActionButton(
      tooltip: tooltip,
      onPressed: () async {
        await showDetailModal<void>(
          context: fabContext,
          childBuilder: (modalSheetContext) => ValueDetailSheetPage(
            valueRepository: valueRepository,
          ),
        );
      },
      heroTag: heroTag,
      child: const Icon(Icons.add),
    );
  }
}
