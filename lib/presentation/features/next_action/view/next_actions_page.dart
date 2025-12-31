import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_orchestrator.dart';
import 'package:taskly_bloc/presentation/features/next_action/bloc/allocation_bloc.dart';
import 'package:taskly_bloc/presentation/features/next_action/view/allocation_view.dart';

/// Page wrapper for Next Actions screen with bloc provider
class NextActionsPage extends StatelessWidget {
  const NextActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AllocationBloc(
        orchestrator: getIt<AllocationOrchestrator>(),
      )..add(const AllocationSubscriptionRequested()),
      child: const NextActionsView(),
    );
  }
}
