import 'package:flutter/material.dart';

class TasklyBrandLogo extends StatelessWidget {
  const TasklyBrandLogo.compact({
    this.size = 80,
    super.key,
  }) : _maxHeroSize = 220,
       _minHeroSize = 140,
       maxHeroSize = 220,
       minHeroSize = 140;

  const TasklyBrandLogo.hero({
    this.maxHeroSize = 220,
    this.minHeroSize = 140,
    super.key,
  }) : size = null,
       _maxHeroSize = maxHeroSize,
       _minHeroSize = minHeroSize;

  final double? size;
  final double? _maxHeroSize;
  final double? _minHeroSize;
  final double maxHeroSize;
  final double minHeroSize;

  @override
  Widget build(BuildContext context) {
    if (size != null) {
      return _LogoAsset(size: size!);
    }

    final maxHeroSize = _maxHeroSize!;
    final minHeroSize = _minHeroSize!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : maxHeroSize;
        final dimension = availableWidth.clamp(minHeroSize, maxHeroSize);
        return Center(
          child: _LogoAsset(size: dimension),
        );
      },
    );
  }
}

class _LogoAsset extends StatelessWidget {
  const _LogoAsset({
    required this.size,
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
        filterQuality: FilterQuality.high,
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
