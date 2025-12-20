import 'package:flutter/material.dart';

class AddTaskFab extends StatelessWidget {
  const AddTaskFab({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'Create task',
      onPressed: onPressed,
      heroTag: 'create_task_fab',
      child: const Icon(Icons.add),
    );
  }
}
