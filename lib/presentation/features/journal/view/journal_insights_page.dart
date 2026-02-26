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
                              return _TopInsightHeroCard(
                                insight: insight,
                                delta: delta,
                                confidenceLabel: confidenceLabel,
                              );
                            }

                            return _InsightEvidenceCard(
                              insight: insight,
                              delta: delta,
                              confidenceLabel: confidenceLabel,
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

class _TopInsightHeroCard extends StatelessWidget {
  const _TopInsightHeroCard({
    required this.insight,
    required this.delta,
    required this.confidenceLabel,
  });

  final JournalTopInsight insight;
  final String delta;
  final String confidenceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    return Container(
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceContainerHigh,
            theme.colorScheme.surfaceContainerLow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOP INSIGHT',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: tokens.spaceXxs),
          Text(
            '${insight.factorName} vs Mood',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: tokens.spaceXs),
          Text(
            '$delta Mood ${insight.deltaMood >= 0 ? 'Increase' : 'Drop'}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Last ${insight.windowDays} Days',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spaceSm),
          Container(
            height: 96,
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceXs),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: CustomPaint(
              painter: _InsightSparklinePainter(
                color: theme.colorScheme.primary,
                baseline: theme.colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
          ),
          SizedBox(height: tokens.spaceXs),
          Text(
            context.l10n.journalTopInsightMeta(
              confidenceLabel,
              insight.sampleSize,
              insight.windowDays,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightEvidenceCard extends StatelessWidget {
  const _InsightEvidenceCard({
    required this.insight,
    required this.delta,
    required this.confidenceLabel,
  });

  final JournalTopInsight insight;
  final String delta;
  final String confidenceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    return Container(
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  insight.factorName,
                  style: theme.textTheme.titleMedium?.copyWith(
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
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(tokens.radiusPill),
                ),
                child: Text(
                  confidenceLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
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
            style: theme.textTheme.bodyLarge?.copyWith(
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightSparklinePainter extends CustomPainter {
  const _InsightSparklinePainter({
    required this.color,
    required this.baseline,
  });

  final Color color;
  final Color baseline;

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = baseline
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width, size.height * 0.75),
      guide,
    );

    final points = <Offset>[
      Offset(size.width * 0.02, size.height * 0.68),
      Offset(size.width * 0.18, size.height * 0.62),
      Offset(size.width * 0.30, size.height * 0.80),
      Offset(size.width * 0.45, size.height * 0.28),
      Offset(size.width * 0.60, size.height * 0.72),
      Offset(size.width * 0.78, size.height * 0.36),
      Offset(size.width * 0.96, size.height * 0.42),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cp1 = Offset((prev.dx + curr.dx) / 2, prev.dy);
      final cp2 = Offset((prev.dx + curr.dx) / 2, curr.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _InsightSparklinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.baseline != baseline;
  }
}
