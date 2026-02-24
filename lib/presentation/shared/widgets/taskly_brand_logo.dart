import 'package:flutter/material.dart';

class TasklyBrandLogo extends StatelessWidget {
  const TasklyBrandLogo({
    required this.size,
    super.key,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        'assets/branding/logo_l1.png',
        fit: BoxFit.contain,
        alignment: Alignment.center,
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
