import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_bloc.dart';
import 'package:taskly_bloc/presentation/features/project_picker/view/project_picker_modal.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SelectionAppBar({
    required this.baseTitle,
    required this.onExit,
    super.key,
  });

  final String baseTitle;
  final VoidCallback onExit;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectionBloc, SelectionState>(
      builder: (context, state) {
        if (!state.isSelectionMode) {
          return AppBar(title: Text(baseTitle));
        }

        final selection = context.read<SelectionBloc>();
        final actions = selection.computeActions();

        return AppBar(
          leading: IconButton(
            tooltip: context.l10n.closeLabel,
            onPressed: () {
              selection.exitSelectionMode();
              onExit();
            },
            icon: const Icon(Icons.close),
          ),
          title: Text('${state.selectedCount} selected'),
          actions: [
            if (actions.isEnabled(BulkActionKind.complete))
              IconButton(
                tooltip: 'Complete',
                onPressed: () =>
                    _completeOrUncomplete(context, completed: true),
                icon: const Icon(Icons.check_rounded),
              ),
            if (actions.isEnabled(BulkActionKind.uncomplete))
              IconButton(
                tooltip: 'Mark incomplete',
                onPressed: () =>
                    _completeOrUncomplete(context, completed: false),
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            PopupMenuButton<_SelectionMenuItem>(
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              onSelected: (item) => _handleMenuAction(context, item),
              itemBuilder: (context) {
                return <PopupMenuEntry<_SelectionMenuItem>>[
                  if (actions.isEnabled(BulkActionKind.pin))
                    const PopupMenuItem(
                      value: _SelectionMenuItem.pin,
                      child: Text('Pin to My Day'),
                    ),
                  if (actions.isEnabled(BulkActionKind.unpin))
                    const PopupMenuItem(
                      value: _SelectionMenuItem.unpin,
                      child: Text('Unpin from My Day'),
                    ),
                  if (actions.isEnabled(BulkActionKind.moveToProject))
                    const PopupMenuItem(
                      value: _SelectionMenuItem.moveToProject,
                      child: Text('Move to project'),
                    ),
                  if (actions.isEnabled(BulkActionKind.completeSeries))
                    const PopupMenuItem(
                      value: _SelectionMenuItem.completeSeries,
                      child: Text('Complete series'),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _SelectionMenuItem.delete,
                    child: Text('Delete'),
                  ),
                ];
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeOrUncomplete(
    BuildContext context, {
    required bool completed,
  }) async {
    final selection = context.read<SelectionBloc>();
    final screenActions = context.read<ScreenActionsBloc>();

    await selection.runSequential((key) async {
      final completer = Completer<void>();

      switch (key.entityType) {
        case EntityType.task:
          screenActions.add(
            ScreenActionsTaskCompletionChanged(
              taskId: key.entityId,
              completed: completed,
              completer: completer,
            ),
          );
        case EntityType.project:
          screenActions.add(
            ScreenActionsProjectCompletionChanged(
              projectId: key.entityId,
              completed: completed,
              completer: completer,
            ),
          );
        case EntityType.value:
          completer.complete();
      }

      await completer.future;
    });

    selection.exitSelectionMode();
    onExit();
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    _SelectionMenuItem item,
  ) async {
    switch (item) {
      case _SelectionMenuItem.pin:
        return _pinOrUnpin(context, pinned: true);
      case _SelectionMenuItem.unpin:
        return _pinOrUnpin(context, pinned: false);
      case _SelectionMenuItem.moveToProject:
        return _moveToProject(context);
      case _SelectionMenuItem.completeSeries:
        return _completeSeries(context);
      case _SelectionMenuItem.delete:
        return _deleteSelected(context);
    }
  }

  Future<void> _pinOrUnpin(
    BuildContext context, {
    required bool pinned,
  }) async {
    final selection = context.read<SelectionBloc>();
    final screenActions = context.read<ScreenActionsBloc>();

    await selection.runSequential((key) async {
      final completer = Completer<void>();

      switch (key.entityType) {
        case EntityType.task:
          screenActions.add(
            ScreenActionsTaskPinnedChanged(
              taskId: key.entityId,
              pinned: pinned,
              completer: completer,
            ),
          );
        case EntityType.project:
          screenActions.add(
            ScreenActionsProjectPinnedChanged(
              projectId: key.entityId,
              pinned: pinned,
              completer: completer,
            ),
          );
        case EntityType.value:
          completer.complete();
      }

      await completer.future;
    });

    selection.exitSelectionMode();
    onExit();
  }

  Future<void> _completeSeries(BuildContext context) async {
    final selection = context.read<SelectionBloc>();
    final screenActions = context.read<ScreenActionsBloc>();

    await selection.runSequential((key) async {
      final meta = selection.state.metaByKey[key];
      if (meta == null || !meta.canCompleteSeries) return;

      final completer = Completer<void>();

      switch (key.entityType) {
        case EntityType.task:
          screenActions.add(
            ScreenActionsTaskSeriesCompleted(
              taskId: key.entityId,
              completer: completer,
            ),
          );
        case EntityType.project:
          screenActions.add(
            ScreenActionsProjectSeriesCompleted(
              projectId: key.entityId,
              completer: completer,
            ),
          );
        case EntityType.value:
          completer.complete();
      }

      await completer.future;
    });

    selection.exitSelectionMode();
    onExit();
  }

  Future<void> _moveToProject(BuildContext context) async {
    final selection = context.read<SelectionBloc>();

    final selected = selection.selectedEntitiesMeta();
    if (selected.isEmpty) return;

    var didSelect = false;
    String? targetProjectId;

    await showProjectPickerModal(
      context: context,
      sharedDataService: context.read<SessionSharedDataService>(),
      onSelect: (projectId) async {
        didSelect = true;
        targetProjectId = projectId;
      },
    );

    if (!context.mounted || !didSelect) return;

    final screenActions = context.read<ScreenActionsBloc>();

    await selection.runSequential((key) async {
      if (key.entityType != EntityType.task) return;

      final completer = Completer<void>();
      screenActions.add(
        ScreenActionsMoveTaskToProject(
          taskId: key.entityId,
          targetProjectId: targetProjectId ?? '',
          completer: completer,
        ),
      );
      await completer.future;
    });

    selection.exitSelectionMode();
    onExit();
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final selection = context.read<SelectionBloc>();
    final metas = selection.selectedEntitiesMeta();
    if (metas.isEmpty) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete ${metas.length} item${metas.length == 1 ? '' : 's'}?',
      confirmLabel: context.l10n.deleteLabel,
      cancelLabel: context.l10n.cancelLabel,
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      iconBackgroundColor: Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.3),
      content: const Text(
        'This action cannot be undone.',
      ),
    );

    if (!context.mounted || !confirmed) return;

    final screenActions = context.read<ScreenActionsBloc>();

    await selection.runSequential((key) async {
      final completer = Completer<void>();
      screenActions.add(
        ScreenActionsDeleteEntity(
          entityType: key.entityType,
          entityId: key.entityId,
          completer: completer,
        ),
      );
      await completer.future;
    });

    selection.exitSelectionMode();
    onExit();
  }
}

enum _SelectionMenuItem {
  pin,
  unpin,
  moveToProject,
  completeSeries,
  delete,
}
