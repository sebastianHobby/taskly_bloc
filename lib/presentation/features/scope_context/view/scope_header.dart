import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_domain/contracts.dart';

import 'package:taskly_bloc/presentation/features/scope_context/bloc/scope_context_bloc.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/projects_scope.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

class ScopeHeader extends StatelessWidget {
  const ScopeHeader({
    required this.scope,
    super.key,
  });

  final ProjectsScope scope;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScopeContextBloc(
        scope: scope,
        taskRepository: context.read<TaskRepositoryContract>(),
        projectRepository: context.read<ProjectRepositoryContract>(),
        valueRepository: context.read<ValueRepositoryContract>(),
      ),
      child: const _ScopeHeaderView(),
    );
  }
}

class _ScopeHeaderView extends StatelessWidget {
  const _ScopeHeaderView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScopeContextBloc, ScopeContextState>(
      builder: (context, state) {
        return switch (state) {
          ScopeContextLoading() => SizedBox(
            height: TasklyTokens.of(context).spaceXxl * 2,
          ),
          ScopeContextError() => Padding(
            padding: EdgeInsets.fromLTRB(
              TasklyTokens.of(context).spaceLg,
              TasklyTokens.of(context).spaceMd,
              TasklyTokens.of(context).spaceLg,
              0,
            ),
            child: Text(
              context.l10n.scopeHeaderLoadFailedMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          ScopeContextLoaded(
            :final title,
            :final taskCount,
            :final projectCount,
          ) =>
            Padding(
              padding: EdgeInsets.fromLTRB(
                TasklyTokens.of(context).spaceLg,
                TasklyTokens.of(context).spaceMd,
                TasklyTokens.of(context).spaceLg,
                0,
              ),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titleLabel(context, title),
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: TasklyTokens.of(context).spaceSm),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MetricChip(
                                  label: context.l10n.tasksTitle,
                                  value: taskCount,
                                ),
                                if (projectCount != null)
                                  _MetricChip(
                                    label: context.l10n.projectsTitle,
                                    value: projectCount,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        };
      },
    );
  }

  String _titleLabel(BuildContext context, ScopeContextTitle title) {
    final l10n = context.l10n;
    final name = title.name;
    if (name != null && name.trim().isNotEmpty) return name;
    return switch (title.kind) {
      ScopeContextTitleKind.project => l10n.projectLabel,
      ScopeContextTitleKind.value => l10n.valueLabel,
    };
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(TasklyTokens.of(context).radiusMd),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: TasklyTokens.of(context).spaceLg,
          vertical: TasklyTokens.of(context).spaceSm,
        ),
        child: Text(
          context.l10n.scopeHeaderMetricLabel(label, value),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}
