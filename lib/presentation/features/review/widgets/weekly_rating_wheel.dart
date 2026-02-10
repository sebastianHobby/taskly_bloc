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
    this.enableTap = true,
  });

  final List<WeeklyReviewRatingEntry> entries;
  final int maxRating;
  final String? selectedValueId;
  final ValueChanged<String> onValueSelected;
  final void Function(String valueId, int rating) onRatingChanged;
  final bool enableTap;

  static const double _hubRadiusFactor = 0.14;
  static const double _sliceGapRadians = 0;
  static const double _ringGap = 0;

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

        return IgnorePointer(
          ignoring: !enableTap,
          child: GestureDetector(
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
              clipBehavior: Clip.none,
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
                    hubBorderColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant,
                    gridColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
                ..._buildIconOverlays(
                  context,
                  size: size,
                  colors: colors,
                ),
              ],
            ),
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
    final tokens = TasklyTokens.of(context);
    final iconRadius = radius + tokens.spaceSm;
    final sliceAngle = (math.pi * 2) / entries.length;
    const startAngle = -math.pi / 2;

    final scheme = Theme.of(context).colorScheme;
    final overlays = <Widget>[];

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final angle = startAngle + i * sliceAngle + sliceAngle / 2;
      final iconOffset = Offset(
        center.dx + math.cos(angle) * iconRadius,
        center.dy + math.sin(angle) * iconRadius,
      );
      final iconData = getIconDataFromName(entry.value.iconName) ?? Icons.star;
      final color = colors[i];
      final isSelected = entry.value.id == selectedValueId;
      final scale = isSelected ? 1.05 : 1.0;
      final background = isSelected
          ? scheme.surfaceContainerHighest
          : Colors.transparent;
      final border = isSelected
          ? color.withValues(alpha: 0.6)
          : Colors.transparent;
      final iconColor = isSelected
          ? color
          : scheme.onSurfaceVariant.withValues(alpha: 0.7);
      final iconSize = tokens.spaceMd2;
      final targetSize = tokens.minTapTargetSize;

      overlays.add(
        Positioned(
          left: iconOffset.dx - targetSize / 2,
          top: iconOffset.dy - targetSize / 2,
          child: Transform.scale(
            scale: scale,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onValueSelected(entry.value.id),
              child: Container(
                width: targetSize,
                height: targetSize,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  border: Border.all(color: border),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.25),
                            blurRadius: tokens.spaceXs2,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  iconData,
                  size: iconSize,
                  color: iconColor,
                ),
              ),
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
    required this.gridColor,
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
  final Color gridColor;

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
      final basePaint = Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final rectOuter = Rect.fromCircle(center: center, radius: radius);
      final rectInner = Rect.fromCircle(center: center, radius: hubRadius);
      final basePath = Path()
        ..addArc(rectOuter, sliceStart, sweep)
        ..arcTo(rectInner, sliceStart + sweep, -sweep, false)
        ..close();
      canvas.drawPath(basePath, basePaint);

      final clampedRating = rating.clamp(0, maxRating);
      if (clampedRating > 0) {
        final filledRadius =
            hubRadius +
            clampedRating * ringThickness +
            math.max(0, clampedRating - 1) * ringGap;
        final filledOuter = Rect.fromCircle(
          center: center,
          radius: filledRadius,
        );
        final filledPath = Path()
          ..addArc(filledOuter, sliceStart, sweep)
          ..arcTo(rectInner, sliceStart + sweep, -sweep, false)
          ..close();
        final fillPaint = Paint()
          ..color = color.withValues(alpha: 0.9)
          ..style = PaintingStyle.fill;
        canvas.drawPath(filledPath, fillPaint);
      }
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    for (var ringIndex = 1; ringIndex <= maxRating; ringIndex++) {
      final ringRadius = hubRadius + ringIndex * (ringThickness + ringGap);
      canvas.drawCircle(center, ringRadius, gridPaint);
    }
    for (var sliceIndex = 0; sliceIndex < entries.length; sliceIndex++) {
      final angle = startAngle + sliceIndex * sliceAngle;
      final lineEnd = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final lineStart = Offset(
        center.dx + math.cos(angle) * hubRadius,
        center.dy + math.sin(angle) * hubRadius,
      );
      canvas.drawLine(lineStart, lineEnd, gridPaint);
    }

    if (selectedIndex >= 0 && selectedIndex < entries.length) {
      final sliceStart = startAngle + selectedIndex * sliceAngle + gapAngle / 2;
      final sweep = sliceAngle - gapAngle;
      final selectedRating = entries[selectedIndex].rating.clamp(0, maxRating);
      final selectedOuterRadius = selectedRating == 0
          ? radius
          : hubRadius +
                selectedRating * ringThickness +
                math.max(0, selectedRating - 1) * ringGap;
      final rectOuter = Rect.fromCircle(
        center: center,
        radius: selectedOuterRadius,
      );
      final rectInner = Rect.fromCircle(center: center, radius: hubRadius);
      final path = Path()
        ..addArc(rectOuter, sliceStart, sweep)
        ..arcTo(rectInner, sliceStart + sweep, -sweep, false)
        ..close();

      final glowPaint = Paint()
        ..color = colors[selectedIndex].withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5);
      canvas.drawPath(path, glowPaint);

      final highlightPaint = Paint()
        ..color = colors[selectedIndex].withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
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
        oldDelegate.colors != colors ||
        oldDelegate.gridColor != gridColor;
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
