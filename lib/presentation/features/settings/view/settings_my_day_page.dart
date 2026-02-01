import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsMyDayPage extends StatelessWidget {
  const SettingsMyDayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Day'),
      ),
      body: BlocBuilder<GlobalSettingsBloc, GlobalSettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = state.settings;

          return ResponsiveBody(
            isExpandedLayout: context.isExpandedScreen,
            child: ListView(
              children: [
                _MyDayShowRoutinesToggle(settings: settings),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MyDayShowRoutinesToggle extends StatelessWidget {
  const _MyDayShowRoutinesToggle({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: const Text('Show routines'),
      subtitle: const Text('Include routines as a guided step.'),
      value: settings.myDayShowRoutines,
      onChanged: (enabled) {
        context.read<GlobalSettingsBloc>().add(
          GlobalSettingsEvent.myDayShowRoutinesChanged(enabled),
        );
      },
    );
  }
}
