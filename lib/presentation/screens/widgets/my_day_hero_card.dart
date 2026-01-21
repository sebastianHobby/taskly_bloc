import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_header_bloc.dart';

class MyDayHeroCard extends StatelessWidget {
  const MyDayHeroCard({required this.summary, super.key});

  final MyDaySummary summary;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MyDayHeaderBloc>(
      create: (_) => getIt<MyDayHeaderBloc>()..add(const MyDayHeaderStarted()),
      child: BlocListener<MyDayHeaderBloc, MyDayHeaderState>(
        listenWhen: (previous, current) {
          return previous.navRequestId != current.navRequestId &&
              current.nav == MyDayHeaderNav.openFocusSetupWizard;
        },
        listener: (context, state) {
          Routing.toScreenKeyWithQuery(
            context,
            'focus_setup',
            queryParameters: const {'step': 'select_focus_mode'},
          );
        },
        child: _HeroCard(summary: summary),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary});

  final MyDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final doneCount = summary.doneCount;
    final totalCount = summary.totalCount;

    final fraction = totalCount <= 0
        ? 0.0
        : (doneCount / totalCount).clamp(0.0, 1.0);

    final showProgress = totalCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<MyDayHeaderBloc, MyDayHeaderState>(
                builder: (context, state) {
                  final focusMode = state.focusMode;
                  final (icon, iconLabel) = _focusIcon(focusMode);

                  return Semantics(
                    container: true,
                    button: true,
                    label: 'Focus mode',
                    value: '${focusMode.displayName}. ${focusMode.tagline}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        context.read<MyDayHeaderBloc>().add(
                          const MyDayHeaderFocusModeBannerTapped(),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Semantics(
                              label: iconLabel,
                              child: Icon(
                                icon,
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    focusMode.displayName,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    focusMode.tagline,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      height: 1.15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Change',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: cs.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (showProgress) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.wb_sunny,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$doneCount/$totalCount completed',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 4,
                    backgroundColor: cs.outlineVariant.withOpacity(0.35),
                    color: cs.primary.withOpacity(0.70),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  (IconData, String) _focusIcon(FocusMode focusMode) {
    return switch (focusMode) {
      FocusMode.intentional => (Icons.gps_fixed, 'Intentional focus'),
      FocusMode.sustainable => (Icons.balance, 'Sustainable focus'),
      FocusMode.responsive => (Icons.bolt, 'Responsive focus'),
      FocusMode.personalized => (Icons.tune, 'Personalized focus'),
    };
  }
}
