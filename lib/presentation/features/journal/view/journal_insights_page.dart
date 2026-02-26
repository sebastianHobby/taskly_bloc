import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalInsightsPage extends StatelessWidget {
  const JournalInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalHistoryBloc>(
      create: (context) => JournalHistoryBloc(
        repository: context.read<JournalRepositoryContract>(),
        dayKeyService: context.read<HomeDayKeyService>(),
        settingsRepository: context.read<SettingsRepositoryContract>(),
        nowUtc: context.read<NowService>().nowUtc,
      )..add(const JournalHistoryStarted()),
      child: BlocBuilder<JournalHistoryBloc, JournalHistoryState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          final tokens = TasklyTokens.of(context);
          final loaded = state is JournalHistoryLoaded ? state : null;
          final insights = loaded?.insights ?? const <JournalTopInsight>[];

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: Text(context.l10n.journalInsightsTitle),
            ),
            body: switch (state) {
              JournalHistoryLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              JournalHistoryError(:final message) => Center(
                child: Padding(
                  padding: EdgeInsets.all(tokens.spaceLg),
                  child: Text(message),
                ),
              ),
              JournalHistoryLoaded() =>
                insights.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(tokens.spaceLg),
                          child: Text(
                            context.l10n.journalInsightsNudge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.surface,
                              theme.colorScheme.surfaceContainerLow,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            tokens.spaceLg,
                            tokens.spaceMd,
                            tokens.spaceLg,
                            tokens.spaceLg,
                          ),
                          itemCount: insights.length + 1,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: tokens.spaceMd),
                          itemBuilder: (context, index) {
                            final insight =
                                insights[index == 0 ? 0 : index - 1];
                            final deltaValue = insight.deltaMood
                                .abs()
                                .toStringAsFixed(
                                  1,
                                );
                            final delta = insight.deltaMood >= 0
                                ? '+$deltaValue'
                                : '-$deltaValue';
                            final confidenceLabel =
                                insight.confidence ==
                                    JournalInsightConfidence.high
                                ? context.l10n.journalInsightHighConfidence
                                : context.l10n.journalInsightMediumConfidence;

                            if (index == 0) {
                              return Container(
                                padding: EdgeInsets.all(tokens.spaceMd),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.surfaceContainerHigh,
                                      theme.colorScheme.surfaceContainer,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    tokens.radiusLg,
                                  ),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOP INSIGHT',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    SizedBox(height: tokens.spaceXxs),
                                    Text(
                                      '${context.l10n.journalInsightsTitle}: ${insight.factorName}',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    SizedBox(height: tokens.spaceXs),
                                    Text(
                                      context.l10n.journalTopInsightAssociated(
                                        insight.factorName,
                                        delta,
                                      ),
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    SizedBox(height: tokens.spaceXxs),
                                    Text(
                                      context.l10n.journalTopInsightMeta(
                                        confidenceLabel,
                                        insight.sampleSize,
                                        insight.windowDays,
                                      ),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Card(
                              color: theme.colorScheme.surfaceContainerLow,
                              child: Padding(
                                padding: EdgeInsets.all(tokens.spaceMd),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            insight.factorName,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: tokens.spaceXs,
                                            vertical: tokens.spaceXxs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              tokens.radiusPill,
                                            ),
                                          ),
                                          child: Text(
                                            confidenceLabel,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: tokens.spaceXs),
                                    Text(
                                      context.l10n.journalTopInsightAssociated(
                                        insight.factorName,
                                        delta,
                                      ),
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    SizedBox(height: tokens.spaceXxs),
                                    Text(
                                      context.l10n.journalTopInsightMeta(
                                        confidenceLabel,
                                        insight.sampleSize,
                                        insight.windowDays,
                                      ),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            },
          );
        },
      ),
    );
  }
}
