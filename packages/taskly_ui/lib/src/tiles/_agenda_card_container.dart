import 'package:flutter/material.dart';

class AgendaCardContainer extends StatelessWidget {
  const AgendaCardContainer({
    required this.child,
    required this.backgroundColor,
    required this.outlineColor,
    super.key,
    this.accentColor,
    this.dashedOutline = false,
  });

  final Widget child;
  final Color backgroundColor;
  final Color outlineColor;
  final Color? accentColor;
  final bool dashedOutline;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    if (!dashedOutline) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: radius,
          border: accentColor != null
              ? Border(
                  left: BorderSide(color: accentColor!, width: 4),
                  top: BorderSide(color: outlineColor),
                  right: BorderSide(color: outlineColor),
                  bottom: BorderSide(color: outlineColor),
                )
              : Border.all(color: outlineColor),
        ),
        child: child,
      );
    }

    final dashColor =
        Color.lerp(
          accentColor ?? outlineColor,
          outlineColor,
          0.35,
        )?.withValues(alpha: 0.85) ??
        outlineColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(color: backgroundColor),
          child: CustomPaint(
            foregroundPainter: _DashedRoundedRectPainter(
              color: dashColor,
              strokeWidth: 1.2,
              radius: 16,
              dashLength: 6,
              gapLength: 4,
            ),
            child: Stack(
              children: [
                if (accentColor != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4,
                    child: ColoredBox(color: accentColor!),
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}

class EndDayMarker extends StatelessWidget {
  const EndDayMarker({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.hourglass_bottom_rounded,
          size: 16,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 10,
            height: 1.1,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
