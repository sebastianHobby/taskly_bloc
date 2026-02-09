import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_scope_header_bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

class ScheduledScopeHeader extends StatelessWidget {
  const ScheduledScopeHeader({required this.scope, super.key});

  final ScheduledScope scope;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScheduledScopeHeaderBloc(
        scope: scope,
        projectRepository: context.read<ProjectRepositoryContract>(),
        valueRepository: context.read<ValueRepositoryContract>(),
      ),
      child: const _ScheduledScopeHeaderView(),
    );
  }
}

class _ScheduledScopeHeaderView extends StatelessWidget {
  const _ScheduledScopeHeaderView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduledScopeHeaderBloc, ScheduledScopeHeaderState>(
      builder: (context, state) {
        return switch (state) {
          ScheduledScopeHeaderLoading() => SizedBox(
            height: TasklyTokens.of(context).spaceSm,
          ),
          ScheduledScopeHeaderError() => Padding(
            padding: EdgeInsets.fromLTRB(
              TasklyTokens.of(context).spaceLg,
              TasklyTokens.of(context).spaceMd,
              TasklyTokens.of(context).spaceLg,
              0,
            ),
            child: Text(
              _errorMessage(context, state),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          ScheduledScopeHeaderLoaded(:final kind, :final name) => Padding(
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
                      child: Text(
                        _titleLabel(context, kind, name),
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  String _titleLabel(
    BuildContext context,
    ScheduledScopeHeaderKind kind,
    String name,
  ) {
    final l10n = context.l10n;
    return switch (kind) {
      ScheduledScopeHeaderKind.project => l10n.scheduledScopeProjectTitle(name),
      ScheduledScopeHeaderKind.value => l10n.scheduledScopeValueTitle(name),
    };
  }

  String _errorMessage(
    BuildContext context,
    ScheduledScopeHeaderError state,
  ) {
    final l10n = context.l10n;
    return switch (state.kind) {
      ScheduledScopeHeaderKind.project =>
        state.type == ScheduledScopeHeaderErrorType.notFound
            ? l10n.scheduledScopeProjectNotFound
            : l10n.scheduledScopeProjectLoadFailed,
      ScheduledScopeHeaderKind.value =>
        state.type == ScheduledScopeHeaderErrorType.notFound
            ? l10n.scheduledScopeValueNotFound
            : l10n.scheduledScopeValueLoadFailed,
    };
  }
}
