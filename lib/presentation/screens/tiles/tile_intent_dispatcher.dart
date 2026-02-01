import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/project_picker/project_picker.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_state.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent.dart';
import 'package:taskly_bloc/presentation/shared/ui/confirmation_dialog_helpers.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

abstract class TileIntentDispatcher {
  Future<void> dispatch(BuildContext context, TileIntent intent);
}

final class DefaultTileIntentDispatcher implements TileIntentDispatcher {
  DefaultTileIntentDispatcher({
    required SessionSharedDataService sharedDataService,
    required EditorLauncher editorLauncher,
  }) : _sharedDataService = sharedDataService,
       _editorLauncher = editorLauncher;

  final SessionSharedDataService _sharedDataService;
  final EditorLauncher _editorLauncher;

  @override
  Future<void> dispatch(BuildContext context, TileIntent intent) async {
    switch (intent) {
      case TileIntentSetCompletion():
        return _setCompletion(context, intent);
      case TileIntentCompleteSeries():
        return _completeSeries(context, intent);
      case TileIntentRequestDelete():
        return _requestDelete(context, intent);
      case TileIntentOpenEditor():
        return _openEditor(context, intent);
      case TileIntentOpenDetails():
        return _openDetails(context, intent);
      case TileIntentOpenMoveToProject():
        return _openMoveToProject(context, intent);
      case TileIntentMoveTaskToProject():
        return _moveTaskToProject(context, intent);
    }
  }

  Future<void> _setCompletion(
    BuildContext context,
    TileIntentSetCompletion intent,
  ) async {
    final bloc = context.read<ScreenActionsBloc>();

    if (intent.scope == CompletionScope.occurrence) {
      // Occurrence-scoped intents must carry occurrence dates.
      assert(
        intent.occurrenceDate != null && intent.originalOccurrenceDate != null,
        'Occurrence-scoped completion intents must carry occurrenceDate and originalOccurrenceDate',
      );

      if (intent.occurrenceDate == null ||
          intent.originalOccurrenceDate == null) {
        bloc.add(
          ScreenActionsFailureEvent(
            failureKind: ScreenActionsFailureKind.invalidOccurrenceData,
            fallbackMessage: 'Invalid occurrence data',
            entityType: intent.entityType,
            entityId: intent.entityId,
          ),
        );
        return;
      }
    }

    switch (intent.entityType) {
      case EntityType.task:
        bloc.add(
          ScreenActionsTaskCompletionChanged(
            taskId: intent.entityId,
            completed: intent.completed,
            occurrenceDate: intent.occurrenceDate,
            originalOccurrenceDate: intent.originalOccurrenceDate,
          ),
        );
      case EntityType.project:
        bloc.add(
          ScreenActionsProjectCompletionChanged(
            projectId: intent.entityId,
            completed: intent.completed,
            occurrenceDate: intent.occurrenceDate,
            originalOccurrenceDate: intent.originalOccurrenceDate,
          ),
        );
      case EntityType.value:
        // Not supported.
        break;
    }
  }

  Future<void> _requestDelete(
    BuildContext context,
    TileIntentRequestDelete intent,
  ) async {
    final l10n = context.l10n;

    final (title, description) = switch (intent.entityType) {
      EntityType.task => (
        l10n.deleteTaskAction,
        l10n.deleteConfirmationIrreversibleDescription,
      ),
      EntityType.project => (
        l10n.deleteProjectAction,
        l10n.deleteProjectCascadeDescription,
      ),
      EntityType.value => (
        l10n.deleteValue,
        l10n.deleteValueCascadeDescription,
      ),
    };

    final confirmed = await ConfirmationDialog.show(
      context,
      title: title,
      confirmLabel: l10n.deleteLabel,
      cancelLabel: l10n.cancelLabel,
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      iconBackgroundColor: Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.3),
      content: buildDeleteConfirmationContent(
        context,
        itemName: intent.entityName,
        description: description,
      ),
    );

    if (!confirmed || !context.mounted) return;

    final bloc = context.read<ScreenActionsBloc>();

    if (!intent.popOnSuccess) {
      bloc.add(
        ScreenActionsDeleteEntity(
          entityType: intent.entityType,
          entityId: intent.entityId,
        ),
      );
      return;
    }

    final completer = Completer<void>();
    bloc.add(
      ScreenActionsDeleteEntity(
        entityType: intent.entityType,
        entityId: intent.entityId,
        completer: completer,
      ),
    );

    await completer.future;
    if (context.mounted) {
      await Navigator.of(context).maybePop();
    }
  }

  Future<void> _completeSeries(
    BuildContext context,
    TileIntentCompleteSeries intent,
  ) async {
    final confirmed = await _confirmCompleteSeries(
      context,
      entityName: intent.entityName,
    );

    if (!confirmed || !context.mounted) return;

    final bloc = context.read<ScreenActionsBloc>();

    switch (intent.entityType) {
      case EntityType.task:
        bloc.add(
          ScreenActionsTaskSeriesCompleted(taskId: intent.entityId),
        );
      case EntityType.project:
        bloc.add(
          ScreenActionsProjectSeriesCompleted(projectId: intent.entityId),
        );
      case EntityType.value:
        break;
    }
  }

  Future<bool> _confirmCompleteSeries(
    BuildContext context, {
    required String entityName,
  }) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.event_busy_outlined,
            color: colorScheme.primary,
            size: 32,
          ),
        ),
        title: const Text(
          'Complete series?',
          textAlign: TextAlign.center,
        ),
        content: Text(
          'This ends the recurring series for "$entityName" and marks it complete.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Complete series'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: EdgeInsets.fromLTRB(
          TasklyTokens.of(context).spaceXl,
          0,
          TasklyTokens.of(context).spaceXl,
          TasklyTokens.of(context).spaceXl,
        ),
      ),
    );

    return result ?? false;
  }

  Future<void> _openEditor(BuildContext context, TileIntentOpenEditor intent) {
    // Prefer route-based navigation for standard editor opens.
    if (!intent.openToValues && !intent.openToProjectPicker) {
      Routing.toEntity(context, intent.entityType, intent.entityId);
      return SynchronousFuture(null);
    }

    // Use EditorLauncher when editor-only flags are required.
    switch (intent.entityType) {
      case EntityType.task:
        return _editorLauncher.openTaskEditor(
          context,
          taskId: intent.entityId,
          openToValues: intent.openToValues,
          openToProjectPicker: intent.openToProjectPicker,
        );
      case EntityType.project:
        return _editorLauncher.openProjectEditor(
          context,
          projectId: intent.entityId,
          openToValues: intent.openToValues,
        );
      case EntityType.value:
        return _editorLauncher.openValueEditor(
          context,
          valueId: intent.entityId,
        );
    }
  }

  Future<void> _openDetails(
    BuildContext context,
    TileIntentOpenDetails intent,
  ) {
    Routing.toEntity(context, intent.entityType, intent.entityId);
    return SynchronousFuture(null);
  }

  Future<void> _openMoveToProject(
    BuildContext context,
    TileIntentOpenMoveToProject intent,
  ) async {
    final l10n = context.l10n;

    if (!intent.allowOpenEditor && !intent.allowQuickMove) {
      return;
    }

    final choice = await showModalBottomSheet<_MoveToProjectChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.drive_file_move_outline),
                title: Text(l10n.selectProjectTitle),
                subtitle: Text(intent.taskName),
              ),
              const Divider(height: 1),
              if (intent.allowQuickMove)
                ListTile(
                  leading: const Icon(Icons.flash_on_outlined),
                  title: const Text('Move now'),
                  subtitle: const Text(
                    'Select a project and move immediately.',
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_MoveToProjectChoice.quickMove),
                ),
              if (intent.allowOpenEditor)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Open editor'),
                  subtitle: const Text(
                    'Open the task editor and choose a project.',
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_MoveToProjectChoice.openEditor),
                ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
            ],
          ),
        );
      },
    );

    if (choice == null || !context.mounted) return;

    switch (choice) {
      case _MoveToProjectChoice.openEditor:
        return dispatch(
          context,
          TileIntentOpenEditor(
            entityType: EntityType.task,
            entityId: intent.taskId,
            openToProjectPicker: true,
          ),
        );
      case _MoveToProjectChoice.quickMove:
        await showProjectPickerModal(
          context: context,
          sharedDataService: _sharedDataService,
          onSelect: (projectId) async {
            if (!context.mounted) return;

            final completer = Completer<void>();
            context.read<ScreenActionsBloc>().add(
              ScreenActionsMoveTaskToProject(
                taskId: intent.taskId,
                targetProjectId: projectId ?? '',
                completer: completer,
              ),
            );
            await completer.future;
          },
        );
        return;
    }
  }

  Future<void> _moveTaskToProject(
    BuildContext context,
    TileIntentMoveTaskToProject intent,
  ) async {
    context.read<ScreenActionsBloc>().add(
      ScreenActionsMoveTaskToProject(
        taskId: intent.taskId,
        targetProjectId: intent.targetProjectId,
      ),
    );
  }
}

enum _MoveToProjectChoice { quickMove, openEditor }
