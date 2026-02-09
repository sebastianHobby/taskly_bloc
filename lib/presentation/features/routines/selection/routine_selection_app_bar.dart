import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/routines/bloc/routine_list_bloc.dart';
import 'package:taskly_bloc/presentation/features/routines/selection/routine_selection_bloc.dart';
import 'package:taskly_bloc/presentation/features/routines/selection/routine_selection_models.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

class RoutineSelectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const RoutineSelectionAppBar({
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
    return BlocBuilder<RoutineSelectionBloc, RoutineSelectionState>(
      builder: (context, state) {
        if (!state.isSelectionMode) {
          return AppBar(title: Text(baseTitle));
        }

        final selection = context.read<RoutineSelectionBloc>();
        final metas = selection.selectedEntitiesMeta();

        final canLog = metas.any((m) => !m.completedToday);
        final canUnlog = metas.any((m) => m.completedToday);
        final canDeactivate = metas.any((m) => m.isActive);
        final canActivate = metas.any((m) => !m.isActive);

        return AppBar(
          leading: IconButton(
            tooltip: context.l10n.closeLabel,
            onPressed: () {
              selection.exitSelectionMode();
              onExit();
            },
            icon: const Icon(Icons.close),
          ),
          title: Text(context.l10n.selectedCountLabel(state.selectedCount)),
          actions: [
            if (canLog)
              IconButton(
                tooltip: context.l10n.routineLogLabel,
                onPressed: () => _logSelected(context),
                icon: const Icon(Icons.check_rounded),
              ),
            if (canUnlog)
              IconButton(
                tooltip: context.l10n.routineUnlogLabel,
                onPressed: () => _unlogSelected(context),
                icon: const Icon(Icons.undo_rounded),
              ),
            PopupMenuButton<_RoutineSelectionMenuItem>(
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              onSelected: (item) => _handleMenuAction(context, item),
              itemBuilder: (context) {
                return <PopupMenuEntry<_RoutineSelectionMenuItem>>[
                  if (canActivate)
                    PopupMenuItem(
                      value: _RoutineSelectionMenuItem.activate,
                      child: Text(context.l10n.activateLabel),
                    ),
                  if (canDeactivate)
                    PopupMenuItem(
                      value: _RoutineSelectionMenuItem.deactivate,
                      child: Text(context.l10n.deactivateLabel),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: _RoutineSelectionMenuItem.delete,
                    child: Text(context.l10n.deleteLabel),
                  ),
                ];
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logSelected(BuildContext context) async {
    final selection = context.read<RoutineSelectionBloc>();
    final ids = selection
        .selectedEntitiesMeta()
        .where((m) => !m.completedToday)
        .map((m) => m.key.routineId)
        .toList(growable: false);
    if (ids.isEmpty) return;

    await context.read<RoutineListBloc>().logRoutines(ids);
    selection.exitSelectionMode();
    onExit();
  }

  Future<void> _unlogSelected(BuildContext context) async {
    final selection = context.read<RoutineSelectionBloc>();
    final ids = selection
        .selectedEntitiesMeta()
        .where((m) => m.completedToday)
        .map((m) => m.key.routineId)
        .toList(growable: false);
    if (ids.isEmpty) return;

    await context.read<RoutineListBloc>().unlogRoutines(ids);
    selection.exitSelectionMode();
    onExit();
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    _RoutineSelectionMenuItem item,
  ) async {
    switch (item) {
      case _RoutineSelectionMenuItem.deactivate:
        return _deactivateSelected(context);
      case _RoutineSelectionMenuItem.activate:
        return _activateSelected(context);
      case _RoutineSelectionMenuItem.delete:
        return _deleteSelected(context);
    }
  }

  Future<void> _activateSelected(BuildContext context) async {
    final selection = context.read<RoutineSelectionBloc>();
    final ids = selection
        .selectedEntitiesMeta()
        .where((m) => !m.isActive)
        .map((m) => m.key.routineId)
        .toList(growable: false);
    if (ids.isEmpty) return;

    await context.read<RoutineListBloc>().activateRoutines(ids);
    selection.exitSelectionMode();
    onExit();
  }

  Future<void> _deactivateSelected(BuildContext context) async {
    final selection = context.read<RoutineSelectionBloc>();
    final ids = selection
        .selectedEntitiesMeta()
        .where((m) => m.isActive)
        .map((m) => m.key.routineId)
        .toList(growable: false);
    if (ids.isEmpty) return;

    await context.read<RoutineListBloc>().deactivateRoutines(ids);
    selection.exitSelectionMode();
    onExit();
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final selection = context.read<RoutineSelectionBloc>();
    final metas = selection.selectedEntitiesMeta();
    if (metas.isEmpty) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: context.l10n.deleteRoutinesConfirmationTitle(metas.length),
      confirmLabel: context.l10n.deleteLabel,
      cancelLabel: context.l10n.cancelLabel,
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      iconBackgroundColor: Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.3),
      content: Text(context.l10n.deleteConfirmationIrreversibleDescription),
    );

    if (!context.mounted || !confirmed) return;

    final ids = metas.map((m) => m.key.routineId).toList(growable: false);
    await context.read<RoutineListBloc>().deleteRoutines(ids);

    selection.exitSelectionMode();
    onExit();
  }
}

enum _RoutineSelectionMenuItem { activate, deactivate, delete }
