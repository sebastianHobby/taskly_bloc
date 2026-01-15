import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_support_section_widgets.dart';

class AttentionBannerSectionRendererV2 extends StatelessWidget {
  const AttentionBannerSectionRendererV2({
    required this.data,
    super.key,
    this.title,
  });

  final SectionDataResult data;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final result = data as AttentionBannerV2SectionResult;

    final showReviews = result.reviewCount > 0;
    final showAlerts = result.alertsCount > 0;
    final showAny = showReviews || showAlerts;

    final doneCount = result.doneCount;
    final totalCount = result.totalCount;
    final fraction = totalCount <= 0
        ? 0.0
        : (doneCount / totalCount).clamp(0.0, 1.0);

    final width = MediaQuery.sizeOf(context).width;
    final useHorizontalScroll = width < 480;

    final progressLabel = totalCount > 0
        ? 'My Day • $doneCount/$totalCount completed'
        : 'My Day';

    Widget buildAllClearChip() {
      return Chip(
        label: const Text('All clear'),
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: scheme.outlineVariant),
      );
    }

    final chips = <Widget>[];
    if (showReviews) {
      chips.add(
        ActionChip(
          label: Text('Reviews • ${result.reviewCount}'),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            Routing.toScreenKeyWithQuery(
              context,
              result.overflowScreenKey,
              queryParameters: const {'bucket': 'review'},
            );
          },
        ),
      );
    }
    if (showAlerts) {
      chips.add(
        ActionChip(
          label: Text('Alerts • ${result.alertsCount}'),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            Routing.toScreenKeyWithQuery(
              context,
              result.overflowScreenKey,
              queryParameters: const {'bucket': 'warning'},
            );
          },
        ),
      );
    }

    return SupportSectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Routing.toScreenKey(context, result.overflowScreenKey);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      showAny
                          ? Icons.notifications_none
                          : Icons.check_circle_outline,
                      color: scheme.onSurfaceVariant,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: useHorizontalScroll
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: _CollapsedChipsRow(
                                  showReviews: showReviews,
                                  showAlerts: showAlerts,
                                  showAny: showAny,
                                  result: result,
                                  overflowScreenKey: result.overflowScreenKey,
                                  buildAllClearChip: buildAllClearChip,
                                ),
                              )
                            : _CollapsedChipsRow(
                                showReviews: showReviews,
                                showAlerts: showAlerts,
                                showAny: showAny,
                                result: result,
                                overflowScreenKey: result.overflowScreenKey,
                                buildAllClearChip: buildAllClearChip,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: useHorizontalScroll ? 160 : 220,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wb_sunny,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              progressLabel,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (totalCount > 0) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 3,
                backgroundColor: scheme.outlineVariant.withOpacity(0.35),
                color: scheme.primary.withOpacity(0.70),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CollapsedChipsRow extends StatelessWidget {
  const _CollapsedChipsRow({
    required this.showReviews,
    required this.showAlerts,
    required this.showAny,
    required this.result,
    required this.overflowScreenKey,
    required this.buildAllClearChip,
  });

  final bool showReviews;
  final bool showAlerts;
  final bool showAny;
  final AttentionBannerV2SectionResult result;
  final String overflowScreenKey;
  final Widget Function() buildAllClearChip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showReviews) ...[
          ActionChip(
            label: Text('Reviews • ${result.reviewCount}'),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Routing.toScreenKeyWithQuery(
                context,
                overflowScreenKey,
                queryParameters: const {'bucket': 'review'},
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        if (showAlerts) ...[
          ActionChip(
            label: Text('Alerts • ${result.alertsCount}'),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Routing.toScreenKeyWithQuery(
                context,
                overflowScreenKey,
                queryParameters: const {'bucket': 'warning'},
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        if (!showAny) ...[
          buildAllClearChip(),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}
