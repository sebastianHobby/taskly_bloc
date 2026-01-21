import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/my_day_prewarm_cubit.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_page.dart';

class MyDayEntryGate extends StatefulWidget {
  const MyDayEntryGate({super.key});

  @override
  State<MyDayEntryGate> createState() => _MyDayEntryGateState();
}

class _MyDayEntryGateState extends State<MyDayEntryGate> {
  static const _showDelay = Duration(milliseconds: 150);

  bool _delayElapsed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Avoid a "flash" of a gate UI when prewarm is near-instant.
    _timer = Timer(_showDelay, () {
      if (!mounted) return;
      setState(() => _delayElapsed = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyDayPrewarmCubit, MyDayPrewarmState>(
      builder: (context, state) {
        final status = state.status;

        if (status is MyDayPrewarmReady) {
          return const MyDayPage();
        }

        if (!_delayElapsed) {
          // Short blank scaffold to avoid jitter while deciding whether
          // to show the full prewarm UI.
          return const Scaffold(
            body: SizedBox.expand(),
          );
        }

        return const _PreparingMyDayScreen();
      },
    );
  }
}

class _PreparingMyDayScreen extends StatelessWidget {
  const _PreparingMyDayScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.myDayTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.myDayPreparingTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.myDayPreparingSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
