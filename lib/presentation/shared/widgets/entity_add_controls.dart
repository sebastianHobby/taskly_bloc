import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

class EntityAddSpeedDial extends StatelessWidget {
  const EntityAddSpeedDial({
    required this.onCreateTask,
    required this.onCreateProject,
    this.heroTag,
    super.key,
  });

  final VoidCallback onCreateTask;
  final VoidCallback onCreateProject;
  final String? heroTag;

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

class EntityAddFab extends StatelessWidget {
  const EntityAddFab({
    required this.onPressed,
    this.heroTag,
    this.tooltip,
    super.key,
  });

  final VoidCallback onPressed;
  final String? heroTag;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      heroTag: heroTag,
      tooltip: tooltip,
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 6,
      spaceBetweenChildren: 6,
      overlayOpacity: 0.4,
      onPress: onPressed,
    );
  }
}
