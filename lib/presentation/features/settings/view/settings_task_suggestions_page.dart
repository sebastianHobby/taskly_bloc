import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/allocation_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_ui/taskly_ui_primitives.dart';
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
          title: Text(context.l10n.settingsTaskSuggestionsTitle),
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
                  _SettingsSectionPadding(
                    child: _SuggestionSignalCard(settings: state.settings),
                  ),
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

class _SuggestionSignalCard extends StatefulWidget {
  const _SuggestionSignalCard({required this.settings});

  final AllocationConfig settings;

  @override
  State<_SuggestionSignalCard> createState() => _SuggestionSignalCardState();
}

class _SuggestionSignalCardState extends State<_SuggestionSignalCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final mode = switch (settings.suggestionSignal) {
      SuggestionSignal.behaviorBased => SuggestionSignalOption.behaviorBased,
      SuggestionSignal.ratingsBased => SuggestionSignalOption.ratingsBased,
    };
    final summary = mode == SuggestionSignalOption.behaviorBased
        ? context.l10n.suggestionSignalBehaviorSummary
        : context.l10n.suggestionSignalRatingsSummary;
    final tokens = TasklyTokens.of(context);

    return TasklySettingsCard(
      title: context.l10n.suggestionSignalTitle,
      subtitle: context.l10n.suggestionSignalSubtitle,
      summary: summary,
      isExpanded: _isExpanded,
      onExpandedChanged: (next) => setState(() => _isExpanded = next),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioListTile<SuggestionSignalOption>(
            title: Text(context.l10n.suggestionSignalBehaviorTitle),
            subtitle: Text(context.l10n.suggestionSignalBehaviorSubtitle),
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
            title: Text(context.l10n.suggestionSignalRatingsTitle),
            subtitle: Text(context.l10n.suggestionSignalRatingsSubtitle),
            value: SuggestionSignalOption.ratingsBased,
            groupValue: mode,
            onChanged: (value) {
              if (value == null) return;
              context.read<AllocationSettingsBloc>().add(
                AllocationSuggestionSignalChanged(value),
              );
            },
          ),
          SizedBox(height: tokens.spaceXs),
          Text(
            context.l10n.suggestionSignalRatingsFootnote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionPadding extends StatelessWidget {
  const _SettingsSectionPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        0,
      ),
      child: child,
    );
  }
}
