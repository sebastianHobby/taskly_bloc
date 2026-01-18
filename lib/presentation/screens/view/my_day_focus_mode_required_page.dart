import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';

/// Full-screen gate shown when My Day prerequisites are missing.
class MyDayFocusModeRequiredPage extends StatelessWidget {
  const MyDayFocusModeRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    MyDayGateBloc? existing;
    try {
      existing = context.read<MyDayGateBloc>();
    } catch (_) {
      existing = null;
    }

    if (existing != null) {
      return const _MyDayFocusModeRequiredView();
    }

    final theme = Theme.of(context);
    final now = getIt<NowService>().nowLocal();
    final dateLabel = DateFormat('EEEE, MMM d').format(now).toUpperCase();

    return BlocProvider<MyDayGateBloc>(
      create: (_) => getIt<MyDayGateBloc>(),
      child: _MyDayFocusModeRequiredView(theme: theme, dateLabel: dateLabel),
    );
  }
}

class _MyDayFocusModeRequiredView extends StatelessWidget {
  const _MyDayFocusModeRequiredView({this.theme, this.dateLabel});

  final ThemeData? theme;
  final String? dateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? Theme.of(context);
    final now = getIt<NowService>().nowLocal();
    final dateLabel =
        this.dateLabel ??
      DateFormat('EEEE, MMM d').format(now).toUpperCase();

    return BlocBuilder<MyDayGateBloc, MyDayGateState>(
      builder: (context, state) {
        return switch (state) {
          MyDayGateLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          MyDayGateError(:final message) => Center(child: Text(message)),
          MyDayGateLoaded(
            :final needsFocusModeSetup,
            :final needsValuesSetup,
            :final ctaIcon,
            :final descriptionText,
          ) =>
            Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final heroHeight = (constraints.maxHeight * 0.55).clamp(
                      360.0,
                      520.0,
                    );

                    return SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            children: [
                              SizedBox(
                                height: heroHeight,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // No tree image: gradient-only hero background.
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            theme.colorScheme.primary
                                                .withOpacity(0.22),
                                            theme.scaffoldBackgroundColor,
                                          ],
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        height: heroHeight * 0.55,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              theme.scaffoldBackgroundColor,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        12,
                                        20,
                                        0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  dateLabel,
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 1.2,
                                                      ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'My Day',
                                                  style: theme
                                                      .textTheme
                                                      .displaySmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            height: 44,
                                            width: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: theme.colorScheme.surface
                                                  .withOpacity(0.55),
                                              border: Border.all(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.12),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.person,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  96,
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.25),
                                        ),
                                      ),
                                      child: Text(
                                        'WELCOME TO TASKLY',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 2.2,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: 'Plan Your Life Around\n',
                                          ),
                                          TextSpan(
                                            // No underline: plain primary emphasis.
                                            text: 'What Matters',
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            height: 1.1,
                                          ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      descriptionText,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            height: 1.45,
                                          ),
                                    ),
                                    const SizedBox(height: 22),
                                    _MyDaySetupStepCard(
                                      stepNumber: 1,
                                      title: 'Choose your focus mode',
                                      subtitle:
                                          'So Taskly can shape Today around your preferences.',
                                      icon: Icons.tune,
                                      isComplete: !needsFocusModeSetup,
                                      ctaLabel: needsFocusModeSetup
                                          ? 'Start focus setup'
                                          : 'Change focus mode',
                                      onPressed: () {
                                        context.push(
                                          Routing.screenPath('focus_setup'),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _MyDaySetupStepCard(
                                      stepNumber: 2,
                                      title: 'Add your first value',
                                      subtitle:
                                          'Values help Taskly prioritize what matters most.',
                                      icon: Icons.favorite_outline,
                                      isComplete: !needsValuesSetup,
                                      ctaLabel: needsValuesSetup
                                          ? 'Add values'
                                          : 'Manage values',
                                      onPressed: () {
                                        if (needsValuesSetup) {
                                          Routing.toValueNew(context);
                                          return;
                                        }

                                        Routing.toScreenKeyWithQuery(
                                          context,
                                          'manage_values',
                                          queryParameters: const {
                                            'source': 'my_day_gate',
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed:
                                            (!needsFocusModeSetup &&
                                                !needsValuesSetup)
                                            ? () => context.go(
                                                Routing.screenPath('my_day'),
                                              )
                                            : null,
                                        icon: Icon(
                                          (!needsFocusModeSetup &&
                                                  !needsValuesSetup)
                                              ? Icons.arrow_forward
                                              : ctaIcon,
                                        ),
                                        label: const Text(
                                          'Continue to My Day',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        };
      },
    );
  }
}

class _MyDaySetupStepCard extends StatelessWidget {
  const _MyDaySetupStepCard({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isComplete,
    required this.ctaLabel,
    required this.onPressed,
  });

  final int stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isComplete;
  final String ctaLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final borderColor = isComplete
        ? scheme.onSurface.withOpacity(0.10)
        : scheme.primary.withOpacity(0.35);

    final pillColor = isComplete
        ? scheme.surfaceContainerHighest.withOpacity(0.55)
        : scheme.primary.withOpacity(0.12);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerHighest.withOpacity(0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pillColor,
                    border: Border.all(
                      color: borderColor,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isComplete
                      ? Icon(Icons.check, color: scheme.primary)
                      : Text(
                          '$stepNumber',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isComplete
                  ? OutlinedButton.icon(
                      onPressed: onPressed,
                      icon: Icon(icon),
                      label: Text(ctaLabel),
                    )
                  : FilledButton.icon(
                      onPressed: onPressed,
                      icon: Icon(icon),
                      label: Text(ctaLabel),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
