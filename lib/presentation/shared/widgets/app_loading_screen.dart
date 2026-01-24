import 'package:flutter/material.dart';

class AppLoadingContent extends StatelessWidget {
  const AppLoadingContent({
    required this.title,
    required this.subtitle,
    this.icon,
    this.progressLabel,
    this.progressValue,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final String? progressLabel;
  final double? progressValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedIcon = icon ?? Icons.sync;
    final label = progressLabel;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              resolvedIcon,
              size: 40,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (progressValue != null)
              LinearProgressIndicator(value: progressValue)
            else
              const LinearProgressIndicator(),
            if (label != null) ...[
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({
    required this.title,
    required this.subtitle,
    this.icon,
    this.progressLabel,
    this.progressValue,
    this.appBarTitle,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final String? progressLabel;
  final double? progressValue;
  final String? appBarTitle;

  @override
  Widget build(BuildContext context) {
    final barTitle = appBarTitle;

    return Scaffold(
      appBar: barTitle == null ? null : AppBar(title: Text(barTitle)),
      body: SafeArea(
        child: Center(
          child: AppLoadingContent(
            title: title,
            subtitle: subtitle,
            icon: icon,
            progressLabel: progressLabel,
            progressValue: progressValue,
          ),
        ),
      ),
    );
  }
}
