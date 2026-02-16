import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/micro_learning/bloc/micro_learning_bloc.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsMicroLearningPage extends StatelessWidget {
  const SettingsMicroLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = TasklyTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsMicroLearningTitle)),
      body: ListView(
        padding: EdgeInsets.all(tokens.spaceLg),
        children: [
          Text(
            l10n.settingsMicroLearningDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: tokens.spaceMd),
          FilledButton.icon(
            onPressed: () {
              context.read<MicroLearningBloc>().add(
                const MicroLearningReplayRequested(),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.settingsMicroLearningReplayDone)),
              );
            },
            icon: const Icon(Icons.refresh),
            label: Text(l10n.settingsMicroLearningReplayAction),
          ),
        ],
      ),
    );
  }
}
