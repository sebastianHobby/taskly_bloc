import 'package:flutter/material.dart';

class TasklyBadge extends StatelessWidget {
  const TasklyBadge({
    required this.label,
    required this.color,
    super.key,
    this.icon,
    this.isOutlined = false,
  });
  final String label;
  final IconData? icon;
  final Color color;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOutlined ? null : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
        border: isOutlined ? Border.all(color: color) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
