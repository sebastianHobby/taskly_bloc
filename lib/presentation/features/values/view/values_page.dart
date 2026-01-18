import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_list_bloc.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/values_list.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_ui/taskly_ui.dart';

class ValuesPage extends StatelessWidget {
  const ValuesPage({super.key});

  void _createValue(BuildContext context) {
    Routing.toValueNew(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ValueListBloc>(
      create: (context) => ValueListBloc(
        valueRepository: getIt<ValueRepositoryContract>(),
        errorReporter: context.read<AppErrorReporter>(),
      )..add(const ValueListEvent.subscriptionRequested()),
      child: Builder(
        builder: (context) {
          final isCompact = WindowSizeClass.of(context).isCompact;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Values'),
              actions: TasklyAppBarActions.withAttentionBell(
                context,
                actions: [
                  if (!isCompact)
                    IconButton(
                      tooltip: context.l10n.createValueTooltip,
                      onPressed: () => _createValue(context),
                      icon: const Icon(Icons.add),
                    ),
                ],
              ),
            ),
            floatingActionButton: isCompact
                ? FloatingActionButton(
                    tooltip: context.l10n.createValueTooltip,
                    onPressed: () => _createValue(context),
                    heroTag: 'create_value_fab_values',
                    child: const Icon(Icons.add),
                  )
                : null,
            body: BlocBuilder<ValueListBloc, ValueListState>(
              builder: (context, state) {
                return switch (state) {
                  ValueListInitial() ||
                  ValueListLoading() => const FeedBody.loading(),
                  ValueListError(:final error) => FeedBody.error(
                    message: friendlyErrorMessageForUi(error, context.l10n),
                    retryLabel: context.l10n.retryButton,
                    onRetry: () => context.read<ValueListBloc>().add(
                      const ValueListEvent.subscriptionRequested(),
                    ),
                  ),
                  ValueListLoaded(:final values) when values.isEmpty =>
                    FeedBody.empty(
                      child: EmptyStateWidget(
                        icon: Icons.favorite_border,
                        title: 'No values yet',
                        description:
                            'Create a value to clarify what matters most.',
                        actionLabel: context.l10n.createValueOption,
                        onAction: () => _createValue(context),
                      ),
                    ),
                  ValueListLoaded(:final values) => ValuesListView(
                    values: values,
                  ),
                };
              },
            ),
          );
        },
      ),
    );
  }
}
