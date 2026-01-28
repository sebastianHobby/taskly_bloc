import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/model/guided_tour_step.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/view/guided_tour_previews.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/view/guided_tour_targets.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class GuidedTourOverlayHost extends StatefulWidget {
  const GuidedTourOverlayHost({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<GuidedTourOverlayHost> createState() => _GuidedTourOverlayHostState();
}

class _GuidedTourOverlayHostState extends State<GuidedTourOverlayHost> {
  final GuidedTourTargetRegistry _registry = GuidedTourTargetRegistry();

  @override
  Widget build(BuildContext context) {
    return GuidedTourTargetScope(
      registry: _registry,
      child: MultiBlocListener(
        listeners: [
          BlocListener<GuidedTourBloc, GuidedTourState>(
            listenWhen: (prev, next) =>
                prev.navRequestId != next.navRequestId && next.active,
            listener: (context, state) {
              final step = state.currentStep;
              if (step == null) return;
              final router = GoRouter.of(context);
              final location = router.routerDelegate.currentConfiguration.uri
                  .toString();
              if (location != step.route) {
                router.go(step.route);
              }
            },
          ),
          BlocListener<GlobalSettingsBloc, GlobalSettingsState>(
            listenWhen: (prev, next) =>
                prev.settings.guidedTourCompleted !=
                    next.settings.guidedTourCompleted ||
                prev.settings.onboardingCompleted !=
                    next.settings.onboardingCompleted,
            listener: (context, state) {
              final shouldStart =
                  state.settings.onboardingCompleted &&
                  !state.settings.guidedTourCompleted;
              final tour = context.read<GuidedTourBloc>();
              if (shouldStart && !tour.state.active) {
                tour.add(const GuidedTourStarted());
              }
            },
          ),
        ],
        child: Stack(
          children: [
            widget.child,
            const _GuidedTourOverlay(),
          ],
        ),
      ),
    );
  }
}

class _GuidedTourOverlay extends StatelessWidget {
  const _GuidedTourOverlay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GuidedTourBloc, GuidedTourState>(
      builder: (context, state) {
        if (!state.active) return const SizedBox.shrink();
        final step = state.currentStep;
        if (step == null) return const SizedBox.shrink();

        return Stack(
          children: [
            const ModalBarrier(
              dismissible: false,
              color: Color(0xAA000000),
            ),
            if (step.kind == GuidedTourStepKind.card)
              _GuidedTourCard(step: step, state: state)
            else
              _GuidedTourCoachmark(step: step, state: state),
            _GuidedTourControls(state: state),
          ],
        );
      },
    );
  }
}

class _GuidedTourCard extends StatelessWidget {
  const _GuidedTourCard({
    required this.step,
    required this.state,
  });

  final GuidedTourStep step;
  final GuidedTourState state;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final previewType = step.previewType;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLg,
          tokens.spaceLg,
          tokens.spaceLg,
          tokens.spaceXl * 1.6,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: tokens.spaceSm),
                Text(
                  step.body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: tokens.spaceLg),
                if (previewType != null)
                  GuidedTourPreview(type: previewType)
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidedTourCoachmark extends StatelessWidget {
  const _GuidedTourCoachmark({
    required this.step,
    required this.state,
  });

  final GuidedTourStep step;
  final GuidedTourState state;

  @override
  Widget build(BuildContext context) {
    final coachmark = step.coachmark;
    if (coachmark == null) {
      return const SizedBox.shrink();
    }

    final registry = GuidedTourTargetScope.of(context);
    final rect = registry?.rectFor(coachmark.targetId);
    if (rect == null) {
      return _CoachmarkBubble(
        title: coachmark.title,
        body: coachmark.body,
        alignment: Alignment.bottomCenter,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final overlayBox = context.findRenderObject() as RenderBox?;
        if (overlayBox == null) {
          return _CoachmarkBubble(
            title: coachmark.title,
            body: coachmark.body,
            alignment: Alignment.bottomCenter,
          );
        }

        final topLeft = overlayBox.globalToLocal(rect.topLeft);
        final localRect = Rect.fromLTWH(
          topLeft.dx,
          topLeft.dy,
          rect.width,
          rect.height,
        );

        return Stack(
          children: [
            Positioned.fromRect(
              rect: localRect.inflate(6),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: tokensFor(context).spaceLg,
              right: tokensFor(context).spaceLg,
              top: _bubbleTopFor(localRect, constraints.maxHeight),
              child: _CoachmarkBubble(
                title: coachmark.title,
                body: coachmark.body,
                alignment: Alignment.center,
              ),
            ),
          ],
        );
      },
    );
  }

  double _bubbleTopFor(Rect target, double height) {
    const gap = 16.0;
    final below = target.bottom + gap;
    if (below + 120 < height) return below;
    final above = target.top - gap - 120;
    return above.clamp(24.0, height - 160.0);
  }

  TasklyTokens tokensFor(BuildContext context) => TasklyTokens.of(context);
}

class _CoachmarkBubble extends StatelessWidget {
  const _CoachmarkBubble({
    required this.title,
    required this.body,
    required this.alignment,
  });

  final String title;
  final String body;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: alignment,
      child: Container(
        padding: EdgeInsets.all(tokens.spaceMd),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: tokens.spaceXs),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidedTourControls extends StatelessWidget {
  const _GuidedTourControls({required this.state});

  final GuidedTourState state;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final stepIndex = state.currentIndex + 1;
    final stepCount = state.steps.length;
    final isLast = !state.hasNext;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            tokens.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Step $stepIndex of $stepCount',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: tokens.spaceSm),
              Row(
                children: [
                  if (state.hasPrevious)
                    TextButton(
                      onPressed: () => context.read<GuidedTourBloc>().add(
                        const GuidedTourBackRequested(),
                      ),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 72),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.read<GuidedTourBloc>().add(
                      const GuidedTourSkipped(),
                    ),
                    child: const Text('Skip'),
                  ),
                  SizedBox(width: tokens.spaceSm),
                  FilledButton(
                    onPressed: () => context.read<GuidedTourBloc>().add(
                      const GuidedTourNextRequested(),
                    ),
                    child: Text(isLast ? 'Finish' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
