import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';

class AddTaskFab extends StatelessWidget {
  const AddTaskFab({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: context.l10n.createTaskTooltip,
      onPressed: onPressed,
      heroTag: 'create_task_fab',
      child: const Icon(Icons.add),
    );
  }
}
