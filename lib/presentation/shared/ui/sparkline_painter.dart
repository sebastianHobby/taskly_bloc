import 'package:flutter/material.dart';

/// Custom painter for simple sparkline charts.
///
/// This is render-only and takes already-prepared numeric series.
class SparklinePainter extends CustomPainter {
  SparklinePainter({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = data.length > 1
          ? i * size.width / (data.length - 1)
          : size.width / 2;
      final normalizedY = range > 0 ? (data[i] - minVal) / range : 0.5;
      final y =
          size.height - (normalizedY * size.height * 0.8 + size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return data != oldDelegate.data || color != oldDelegate.color;
  }
}
