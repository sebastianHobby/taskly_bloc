import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

class AttentionAppBarAccessory extends StatelessWidget {
  const AttentionAppBarAccessory({
    required this.result,
    super.key,
  });

  final AttentionBannerV2SectionResult result;

  static double preferredHeight({required bool showProgressRail}) {
    // Row height + rail + padding.
    return showProgressRail ? 46 : 40;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final showReviews = result.reviewCount > 0;
    final showAlerts = result.alertsCount > 0;
    final showAny = showReviews || showAlerts;

    final doneCount = result.doneCount;
    final totalCount = result.totalCount;
    final hasProgress = totalCount > 0;
    final fraction = hasProgress
        ? (doneCount / totalCount).clamp(0.0, 1.0)
        : 0.0;

    final progressLabel = hasProgress
        ? 'My Day • $doneCount/$totalCount completed'
        : 'My Day';

    final width = MediaQuery.sizeOf(context).width;
    final useHorizontalScroll = width < 480;

    Widget buildAllClearChip() {
      return Chip(
        label: const Text('All clear'),
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: scheme.outlineVariant),
      );
    }

    Widget buildChipRow() {
      final row = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showReviews) ...[
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
            const SizedBox(width: 8),
          ],
          if (showAlerts) ...[
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
            const SizedBox(width: 8),
          ],
          if (!showAny) buildAllClearChip(),
        ],
      );

      if (!useHorizontalScroll) return row;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: row,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Routing.toScreenKey(context, result.overflowScreenKey),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    showAny
                        ? Icons.notifications_none
                        : Icons.check_circle_outline,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: buildChipRow(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: useHorizontalScroll ? 160 : 240,
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
              if (hasProgress) ...[
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
        ),
      ),
    );
  }
}
