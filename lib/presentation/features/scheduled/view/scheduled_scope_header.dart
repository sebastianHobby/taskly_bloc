import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_scope_header_bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/taskly_domain.dart';

class ScheduledScopeHeader extends StatelessWidget {
  const ScheduledScopeHeader({required this.scope, super.key});

  final ScheduledScope scope;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScheduledScopeHeaderBloc(
        scope: scope,
        projectRepository: getIt<ProjectRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
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
          ScheduledScopeHeaderLoading() => const SizedBox(height: 12),
          ScheduledScopeHeaderError(:final message) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          ScheduledScopeHeaderLoaded(:final title) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
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
}
