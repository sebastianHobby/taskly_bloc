import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/features/app/view/app.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/guided_tour_anchors.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/model/guided_tour_step.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

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
  static const int _maxCoachmarkAttempts = 200;
  static const Duration _coachmarkRetryDelay = Duration(milliseconds: 50);
  TutorialCoachMark? _coachMark;
  int _showToken = 0;
  int _navToken = 0;
  String? _pendingRoute;
  OverlayState? _rootOverlay;
  AppLifecycleListener? _lifecycleListener;
  bool _abortRequested = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _onAppLifecycleChanged,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rootOverlay =
        App.navigatorKey.currentState?.overlay ??
        Overlay.maybeOf(context, rootOverlay: true);
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _dismissCoachMark();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GuidedTourBloc, GuidedTourState>(
          listenWhen: (prev, next) =>
              prev.navRequestId != next.navRequestId ||
              prev.active != next.active,
          listener: _onTourStateChanged,
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
      child: widget.child,
    );
  }

  void _onTourStateChanged(BuildContext context, GuidedTourState state) {
    _dismissCoachMark();
    if (!state.active) {
      _abortRequested = false;
      _cancelPendingNavigation();
      return;
    }

    final step = state.currentStep;
    if (step == null) {
      _cancelPendingNavigation();
      return;
    }

    if (!_isOnRoute(step.route)) {
      _scheduleNavigation(step);
      return;
    }

    _pendingRoute = null;

    _scheduleShow(step);
  }

  void _onAppLifecycleChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    _abortTour(GuidedTourAbortReason.appPaused);
  }

  void _scheduleShow(GuidedTourStep step) {
    final token = ++_showToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || token != _showToken) return;
      _attemptShow(step, 0);
    });
  }

  void _attemptShow(GuidedTourStep step, int attempt) {
    final state = context.read<GuidedTourBloc>().state;
    if (!state.active || state.currentStep?.id != step.id) return;
    if (!_isOnRoute(step.route)) {
      if (attempt < _maxCoachmarkAttempts) {
        Future<void>.delayed(_coachmarkRetryDelay, () {
          if (!mounted) return;
          _attemptShow(step, attempt + 1);
        });
      } else {
        _abortTour(GuidedTourAbortReason.routeTimeout);
      }
      return;
    }

    if (_shouldWaitForPlanMyDay(step)) {
      if (kDebugMode) {
        debugPrint(
          '[GuidedTourOverlay] waiting for PlanMyDay ready '
          '(step=${step.id}, attempt=$attempt)',
        );
      }
      if (attempt < _maxCoachmarkAttempts) {
        Future<void>.delayed(_coachmarkRetryDelay, () {
          if (!mounted) return;
          _attemptShow(step, attempt + 1);
        });
      } else {
        _abortTour(GuidedTourAbortReason.planMyDayTimeout);
      }
      return;
    }

    if (step.kind == GuidedTourStepKind.coachmark) {
      final coachmark = step.coachmark;
      final key = coachmark == null
          ? null
          : GuidedTourAnchors.keyFor(coachmark.targetId);
      _logAnchorStatus(step, attempt, key: key);
      if (key == null || key.currentContext == null) {
        if (kDebugMode) {
          debugPrint(
            '[GuidedTourOverlay] waiting for anchor '
            '(step=${step.id}, target=${coachmark?.targetId}, attempt=$attempt)',
          );
        }
        if (attempt < _maxCoachmarkAttempts) {
          Future<void>.delayed(_coachmarkRetryDelay, () {
            if (!mounted) return;
            _attemptShow(step, attempt + 1);
          });
        } else {
          _abortTour(GuidedTourAbortReason.anchorTimeout);
        }
        return;
      }

      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is RenderBox && !renderObject.hasSize) {
        if (kDebugMode) {
          debugPrint(
            '[GuidedTourOverlay] anchor has no size '
            '(step=${step.id}, target=${coachmark?.targetId}, attempt=$attempt)',
          );
        }
        if (attempt < _maxCoachmarkAttempts) {
          Future<void>.delayed(_coachmarkRetryDelay, () {
            if (!mounted) return;
            _attemptShow(step, attempt + 1);
          });
        } else {
          _abortTour(GuidedTourAbortReason.anchorTimeout);
        }
        return;
      }
    }

    _showCoachMark(step, state);
  }

  bool _shouldWaitForPlanMyDay(GuidedTourStep step) {
    if (!step.id.startsWith('plan_my_day_')) return false;

    PlanMyDayBloc bloc;
    try {
      bloc = context.read<PlanMyDayBloc>();
    } catch (_) {
      return false;
    }

    final state = bloc.state;
    if (kDebugMode) {
      debugPrint(
        '[GuidedTourOverlay] plan state check '
        '(step=${step.id}, current=${state.runtimeType})',
      );
    }
    return state is! PlanMyDayReady;
  }

  void _showCoachMark(GuidedTourStep step, GuidedTourState state) {
    final tokens = TasklyTokens.of(context);
    final target = _buildTarget(step, state, tokens);
    final coachMark = TutorialCoachMark(
      targets: [target],
      hideSkip: true,
      paddingFocus: tokens.spaceSm,
      opacityShadow: 0.72,
    );
    _coachMark = coachMark;
    final navigatorState = App.navigatorKey.currentState;
    if (navigatorState != null) {
      coachMark.showWithNavigatorStateKey(
        navigatorKey: App.navigatorKey,
        rootOverlay: true,
      );
      return;
    }

    final overlay = _rootOverlay;
    if (overlay != null) {
      coachMark.showWithOverlayState(
        overlay: overlay,
        rootOverlay: true,
      );
      return;
    }

    coachMark.show(context: context);
  }

  void _scheduleNavigation(GuidedTourStep step) {
    if (_pendingRoute == step.route) return;
    _pendingRoute = step.route;
    final token = ++_navToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || token != _navToken) return;
      _dismissTransientRoutes();
      if (!_isOnRoute(step.route)) {
        GoRouter.of(context).go(step.route);
      }
      _waitForRouteAndShow(step, 0, token);
    });
  }

  void _waitForRouteAndShow(GuidedTourStep step, int attempt, int token) {
    if (!mounted || token != _navToken) return;
    if (_isOnRoute(step.route)) {
      _pendingRoute = null;
      _scheduleShow(step);
      return;
    }
    if (attempt < _maxCoachmarkAttempts) {
      Future<void>.delayed(_coachmarkRetryDelay, () {
        if (!mounted) return;
        _waitForRouteAndShow(step, attempt + 1, token);
      });
    } else {
      _abortTour(GuidedTourAbortReason.routeTimeout);
    }
  }

  bool _isOnRoute(String route) {
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    return location == route;
  }

  TargetFocus _buildTarget(
    GuidedTourStep step,
    GuidedTourState state,
    TasklyTokens tokens,
  ) {
    final coachmarkLayout = step.kind == GuidedTourStepKind.coachmark
        ? _computeCoachmarkLayout(step, tokens)
        : null;
    final content = TargetContent(
      align: ContentAlign.custom,
      customPosition: step.kind == GuidedTourStepKind.card
          ? CustomTargetContentPosition(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
            )
          : CustomTargetContentPosition(
              top: coachmarkLayout?.top,
              bottom: coachmarkLayout?.bottom,
              left: coachmarkLayout?.left ?? 0,
              right: coachmarkLayout?.right ?? 0,
            ),
      padding: step.kind == GuidedTourStepKind.card
          ? EdgeInsets.zero
          : EdgeInsets.fromLTRB(
              tokens.spaceLg,
              tokens.spaceLg,
              tokens.spaceLg,
              tokens.spaceLg,
            ),
      builder: (context, controller) {
        final card = step.kind == GuidedTourStepKind.card
            ? _GuidedTourFullScreenCard(
                key: Key('guided-tour-card-${step.id}'),
                step: step,
                state: state,
                onBack: state.hasPrevious
                    ? () => _handleBack(controller)
                    : null,
                onNext: () => _handleNext(controller),
                onSkip: () => _handleSkip(controller),
              )
            : _GuidedTourCoachmarkCard(
                key: Key('guided-tour-coachmark-${step.id}'),
                step: step,
                state: state,
                onBack: state.hasPrevious
                    ? () => _handleBack(controller)
                    : null,
                onNext: () => _handleNext(controller),
                onSkip: () => _handleSkip(controller),
              );

        if (step.kind == GuidedTourStepKind.coachmark &&
            coachmarkLayout != null) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: coachmarkLayout.maxHeight,
            ),
            child: SingleChildScrollView(
              child: card,
            ),
          );
        }

        return card;
      },
    );

    if (step.kind == GuidedTourStepKind.card) {
      return TargetFocus(
        identify: step.id,
        targetPosition: TargetPosition(
          MediaQuery.sizeOf(context),
          Offset.zero,
        ),
        shape: ShapeLightFocus.RRect,
        radius: 0,
        enableOverlayTab: false,
        enableTargetTab: false,
        contents: [content],
      );
    }

    final coachmark = step.coachmark;
    final key = coachmark == null
        ? null
        : GuidedTourAnchors.keyFor(coachmark.targetId);
    return TargetFocus(
      identify: step.id,
      keyTarget: key,
      targetPosition: key == null
          ? TargetPosition(MediaQuery.sizeOf(context), Offset.zero)
          : null,
      shape: ShapeLightFocus.RRect,
      radius: tokens.radiusLg,
      enableOverlayTab: false,
      enableTargetTab: false,
      contents: [content],
    );
  }

  _CoachmarkLayout? _computeCoachmarkLayout(
    GuidedTourStep step,
    TasklyTokens tokens,
  ) {
    final anchorId = step.coachmark?.targetId;
    final anchorKey = anchorId == null
        ? null
        : GuidedTourAnchors.keyFor(anchorId);
    final anchorContext = anchorKey?.currentContext;
    if (anchorContext == null) return null;
    final overlayContext =
        _rootOverlay?.context ??
        Overlay.maybeOf(context, rootOverlay: true)?.context ??
        context;
    final overlayBox = overlayContext.findRenderObject();
    final targetBox = anchorContext.findRenderObject();
    if (overlayBox is! RenderBox || targetBox is! RenderBox) return null;
    if (!overlayBox.hasSize || !targetBox.hasSize) return null;

    final topLeft = targetBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final targetRect = topLeft & targetBox.size;

    final media = MediaQuery.of(context);
    final safeTop = media.padding.top + tokens.spaceSm;
    final safeBottom = media.padding.bottom + tokens.spaceSm;
    final gap = tokens.spaceMd;

    final availableAbove = (targetRect.top - safeTop - gap).clamp(
      0.0,
      double.infinity,
    );
    final availableBelow =
        ((overlayBox.size.height - safeBottom) - targetRect.bottom - gap).clamp(
          0.0,
          double.infinity,
        );

    final placeBelow =
        availableBelow >= 180 || availableBelow >= availableAbove;
    final maxHeight = placeBelow ? availableBelow : availableAbove;

    return _CoachmarkLayout(
      top: placeBelow ? targetRect.bottom + gap : null,
      bottom: placeBelow
          ? null
          : (overlayBox.size.height - targetRect.top + gap),
      left: 0,
      right: 0,
      maxHeight: maxHeight,
    );
  }

  void _handleNext(TutorialCoachMarkController controller) {
    context.read<GuidedTourBloc>().add(const GuidedTourNextRequested());
    controller.skip();
  }

  void _handleBack(TutorialCoachMarkController controller) {
    context.read<GuidedTourBloc>().add(const GuidedTourBackRequested());
    controller.skip();
  }

  void _handleSkip(TutorialCoachMarkController controller) {
    context.read<GuidedTourBloc>().add(const GuidedTourSkipped());
    controller.skip();
  }

  void _dismissCoachMark() {
    _coachMark?.finish();
    _coachMark = null;
  }

  void _cancelPendingNavigation() {
    _pendingRoute = null;
    _navToken++;
  }

  void _dismissTransientRoutes() {
    final navigator = App.navigatorKey.currentState;
    if (navigator == null) return;
    navigator.popUntil((route) => route is PageRoute);
  }

  void _logAnchorStatus(
    GuidedTourStep step,
    int attempt, {
    GlobalKey? key,
  }) {
    if (!kDebugMode) return;
    if (attempt % 5 != 0) return;

    final targetId = step.coachmark?.targetId;
    if (key == null) {
      debugPrint(
        '[GuidedTourOverlay] anchor key missing '
        '(step=${step.id}, target=$targetId, attempt=$attempt)',
      );
      return;
    }

    final anchorContext = key.currentContext;
    if (anchorContext == null) {
      debugPrint(
        '[GuidedTourOverlay] anchor context null '
        '(step=${step.id}, target=$targetId, attempt=$attempt, key=${key.hashCode})',
      );
      return;
    }

    final renderObject = anchorContext.findRenderObject();
    if (renderObject is RenderBox) {
      debugPrint(
        '[GuidedTourOverlay] anchor render box '
        '(step=${step.id}, target=$targetId, attempt=$attempt, '
        'hasSize=${renderObject.hasSize}, size=${renderObject.hasSize ? renderObject.size : null})',
      );
      return;
    }

    debugPrint(
      '[GuidedTourOverlay] anchor render object '
      '(step=${step.id}, target=$targetId, attempt=$attempt, '
      'type=${renderObject.runtimeType})',
    );
  }

  void _abortTour(GuidedTourAbortReason reason) {
    if (!mounted || _abortRequested) return;
    final bloc = context.read<GuidedTourBloc>();
    if (!bloc.state.active) return;
    _abortRequested = true;
    bloc.add(GuidedTourAborted(reason: reason));
  }
}

class _CoachmarkLayout {
  const _CoachmarkLayout({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.maxHeight,
  });

  final double? top;
  final double? bottom;
  final double left;
  final double right;
  final double maxHeight;
}

class _GuidedTourFullScreenCard extends StatelessWidget {
  const _GuidedTourFullScreenCard({
    required this.step,
    required this.state,
    required this.onNext,
    required this.onSkip,
    this.onBack,
    super.key,
  });

  final GuidedTourStep step;
  final GuidedTourState state;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: scheme.scrim.withValues(alpha: 0.72),
          ),
        ),
        SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: _GuidedTourContentCard(
                step: step,
                state: state,
                onBack: onBack,
                onNext: onNext,
                onSkip: onSkip,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuidedTourCoachmarkCard extends StatelessWidget {
  const _GuidedTourCoachmarkCard({
    required this.step,
    required this.state,
    required this.onNext,
    required this.onSkip,
    this.onBack,
    super.key,
  });

  final GuidedTourStep step;
  final GuidedTourState state;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: _GuidedTourContentCard(
          step: step,
          state: state,
          onBack: onBack,
          onNext: onNext,
          onSkip: onSkip,
        ),
      ),
    );
  }
}

class _GuidedTourContentCard extends StatelessWidget {
  const _GuidedTourContentCard({
    required this.step,
    required this.state,
    required this.onNext,
    required this.onSkip,
    this.onBack,
  });

  final GuidedTourStep step;
  final GuidedTourState state;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: scheme.onSurface,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return DecoratedBox(
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(step.title, style: titleStyle),
            SizedBox(height: tokens.spaceSm),
            Text(step.body, style: bodyStyle),
            SizedBox(height: tokens.spaceLg),
            Row(
              children: [
                if (onBack != null)
                  TextButton(
                    onPressed: onBack,
                    child: const Text('Back'),
                  )
                else
                  const SizedBox(width: 72),
                const Spacer(),
                TextButton(
                  onPressed: onSkip,
                  child: const Text('Skip'),
                ),
                SizedBox(width: tokens.spaceSm),
                FilledButton(
                  onPressed: onNext,
                  child: Text(state.hasNext ? 'Next' : 'Finish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
