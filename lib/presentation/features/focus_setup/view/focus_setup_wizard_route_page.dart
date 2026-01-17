import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/bloc/focus_setup_bloc.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/view/focus_setup_wizard_page.dart';
import 'package:taskly_domain/contracts.dart';

class FocusSetupWizardRoutePage extends StatelessWidget {
  const FocusSetupWizardRoutePage({super.key, this.initialStep});

  final FocusSetupWizardStep? initialStep;

  static FocusSetupWizardStep? parseInitialStep(Uri uri) {
    final step = uri.queryParameters['step'];
    return switch (step) {
      'select_focus_mode' => FocusSetupWizardStep.selectFocusMode,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FocusSetupBloc(
        settingsRepository: getIt<SettingsRepositoryContract>(),
        valueRepository: getIt(),
      )..add(FocusSetupEvent.started(initialStep: initialStep)),
      child: const FocusSetupWizardPage(),
    );
  }
}
