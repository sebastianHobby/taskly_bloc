import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/theme/taskly_semantic_theme.dart';

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
      child: child,
    );
  }
}
