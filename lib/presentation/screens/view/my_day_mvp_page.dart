import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/my_day_ranked_tasks_v1_module_interpreter.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_mvp_bloc.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/my_day_hero_v1_section.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/my_day_ranked_tasks_v1_section.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_focus_mode_required_page.dart';

class MyDayMvpPage extends StatelessWidget {
  const MyDayMvpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MyDayGateBloc>(create: (_) => getIt<MyDayGateBloc>()),
        BlocProvider<MyDayMvpBloc>(
          create: (_) => MyDayMvpBloc(
            interpreter: getIt<MyDayRankedTasksV1ModuleInterpreter>(),
          ),
        ),
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
                  : const _MyDayMvpLoadedBody(),
          };
        },
      ),
    );
  }
}

class _MyDayMvpLoadedBody extends StatelessWidget {
  const _MyDayMvpLoadedBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyDayMvpBloc, MyDayMvpState>(
      builder: (context, state) {
        return switch (state) {
          MyDayMvpLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          MyDayMvpError(:final message) => Center(child: Text(message)),
          MyDayMvpLoaded(:final hero, :final rankedTasks) => Scaffold(
            body: SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: MyDayHeroV1Section(data: hero)),
                  MyDayRankedTasksV1Section(
                    data: rankedTasks.items,
                    title: 'Today',
                    enrichment: rankedTasks.enrichment,
                    entityStyle: const EntityStyleV1(),
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
