import 'package:flutter/material.dart';

class TasklyBrandLogo extends StatelessWidget {
  const TasklyBrandLogo({
    required this.size,
    super.key,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/branding/logo_l1.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.check_circle_outline,
            size: size,
            color: Theme.of(context).colorScheme.primary,
          );
        },
      ),
    );
  }
}
