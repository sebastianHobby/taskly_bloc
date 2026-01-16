import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_tile_capabilities.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_state.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';

abstract class TileIntentDispatcher {
  Future<void> dispatch(BuildContext context, TileIntent intent);
}

final class DefaultTileIntentDispatcher implements TileIntentDispatcher {
  DefaultTileIntentDispatcher({
    required ProjectRepositoryContract projectRepository,
    required EditorLauncher editorLauncher,
  }) : _projectRepository = projectRepository,
       _editorLauncher = editorLauncher;

  final ProjectRepositoryContract _projectRepository;
  final EditorLauncher _editorLauncher;

  @override
  Future<void> dispatch(BuildContext context, TileIntent intent) async {
    switch (intent) {
      case TileIntentSetCompletion():
        return _setCompletion(context, intent);
      case TileIntentSetPinned():
        return _setPinned(context, intent);
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

  Future<void> _setPinned(
    BuildContext context,
    TileIntentSetPinned intent,
  ) async {
    final bloc = context.read<ScreenActionsBloc>();

    switch (intent.entityType) {
      case EntityType.task:
        bloc.add(
          ScreenActionsTaskPinnedChanged(
            taskId: intent.entityId,
            pinned: intent.isPinned,
          ),
        );
      case EntityType.project:
        bloc.add(
          ScreenActionsProjectPinnedChanged(
            projectId: intent.entityId,
            pinned: intent.isPinned,
          ),
        );
      case EntityType.value:
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

    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      title: title,
      itemName: intent.entityName,
      description: description,
    );

    if (!confirmed || !context.mounted) return;

    final bloc = context.read<ScreenActionsBloc>();
    bloc.add(
      ScreenActionsDeleteEntity(
        entityType: intent.entityType,
        entityId: intent.entityId,
      ),
    );
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
              const SizedBox(height: 8),
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
        final targetProjectId = await _pickProjectId(context);
        if (targetProjectId == null || !context.mounted) return;
        return dispatch(
          context,
          TileIntentMoveTaskToProject(
            taskId: intent.taskId,
            targetProjectId: targetProjectId,
          ),
        );
    }
  }

  Future<String?> _pickProjectId(BuildContext context) async {
    final l10n = context.l10n;

    final projects = await _projectRepository.getAll();

    if (!context.mounted) return null;

    return showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.selectProjectTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: projects.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const Icon(Icons.folder_off_outlined),
                    title: const Text('No project'),
                    onTap: () => Navigator.of(context).pop(''),
                  );
                }

                final project = projects[index - 1];
                return ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(project.name),
                  onTap: () => Navigator.of(context).pop(project.id),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(l10n.cancelLabel),
            ),
          ],
        );
      },
    );
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
