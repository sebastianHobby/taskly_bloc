import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/services/screens/entity_action_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/presentation/features/labels/bloc/label_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/labels/view/label_detail_view.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';
import 'package:taskly_bloc/presentation/navigation/entity_navigator.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/entity_header.dart';
import 'package:taskly_bloc/presentation/widgets/error_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/loading_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';

/// Unified label detail page using the screen model.
///
/// Fetches the label first, then creates a dynamic ScreenDefinition
/// and renders using the unified pattern.
class LabelDetailUnifiedPage extends StatelessWidget {
  const LabelDetailUnifiedPage({
    required this.labelId,
    super.key,
  });

  final String labelId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LabelDetailBloc>(
      create: (_) => LabelDetailBloc(
        labelRepository: getIt<LabelRepositoryContract>(),
        labelId: labelId,
      ),
      child: _LabelDetailContent(labelId: labelId),
    );
  }
}

class _LabelDetailContent extends StatelessWidget {
  const _LabelDetailContent({required this.labelId});

  final String labelId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LabelDetailBloc, LabelDetailState>(
      builder: (context, state) {
        return switch (state) {
          LabelDetailInitial() ||
          LabelDetailLoadInProgress() => const _LoadingScaffold(),
          LabelDetailLoadSuccess(:final label) => _LabelScreenWithData(
            label: label,
          ),
          LabelDetailOperationFailure(:final errorDetails) => _ErrorScaffold(
            message: friendlyErrorMessageForUi(
              errorDetails.error,
              context.l10n,
            ),
            onRetry: () => context.read<LabelDetailBloc>().add(
              LabelDetailEvent.loadById(labelId: labelId),
            ),
          ),
          _ => const _LoadingScaffold(),
        };
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.labelsTitle)),
      body: const LoadingStateWidget(),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.labelsTitle)),
      body: ErrorStateWidget(message: message, onRetry: onRetry),
    );
  }
}

/// Main content view when label is loaded
class _LabelScreenWithData extends StatelessWidget {
  const _LabelScreenWithData({required this.label});

  final Label label;

  @override
  Widget build(BuildContext context) {
    // Create dynamic screen definition for this label
    final definition = SystemScreenDefinitions.forLabel(
      labelId: label.id,
      labelName: label.name,
      labelColor: label.color,
    );

    return BlocProvider<ScreenBloc>(
      create: (context) => ScreenBloc(
        screenRepository: getIt(),
        interpreter: getIt<ScreenDataInterpreter>(),
      )..add(ScreenEvent.load(definition: definition)),
      child: _LabelScreenView(label: label),
    );
  }
}

class _LabelScreenView extends StatelessWidget {
  const _LabelScreenView({required this.label});

  final Label label;

  void _showEditLabelSheet(BuildContext context) {
    unawaited(
      showDetailModal<void>(
        context: context,
        childBuilder: (modalSheetContext) => SafeArea(
          top: false,
          child: LabelDetailSheetPage(
            labelId: label.id,
            labelRepository: getIt<LabelRepositoryContract>(),
            onSaved: (savedLabelId) {
              // Refresh the label details after edit
              context.read<LabelDetailBloc>().add(
                LabelDetailEvent.loadById(labelId: savedLabelId),
              );
            },
          ),
        ),
        showDragHandle: true,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteLabel),
        content: Text(
          'Are you sure you want to delete "${label.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.deleteLabel),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      context.read<LabelDetailBloc>().add(
        LabelDetailEvent.delete(id: label.id),
      );
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _showEditLabelSheet(context);
      case 'delete':
        unawaited(_showDeleteConfirmation(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entityActionService = getIt<EntityActionService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(label.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n.editLabel,
            onPressed: () => _showEditLabelSheet(context),
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleMenuAction(context, action),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.deleteLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Entity header
          EntityHeader.label(
            label: label,
            onTap: () => _showEditLabelSheet(context),
          ),

          // Related lists via ScreenBloc
          Expanded(
            child: BlocBuilder<ScreenBloc, ScreenState>(
              builder: (context, state) {
                return switch (state) {
                  ScreenInitialState() ||
                  ScreenLoadingState() => const LoadingStateWidget(),
                  ScreenLoadedState(:final data) => _buildRelatedLists(
                    context,
                    data,
                    entityActionService,
                  ),
                  ScreenErrorState(:final message) => ErrorStateWidget(
                    message: message,
                    onRetry: () => context.read<ScreenBloc>().add(
                      const ScreenEvent.refresh(),
                    ),
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedLists(
    BuildContext context,
    ScreenData data,
    EntityActionService entityActionService,
  ) {
    if (data.sections.isEmpty) {
      return EmptyStateWidget.noTasks(
        title: context.l10n.emptyTasksTitle,
        description: 'No tasks or projects associated with this label.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ScreenBloc>().add(const ScreenEvent.refresh());
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: data.sections.length,
        itemBuilder: (context, index) {
          final section = data.sections[index];
          return SectionWidget(
            section: section,
            displayConfig: section.displayConfig,
            onEntityTap: (entityId, entityType) {
              EntityNavigator.toEntity(
                context,
                entityId: entityId,
                entityType: entityType,
              );
            },
            onTaskCheckboxChanged: (task, value) async {
              if (value ?? false) {
                await entityActionService.completeTask(task.id);
              } else {
                await entityActionService.uncompleteTask(task.id);
              }
              if (context.mounted) {
                context.read<ScreenBloc>().add(const ScreenEvent.refresh());
              }
            },
            onTaskDelete: (task) async {
              await entityActionService.deleteTask(task.id);
              if (context.mounted) {
                context.read<ScreenBloc>().add(const ScreenEvent.refresh());
              }
            },
          );
        },
      ),
    );
  }
}
