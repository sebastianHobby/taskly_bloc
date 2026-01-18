import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/widgets/my_day_hero_card.dart';
import 'package:taskly_bloc/presentation/screens/widgets/my_day_task_list_section.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_focus_mode_required_page.dart';

class MyDayPage extends StatelessWidget {
  const MyDayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MyDayGateBloc>(create: (_) => getIt<MyDayGateBloc>()),
        BlocProvider<MyDayBloc>(create: (_) => getIt<MyDayBloc>()),
      ],
      child: BlocBuilder<MyDayGateBloc, MyDayGateState>(
        builder: (context, gateState) {
          return switch (gateState) {
            MyDayGateLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            MyDayGateError(:final message) => Center(child: Text(message)),
            MyDayGateLoaded(
              :final needsFocusModeSetup,
              :final needsValuesSetup,
            ) =>
              (needsFocusModeSetup || needsValuesSetup)
                  ? const MyDayFocusModeRequiredPage()
                  : const _MyDayLoadedBody(),
          };
        },
      ),
    );
  }
}

class _MyDayLoadedBody extends StatelessWidget {
  const _MyDayLoadedBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyDayBloc, MyDayState>(
      builder: (context, state) {
        return switch (state) {
          MyDayLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          MyDayError(:final message) => Center(child: Text(message)),
          MyDayLoaded(:final summary, :final mix, :final tasks) => Scaffold(
            body: SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: MyDayHeroCard(summary: summary),
                  ),
                  MyDayTaskListSection(
                    tasks: tasks,
                    mix: mix,
                  ),
                ],
              ),
            ),
          ),
        };
      },
    );
  }
}
