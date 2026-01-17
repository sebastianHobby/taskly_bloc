import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';

/// Compact, dot-based summary for a list of values.
///
/// Intended for dense tile meta lines where showing many chips would be noisy.
class ValueDotsCluster extends StatelessWidget {
  const ValueDotsCluster({
    required this.values,
    this.maxDots = 3,
    this.dotSize = 10,
    this.overlap = 4,
    this.onTap,
    super.key,
  });

  final List<Value> values;
  final int maxDots;
  final double dotSize;
  final double overlap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || maxDots <= 0) {
      return const SizedBox.shrink();
    }

    final visible = values.take(maxDots).toList(growable: false);
    final names = values.map((v) => v.name).join(', ');

    final effectiveOverlap = overlap.clamp(0.0, dotSize);
    final step = dotSize - effectiveOverlap;
    final width = dotSize + (visible.length - 1) * step;

    final cluster = SizedBox(
      width: width,
      height: dotSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * step,
              child: _ValueDot(
                value: visible[i],
                size: dotSize,
              ),
            ),
        ],
      ),
    );

    Widget result = cluster;

    if (onTap != null) {
      result = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: result,
      );
    }

    return Semantics(
      label: 'Values',
      value: names,
      button: onTap != null,
      child: Tooltip(
        message: names,
        child: result,
      ),
    );
  }
}

class _ValueDot extends StatelessWidget {
  const _ValueDot({required this.value, required this.size});

  final Value value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = ColorUtils.fromHexWithThemeFallback(context, value.color);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.surface,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
