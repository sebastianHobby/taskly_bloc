import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_feedback.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_delete_reassignment_bloc.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

Future<bool> showValueDeleteReassignmentSheet(
  BuildContext context, {
  required String valueId,
  required String valueName,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) {
      return BlocProvider(
        create: (context) => ValueDeleteReassignmentBloc(
          valueRepository: context.read<ValueRepositoryContract>(),
          projectRepository: context.read<ProjectRepositoryContract>(),
          valueWriteService: context.read<ValueWriteService>(),
          errorReporter: context.read<AppErrorReporter>(),
          valueId: valueId,
          valueName: valueName,
        )..add(const ValueDeleteReassignmentStarted()),
        child: const _ValueDeleteReassignmentSheetBody(),
      );
    },
  );
  return result == true;
}

class _ValueDeleteReassignmentSheetBody extends StatelessWidget {
  const _ValueDeleteReassignmentSheetBody();

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;

    return BlocConsumer<
      ValueDeleteReassignmentBloc,
      ValueDeleteReassignmentState
    >(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          (current.status == ValueDeleteReassignmentStatus.success ||
              current.status == ValueDeleteReassignmentStatus.error),
      listener: (context, state) {
        if (state.status == ValueDeleteReassignmentStatus.success) {
          showEditorSuccessSnackBar(
            context,
            context.l10n.valueDeletedSuccessfully,
          );
          Navigator.of(context).pop(true);
        } else if (state.status == ValueDeleteReassignmentStatus.error &&
            state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                friendlyErrorMessageForUi(state.error!, context.l10n),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == ValueDeleteReassignmentStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceLg,
            tokens.spaceLg,
            tokens.spaceXl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                state.step == ValueDeleteReassignmentStep.impact
                    ? l10n.valueDeleteReassignStep1Title(state.valueName)
                    : l10n.valueDeleteReassignStep2Title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: tokens.spaceXs),
              Text(
                state.step == ValueDeleteReassignmentStep.impact
                    ? l10n.valueDeleteReassignStep1Progress
                    : l10n.valueDeleteReassignStep2Progress,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spaceLg),
              if (state.step == ValueDeleteReassignmentStep.impact)
                _ImpactStep(state: state)
              else
                _ReplacementStep(state: state),
              SizedBox(height: tokens.spaceLg),
              if (state.step == ValueDeleteReassignmentStep.impact)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancelLabel),
                      ),
                    ),
                    SizedBox(width: tokens.spaceSm),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            context.read<ValueDeleteReassignmentBloc>().add(
                              const ValueDeleteReassignmentContinuePressed(),
                            ),
                        child: Text(l10n.onboardingContinueLabel),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            state.status ==
                                ValueDeleteReassignmentStatus.submitting
                            ? null
                            : () => context
                                  .read<ValueDeleteReassignmentBloc>()
                                  .add(
                                    const ValueDeleteReassignmentBackPressed(),
                                  ),
                        child: Text(l10n.backLabel),
                      ),
                    ),
                    SizedBox(width: tokens.spaceSm),
                    Expanded(
                      child: FilledButton(
                        onPressed: state.canConfirm
                            ? () => context
                                  .read<ValueDeleteReassignmentBloc>()
                                  .add(
                                    const ValueDeleteReassignmentConfirmPressed(),
                                  )
                            : null,
                        child:
                            state.status ==
                                ValueDeleteReassignmentStatus.submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n.valueDeleteReassignConfirmAction(
                                  state.affectedProjects.length,
                                ),
                              ),
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
}

class _ImpactStep extends StatelessWidget {
  const _ImpactStep({required this.state});

  final ValueDeleteReassignmentState state;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;
    final projects = state.affectedProjects;
    final preview = projects.take(3).toList(growable: false);
    final remainingCount = projects.length - preview.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.valueDeleteReassignImpactBody(projects.length),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: tokens.spaceSm),
        Text(
          l10n.valueDeleteReassignImpactRule,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: tokens.spaceMd),
        Text(
          l10n.valueDeleteReassignAffectedProjectsLabel(projects.length),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SizedBox(height: tokens.spaceSm),
        for (final project in preview) ...[
          Text(
            '• ${project.name}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: tokens.spaceXxs),
        ],
        if (remainingCount > 0)
          Text(
            l10n.valueDeleteReassignAffectedProjectsMore(remainingCount),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
      ],
    );
  }
}

class _ReplacementStep extends StatelessWidget {
  const _ReplacementStep({required this.state});

  final ValueDeleteReassignmentState state;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.replacementValues.isEmpty)
          Text(
            l10n.valueDeleteReassignNeedReplacementBody,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          DropdownButtonFormField<String>(
            initialValue: state.selectedReplacementValueId,
            decoration: InputDecoration(
              labelText: l10n.valueDeleteReassignReplacementFieldLabel,
              border: const OutlineInputBorder(),
            ),
            items: state.replacementValues
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value.id,
                    child: Text(value.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (next) {
              if (next == null) return;
              context.read<ValueDeleteReassignmentBloc>().add(
                ValueDeleteReassignmentReplacementSelected(next),
              );
            },
          ),
        SizedBox(height: tokens.spaceSm),
        TextButton.icon(
          onPressed: () => _createValueInFlow(context),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.valueDeleteReassignCreateReplacementAction),
        ),
        SizedBox(height: tokens.spaceSm),
        if (state.selectedReplacementValueId != null)
          Text(
            l10n.valueDeleteReassignResultSummary(
              state.affectedProjects.length,
              _selectedReplacementName(state),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  String _selectedReplacementName(ValueDeleteReassignmentState state) {
    final selectedId = state.selectedReplacementValueId;
    if (selectedId == null) return '';
    return state.replacementValues
        .firstWhere(
          (value) => value.id == selectedId,
          orElse: () => state.replacementValues.first,
        )
        .name;
  }

  Future<void> _createValueInFlow(BuildContext context) async {
    String? createdValueId;
    await context.read<EditorLauncher>().openValueEditor(
      context,
      onSaved: (valueId) => createdValueId = valueId,
    );
    if (!context.mounted) return;
    if (createdValueId == null || createdValueId!.trim().isEmpty) return;
    context.read<ValueDeleteReassignmentBloc>().add(
      ValueDeleteReassignmentReplacementCreated(createdValueId!),
    );
  }
}
