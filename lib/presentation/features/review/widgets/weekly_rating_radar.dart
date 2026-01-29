import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/review/bloc/weekly_review_cubit.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class WeeklyRatingRadar extends StatelessWidget {
  const WeeklyRatingRadar({
    required this.entries,
    required this.maxRating,
    required this.selectedValueId,
    this.onIconTap,
    this.showIcons = true,
    super.key,
  });

  final List<WeeklyReviewRatingEntry> entries;
  final int maxRating;
  final String? selectedValueId;
  final ValueChanged<String>? onIconTap;
  final bool showIcons;

  static const int _ringCount = 4;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final colors = entries
        .map(
          (entry) => ColorUtils.valueColorForTheme(
            context,
            entry.value.color,
          ),
        )
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tokens = TasklyTokens.of(context);
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final minSide = math.min(size.width, size.height);
        final chartInset = tokens.spaceLg2 + tokens.spaceSm;
        final chartRadius = minSide / 2 - chartInset;
        final iconRadius = chartRadius + tokens.spaceLg2;
        final badgeSize = tokens.spaceLg3 + tokens.spaceSm;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: size,
              painter: _WeeklyRatingRadarPainter(
                entries: entries,
                colors: colors,
                maxRating: maxRating,
                selectedValueId: selectedValueId,
                ringCount: _ringCount,
                chartRadius: chartRadius,
                handleRadius: tokens.spaceXs,
                selectedHandleRadius: tokens.spaceSm,
                gridColor: Theme.of(context).colorScheme.outlineVariant,
                axisColor: Theme.of(context).colorScheme.outlineVariant,
                polygonFillColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                polygonStrokeColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                surfaceColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            if (showIcons)
              ..._buildIconBadges(
                context,
                size: size,
                radius: iconRadius,
                badgeSize: badgeSize,
                colors: colors,
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildIconBadges(
    BuildContext context, {
    required Size size,
    required double radius,
    required double badgeSize,
    required List<Color> colors,
  }) {
    final center = Offset(size.width / 2, size.height / 2);
    final sliceAngle = (math.pi * 2) / entries.length;
    const startAngle = -math.pi / 2;
    final tokens = TasklyTokens.of(context);

    return List<Widget>.generate(entries.length, (index) {
      final entry = entries[index];
      final angle = startAngle + index * sliceAngle;
      final position = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final color = colors[index];
      final icon = getIconDataFromName(entry.value.iconName) ?? Icons.star;
      final isSelected = entry.value.id == selectedValueId;
      final scale = isSelected ? 1.15 : 1.0;
      final background = color.withValues(alpha: isSelected ? 0.2 : 0.12);
      final border = color.withValues(alpha: isSelected ? 0.4 : 0.25);

      return Positioned(
        left: position.dx - badgeSize / 2,
        top: position.dy - badgeSize / 2,
        child: Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: onIconTap == null ? null : () => onIconTap!(entry.value.id),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                border: Border.all(color: border),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: tokens.spaceSm,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: color,
                size: tokens.spaceMd2,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _WeeklyRatingRadarPainter extends CustomPainter {
  _WeeklyRatingRadarPainter({
    required this.entries,
    required this.colors,
    required this.maxRating,
    required this.selectedValueId,
    required this.ringCount,
    required this.chartRadius,
    required this.handleRadius,
    required this.selectedHandleRadius,
    required this.gridColor,
    required this.axisColor,
    required this.polygonFillColor,
    required this.polygonStrokeColor,
    required this.surfaceColor,
  });

  final List<WeeklyReviewRatingEntry> entries;
  final List<Color> colors;
  final int maxRating;
  final String? selectedValueId;
  final int ringCount;
  final double chartRadius;
  final double handleRadius;
  final double selectedHandleRadius;
  final Color gridColor;
  final Color axisColor;
  final Color polygonFillColor;
  final Color polygonStrokeColor;
  final Color surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final sliceAngle = (math.pi * 2) / entries.length;
    const startAngle = -math.pi / 2;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var ringIndex = 1; ringIndex <= ringCount; ringIndex++) {
      final ringRadius = chartRadius * ringIndex / ringCount;
      final path = Path();
      for (var i = 0; i < entries.length; i++) {
        final angle = startAngle + i * sliceAngle;
        final point = Offset(
          center.dx + math.cos(angle) * ringRadius,
          center.dy + math.sin(angle) * ringRadius,
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final spokePaint = Paint()
      ..color = axisColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < entries.length; i++) {
      final angle = startAngle + i * sliceAngle;
      final end = Offset(
        center.dx + math.cos(angle) * chartRadius,
        center.dy + math.sin(angle) * chartRadius,
      );
      _drawDashedLine(canvas, center, end, spokePaint, 6, 8);
    }

    final valuesPath = Path();
    for (var i = 0; i < entries.length; i++) {
      final rating = entries[i].rating.clamp(0, maxRating);
      final ratio = rating / maxRating;
      final angle = startAngle + i * sliceAngle;
      final point = Offset(
        center.dx + math.cos(angle) * chartRadius * ratio,
        center.dy + math.sin(angle) * chartRadius * ratio,
      );
      if (i == 0) {
        valuesPath.moveTo(point.dx, point.dy);
      } else {
        valuesPath.lineTo(point.dx, point.dy);
      }
    }
    valuesPath.close();

    final fillPaint = Paint()
      ..color = polygonFillColor.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawPath(valuesPath, fillPaint);

    final strokePaint = Paint()
      ..color = polygonStrokeColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(valuesPath, strokePaint);

    final selectedIndex = entries.indexWhere(
      (entry) => entry.value.id == selectedValueId,
    );
    if (selectedIndex >= 0 && selectedIndex < entries.length) {
      final rating = entries[selectedIndex].rating.clamp(0, maxRating);
      final ratio = rating / maxRating;
      final angle = startAngle + selectedIndex * sliceAngle;
      final selectedPoint = Offset(
        center.dx + math.cos(angle) * chartRadius * ratio,
        center.dy + math.sin(angle) * chartRadius * ratio,
      );
      final linePaint = Paint()
        ..color = colors[selectedIndex].withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      _drawDashedLine(canvas, center, selectedPoint, linePaint, 6, 8);
    }

    for (var i = 0; i < entries.length; i++) {
      final rating = entries[i].rating.clamp(0, maxRating);
      final ratio = rating / maxRating;
      final angle = startAngle + i * sliceAngle;
      final point = Offset(
        center.dx + math.cos(angle) * chartRadius * ratio,
        center.dy + math.sin(angle) * chartRadius * ratio,
      );
      final color = colors[i];
      final isSelected = entries[i].value.id == selectedValueId;
      final radius = isSelected ? selectedHandleRadius : handleRadius;

      if (isSelected) {
        final shadowPath = Path()
          ..addOval(Rect.fromCircle(center: point, radius: radius + 2));
        canvas.drawShadow(
          shadowPath,
          color.withValues(alpha: 0.35),
          12,
          false,
        );
      }

      final fill = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, radius, fill);

      if (isSelected) {
        final border = Paint()
          ..color = surfaceColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(point, radius, border);
      }
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashLength,
    double gapLength,
  ) {
    final totalLength = (end - start).distance;
    final direction = (end - start) / totalLength;
    var distance = 0.0;
    while (distance < totalLength) {
      final currentStart = start + direction * distance;
      final currentEnd =
          start + direction * math.min(distance + dashLength, totalLength);
      canvas.drawLine(currentStart, currentEnd, paint);
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyRatingRadarPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.selectedValueId != selectedValueId ||
        oldDelegate.maxRating != maxRating ||
        oldDelegate.colors != colors;
  }
}
