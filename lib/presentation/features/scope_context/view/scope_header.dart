import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_domain/contracts.dart';

import 'package:taskly_bloc/presentation/features/scope_context/bloc/scope_context_bloc.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';

class ScopeHeader extends StatelessWidget {
  const ScopeHeader({
    required this.scope,
    super.key,
  });

  final AnytimeScope scope;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScopeContextBloc(
        scope: scope,
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
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
          ScopeContextLoading() => const SizedBox(height: 64),
          ScopeContextError(:final message) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          ScopeContextLoaded(
            :final title,
            :final taskCount,
            :final projectCount,
          ) =>
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MetricChip(label: 'Tasks', value: taskCount),
                                if (projectCount != null)
                                  _MetricChip(
                                    label: 'Projects',
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
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '$label: $value',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}
