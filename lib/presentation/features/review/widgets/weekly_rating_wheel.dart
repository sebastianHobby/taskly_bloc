import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/review/bloc/weekly_review_cubit.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class WeeklyRatingWheel extends StatelessWidget {
  const WeeklyRatingWheel({
    required this.entries,
    required this.maxRating,
    required this.selectedValueId,
    required this.onValueSelected,
    required this.onRatingChanged,
    super.key,
  });

  final List<WeeklyReviewRatingEntry> entries;
  final int maxRating;
  final String? selectedValueId;
  final ValueChanged<String> onValueSelected;
  final void Function(String valueId, int rating) onRatingChanged;

  static const double _hubRadiusFactor = 0.18;
  static const double _sliceGapRadians = 0.08;
  static const double _ringGap = 2.5;

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

    final selectedIndex = entries.indexWhere(
      (entry) => entry.value.id == selectedValueId,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final hit = _hitTest(details.localPosition, size);
            if (hit == null) return;
            onValueSelected(hit.valueId);
            if (hit.rating != null) {
              onRatingChanged(hit.valueId, hit.rating!);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _WeeklyRatingWheelPainter(
                  entries: entries,
                  colors: colors,
                  maxRating: maxRating,
                  hubRadiusFactor: _hubRadiusFactor,
                  ringGap: _ringGap,
                  sliceGapRadians: _sliceGapRadians,
                  selectedIndex: selectedIndex,
                  hubColor: Theme.of(context).colorScheme.surface,
                  hubBorderColor: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              ..._buildIconOverlays(
                context,
                size: size,
                colors: colors,
              ),
            ],
          ),
        );
      },
    );
  }

  _HitResult? _hitTest(Offset position, Size size) {
    if (entries.isEmpty) return null;

    final center = Offset(size.width / 2, size.height / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final radius = math.min(size.width, size.height) / 2;
    final hubRadius = radius * _hubRadiusFactor;

    if (distance < hubRadius || distance > radius) return null;

    var angle = math.atan2(dy, dx);
    angle = (angle + math.pi * 2 + math.pi / 2) % (math.pi * 2);

    final sliceAngle = (math.pi * 2) / entries.length;
    final sliceIndex = (angle / sliceAngle).floor().clamp(
      0,
      entries.length - 1,
    );
    final valueId = entries[sliceIndex].value.id;

    final available = radius - hubRadius;
    final ringThickness = (available - _ringGap * (maxRating - 1)) / maxRating;
    final relative = distance - hubRadius;
    final ringSpan = ringThickness + _ringGap;
    final ringIndex = (relative / ringSpan).floor();
    final ringOffset = relative - ringIndex * ringSpan;
    if (ringIndex < 0 || ringIndex >= maxRating) {
      return _HitResult(valueId: valueId);
    }
    if (ringOffset > ringThickness) {
      return _HitResult(valueId: valueId);
    }

    return _HitResult(
      valueId: valueId,
      rating: ringIndex + 1,
    );
  }

  List<Widget> _buildIconOverlays(
    BuildContext context, {
    required Size size,
    required List<Color> colors,
  }) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final iconRadius = radius + 18;
    final labelRadius = radius + 38;
    final sliceAngle = (math.pi * 2) / entries.length;
    const startAngle = -math.pi / 2;

    final tokens = TasklyTokens.of(context);
    final overlays = <Widget>[];

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final angle = startAngle + i * sliceAngle + sliceAngle / 2;
      final iconOffset = Offset(
        center.dx + math.cos(angle) * iconRadius,
        center.dy + math.sin(angle) * iconRadius,
      );
      final labelOffset = Offset(
        center.dx + math.cos(angle) * labelRadius,
        center.dy + math.sin(angle) * labelRadius,
      );
      final iconData = getIconDataFromName(entry.value.iconName) ?? Icons.star;
      final color = colors[i];

      overlays.add(
        Positioned(
          left: iconOffset.dx - tokens.spaceMd2,
          top: iconOffset.dy - tokens.spaceMd2,
          child: Icon(
            iconData,
            size: tokens.spaceMd2,
            color: color,
          ),
        ),
      );
      overlays.add(
        Positioned(
          left: labelOffset.dx - 30,
          top: labelOffset.dy - 8,
          width: 60,
          child: Text(
            entry.value.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return overlays;
  }
}

class _WeeklyRatingWheelPainter extends CustomPainter {
  _WeeklyRatingWheelPainter({
    required this.entries,
    required this.colors,
    required this.maxRating,
    required this.hubRadiusFactor,
    required this.ringGap,
    required this.sliceGapRadians,
    required this.selectedIndex,
    required this.hubColor,
    required this.hubBorderColor,
  });

  final List<WeeklyReviewRatingEntry> entries;
  final List<Color> colors;
  final int maxRating;
  final double hubRadiusFactor;
  final double ringGap;
  final double sliceGapRadians;
  final int selectedIndex;
  final Color hubColor;
  final Color hubBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final hubRadius = radius * hubRadiusFactor;

    final available = radius - hubRadius;
    final ringThickness = (available - ringGap * (maxRating - 1)) / maxRating;
    final sliceAngle = (math.pi * 2) / entries.length;
    final gapAngle = sliceGapRadians;
    const startAngle = -math.pi / 2;

    for (var sliceIndex = 0; sliceIndex < entries.length; sliceIndex++) {
      final color = colors[sliceIndex];
      final rating = entries[sliceIndex].rating;
      final sliceStart = startAngle + sliceIndex * sliceAngle + gapAngle / 2;
      final sweep = sliceAngle - gapAngle;

      for (var ringIndex = 0; ringIndex < maxRating; ringIndex++) {
        final innerRadius = hubRadius + ringIndex * (ringThickness + ringGap);
        final outerRadius = innerRadius + ringThickness;
        final rectOuter = Rect.fromCircle(center: center, radius: outerRadius);
        final rectInner = Rect.fromCircle(center: center, radius: innerRadius);

        final isFilled = rating >= ringIndex + 1;
        final paint = Paint()
          ..color = isFilled ? color.withOpacity(0.92) : color.withOpacity(0.18)
          ..style = PaintingStyle.fill;

        final path = Path()
          ..addArc(rectOuter, sliceStart, sweep)
          ..arcTo(rectInner, sliceStart + sweep, -sweep, false)
          ..close();

        canvas.drawPath(path, paint);
      }
    }

    final spokePaint = Paint()
      ..color = hubBorderColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i < entries.length; i++) {
      final angle = startAngle + i * sliceAngle;
      final start = Offset(
        center.dx + math.cos(angle) * hubRadius,
        center.dy + math.sin(angle) * hubRadius,
      );
      final end = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawLine(start, end, spokePaint);
    }

    if (selectedIndex >= 0 && selectedIndex < entries.length) {
      final highlightPaint = Paint()
        ..color = colors[selectedIndex].withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final sliceStart = startAngle + selectedIndex * sliceAngle + gapAngle / 2;
      final sweep = sliceAngle - gapAngle;
      final rectOuter = Rect.fromCircle(center: center, radius: radius);
      final rectInner = Rect.fromCircle(center: center, radius: hubRadius);
      final path = Path()
        ..addArc(rectOuter, sliceStart, sweep)
        ..arcTo(rectInner, sliceStart + sweep, -sweep, false)
        ..close();
      canvas.drawPath(path, highlightPaint);
    }

    final hubPaint = Paint()..color = hubColor;
    canvas.drawCircle(center, hubRadius, hubPaint);
    canvas.drawCircle(
      center,
      hubRadius,
      Paint()
        ..color = hubBorderColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _WeeklyRatingWheelPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.colors != colors;
  }
}

class _HitResult {
  const _HitResult({
    required this.valueId,
    this.rating,
  });

  final String valueId;
  final int? rating;
}
