import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/theme/taskly_semantic_themes.dart';

class TasklyPageGradientSurface extends StatelessWidget {
  const TasklyPageGradientSurface({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final panelTheme = TasklyPanelTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            panelTheme.gradientStart,
            panelTheme.gradientEnd,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -56,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    radius: 0.92,
                    colors: [
                      panelTheme.ambientPrimary,
                      panelTheme.ambientPrimary.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: const SizedBox(width: 280, height: 280),
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: -88,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    radius: 1,
                    colors: [
                      panelTheme.ambientSecondary,
                      panelTheme.ambientSecondary.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: const SizedBox(width: 232, height: 232),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
