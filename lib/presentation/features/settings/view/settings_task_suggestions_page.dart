import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/allocation_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';

class SettingsTaskSuggestionsPage extends StatelessWidget {
  const SettingsTaskSuggestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AllocationSettingsBloc>(
      create: (context) => AllocationSettingsBloc(
        settingsRepository: context.read<SettingsRepositoryContract>(),
      )..add(const AllocationSettingsStarted()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Task Suggestions'),
        ),
        body: BlocBuilder<AllocationSettingsBloc, AllocationSettingsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ResponsiveBody(
              isExpandedLayout: context.isExpandedScreen,
              child: ListView(
                children: [
                  _SuggestionSignalSection(settings: state.settings),
                  _ValuesBalanceSection(settings: state.settings),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionSignalSection extends StatelessWidget {
  const _SuggestionSignalSection({required this.settings});

  final AllocationConfig settings;

  @override
  Widget build(BuildContext context) {
    final mode = switch (settings.suggestionSignal) {
      SuggestionSignal.behaviorBased => SuggestionSignalOption.behaviorBased,
      SuggestionSignal.ratingsBased => SuggestionSignalOption.ratingsBased,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Suggestion signal'),
        RadioListTile<SuggestionSignalOption>(
          title: const Text('Behavior-based (Completions + balance)'),
          subtitle: const Text(
            'Stable and objective. Follows what you actually did.',
          ),
          value: SuggestionSignalOption.behaviorBased,
          groupValue: mode,
          onChanged: (value) {
            if (value == null) return;
            context.read<AllocationSettingsBloc>().add(
              AllocationSuggestionSignalChanged(value),
            );
          },
        ),
        RadioListTile<SuggestionSignalOption>(
          title: const Text('Ratings-based (Values + ratings)'),
          subtitle: const Text(
            'More personal and reflective. Uses your weekly check-ins.',
          ),
          value: SuggestionSignalOption.ratingsBased,
          groupValue: mode,
          onChanged: (value) {
            if (value == null) return;
            context.read<AllocationSettingsBloc>().add(
              AllocationSuggestionSignalChanged(value),
            );
          },
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            TasklyTokens.of(context).spaceLg,
            0,
            TasklyTokens.of(context).spaceLg,
            TasklyTokens.of(context).spaceSm,
          ),
          child: Text(
            'Ratings mode requires weekly ratings and may change suggestions '
            'more quickly.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ValuesBalanceSection extends StatelessWidget {
  const _ValuesBalanceSection({required this.settings});

  final AllocationConfig settings;

  @override
  Widget build(BuildContext context) {
    final mode = settings.strategySettings.enableNeglectWeighting
        ? ValuesBalanceMode.balanceOverTime
        : ValuesBalanceMode.prioritizeTopValues;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Values balance'),
        RadioListTile<ValuesBalanceMode>(
          title: const Text('Balance over time'),
          subtitle: const Text(
            'Suggest more from values you\u2019ve done less of, while still '
            'giving more weight to higher-priority values overall.',
          ),
          value: ValuesBalanceMode.balanceOverTime,
          groupValue: mode,
          onChanged: (value) {
            if (value == null) return;
            context.read<AllocationSettingsBloc>().add(
              AllocationValuesBalanceModeChanged(value),
            );
          },
        ),
        RadioListTile<ValuesBalanceMode>(
          title: const Text('Prioritize top values'),
          subtitle: const Text(
            'Keep suggestions tightly aligned to your highest-priority values, '
            'even if other values are neglected.',
          ),
          value: ValuesBalanceMode.prioritizeTopValues,
          groupValue: mode,
          onChanged: (value) {
            if (value == null) return;
            context.read<AllocationSettingsBloc>().add(
              AllocationValuesBalanceModeChanged(value),
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXs2,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
