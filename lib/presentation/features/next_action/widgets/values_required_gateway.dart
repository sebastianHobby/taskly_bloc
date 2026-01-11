import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

/// Full-screen gateway shown when user has no values defined.
///
/// Explains the purpose of values-based allocation. User must set up
/// values to use Focus - there is no skip option.
class ValuesRequiredGateway extends StatelessWidget {
  const ValuesRequiredGateway({
    required this.onSetUpValues,
    super.key,
    this.title,
  });

  /// Called when "Set Up My Values" is tapped.
  final VoidCallback onSetUpValues;

  /// Optional title for the app bar.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? l10n.nextActionsTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Icon
              Icon(
                Icons.balance,
                size: 72,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                l10n.valuesGatewayTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                l10n.valuesGatewayDescription,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Primary CTA - only option
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSetUpValues,
                  icon: const Icon(Icons.star_outline),
                  label: Text(l10n.setUpMyValues),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
