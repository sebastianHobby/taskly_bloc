import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/checklists/bloc/checklist_execution_bloc.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

Future<void> showTaskChecklistExecutionSheet(
  BuildContext context, {
  required ChecklistExecutionBloc bloc,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: bloc..add(const ChecklistExecutionEvent.started()),
        child: const _ChecklistExecutionSheetBody(),
      );
    },
  );
}

Future<void> showRoutineChecklistExecutionSheet(
  BuildContext context, {
  required ChecklistExecutionBloc bloc,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: bloc..add(const ChecklistExecutionEvent.started()),
        child: const _ChecklistExecutionSheetBody(),
      );
    },
  );
}

class _ChecklistExecutionSheetBody extends StatefulWidget {
  const _ChecklistExecutionSheetBody();

  @override
  State<_ChecklistExecutionSheetBody> createState() =>
      _ChecklistExecutionSheetBodyState();
}

class _ChecklistExecutionSheetBodyState
    extends State<_ChecklistExecutionSheetBody> {
  final TextEditingController _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);

    return BlocConsumer<ChecklistExecutionBloc, ChecklistExecutionState>(
      listenWhen: (previous, current) => previous.effect != current.effect,
      listener: (context, state) async {
        final bloc = context.read<ChecklistExecutionBloc>();
        final effect = state.effect;
        if (effect == null) return;
        switch (effect) {
          case ChecklistExecutionPromptComplete():
            final shouldComplete = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(context.l10n.checklistAllDoneTitle),
                content: Text(_completionPromptBody(bloc, context)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(context.l10n.notNowLabel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(_completionPromptPrimaryLabel(bloc, context)),
                  ),
                ],
              ),
            );
            if (!context.mounted) return;
            if (shouldComplete ?? false) {
              bloc.add(
                const ChecklistExecutionEvent.completeParentNow(),
              );
            }
          case ChecklistExecutionClose():
            Navigator.of(context).pop();
          case ChecklistExecutionError(:final message):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
        }

        if (!context.mounted) return;
        bloc.add(const ChecklistExecutionEvent.effectHandled());
      },
      builder: (context, state) {
        final bloc = context.read<ChecklistExecutionBloc>();
        final checked = state.items
            .where((i) => state.checkedItemIds.contains(i.id))
            .length;
        final total = state.items.length;

        if (state.loading) {
          return const SizedBox(
            height: 320,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            tokens.spaceLg + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bloc.taskTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.spaceXxs2),
              Text(
                context.l10n.checklistProgressLabel(checked, total),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: tokens.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addController,
                      minLines: 1,
                      maxLines: null,
                      decoration: InputDecoration(
                        labelText: context.l10n.checklistAddItemLabel,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addItem(context),
                    ),
                  ),
                  SizedBox(width: tokens.spaceXs),
                  FilledButton(
                    onPressed: state.items.length >= 20
                        ? null
                        : () => _addItem(context),
                    child: Text(context.l10n.checklistAddItemLabel),
                  ),
                ],
              ),
              SizedBox(height: tokens.spaceSm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: state.items.length,
                  onReorder: (oldIndex, newIndex) {
                    context.read<ChecklistExecutionBloc>().add(
                      ChecklistExecutionEvent.reorderItems(
                        oldIndex: oldIndex,
                        newIndex: newIndex,
                      ),
                    );
                  },
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final isChecked = state.checkedItemIds.contains(item.id);
                    return ListTile(
                      key: ValueKey(item.id),
                      contentPadding: EdgeInsets.zero,
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_indicator),
                      ),
                      title: Row(
                        children: [
                          Checkbox(
                            value: isChecked,
                            onChanged: (value) {
                              context.read<ChecklistExecutionBloc>().add(
                                ChecklistExecutionEvent.toggleChanged(
                                  itemId: item.id,
                                  checked: value ?? false,
                                ),
                              );
                            },
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.title,
                              minLines: 1,
                              maxLines: null,
                              onChanged: (value) {
                                context.read<ChecklistExecutionBloc>().add(
                                  ChecklistExecutionEvent.updateItemTitle(
                                    index: index,
                                    title: value,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        tooltip: context.l10n.checklistDeleteStepLabel,
                        onPressed: () {
                          context.read<ChecklistExecutionBloc>().add(
                            ChecklistExecutionEvent.deleteItem(index: index),
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: tokens.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.saving
                          ? null
                          : () => context.read<ChecklistExecutionBloc>().add(
                              const ChecklistExecutionEvent.checkAllAndComplete(),
                            ),
                      child: Text(
                        context.l10n.checklistCheckAllAndCompleteLabel,
                      ),
                    ),
                  ),
                  SizedBox(width: tokens.spaceSm),
                  Expanded(
                    child: FilledButton(
                      onPressed: state.saving
                          ? null
                          : () => context.read<ChecklistExecutionBloc>().add(
                              const ChecklistExecutionEvent.completeParentNow(),
                            ),
                      child: Text(_primaryActionLabel(bloc, context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _addItem(BuildContext context) {
    final value = _addController.text.trim();
    if (value.isEmpty) return;
    _addController.clear();
    context.read<ChecklistExecutionBloc>().add(
      ChecklistExecutionEvent.addItem(title: value),
    );
  }

  String _primaryActionLabel(
    ChecklistExecutionBloc bloc,
    BuildContext context,
  ) {
    return switch (bloc.parentKind) {
      ChecklistParentKind.task => context.l10n.checklistCompleteParentNowLabel,
      ChecklistParentKind.routine => context.l10n.checklistLogRoutineNowLabel,
    };
  }

  String _completionPromptBody(
    ChecklistExecutionBloc bloc,
    BuildContext context,
  ) {
    return switch (bloc.parentKind) {
      ChecklistParentKind.task => context.l10n.checklistAllDoneTaskBody,
      ChecklistParentKind.routine => context.l10n.checklistAllDoneRoutineBody,
    };
  }

  String _completionPromptPrimaryLabel(
    ChecklistExecutionBloc bloc,
    BuildContext context,
  ) {
    return switch (bloc.parentKind) {
      ChecklistParentKind.task => context.l10n.completeLabel,
      ChecklistParentKind.routine => context.l10n.checklistLogActionLabel,
    };
  }
}
