import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

enum AddEntityAction {
  task,
  project,
}

class EntityAddMenuButton extends StatelessWidget {
  const EntityAddMenuButton({
    required this.onCreateTask,
    required this.onCreateProject,
    super.key,
  });

  final VoidCallback onCreateTask;
  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopupMenuButton<AddEntityAction>(
      tooltip: 'Add',
      icon: const Icon(Icons.add),
      onSelected: (action) {
        switch (action) {
          case AddEntityAction.task:
            onCreateTask();
          case AddEntityAction.project:
            onCreateProject();
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<AddEntityAction>>[
        PopupMenuItem(
          value: AddEntityAction.task,
          child: ListTile(
            leading: const Icon(Icons.check_box_outlined),
            title: Text(l10n.addTaskAction),
          ),
        ),
        PopupMenuItem(
          value: AddEntityAction.project,
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(l10n.addProjectAction),
          ),
        ),
      ],
    );
  }
}

class EntityAddSpeedDial extends StatelessWidget {
  const EntityAddSpeedDial({
    required this.onCreateTask,
    required this.onCreateProject,
    this.heroTag,
    super.key,
  });

  final VoidCallback onCreateTask;
  final VoidCallback onCreateProject;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SpeedDial(
      heroTag: heroTag,
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 6,
      spaceBetweenChildren: 6,
      overlayOpacity: 0.4,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.check_box_outlined),
          label: l10n.addTaskAction,
          onTap: onCreateTask,
        ),
        SpeedDialChild(
          child: const Icon(Icons.folder_outlined),
          label: l10n.addProjectAction,
          onTap: onCreateProject,
        ),
      ],
    );
  }
}
