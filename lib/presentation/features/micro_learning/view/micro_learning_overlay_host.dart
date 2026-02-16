import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/micro_learning/bloc/micro_learning_bloc.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class MicroLearningOverlayHost extends StatefulWidget {
  const MicroLearningOverlayHost({
    required this.currentPath,
    required this.child,
    super.key,
  });

  final String currentPath;
  final Widget child;

  @override
  State<MicroLearningOverlayHost> createState() =>
      _MicroLearningOverlayHostState();
}

class _MicroLearningOverlayHostState extends State<MicroLearningOverlayHost> {
  bool _started = false;
  bool _presenting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final bloc = context.read<MicroLearningBloc>();
    bloc.add(const MicroLearningStarted());
    bloc.add(MicroLearningRouteVisited(widget.currentPath));
  }

  @override
  void didUpdateWidget(covariant MicroLearningOverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath == widget.currentPath) return;
    context.read<MicroLearningBloc>().add(
      MicroLearningRouteVisited(widget.currentPath),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MicroLearningBloc, MicroLearningState>(
      listenWhen: (previous, current) =>
          previous.activeTipId != current.activeTipId &&
          current.activeTipId != null,
      listener: (_, state) async {
        final tipId = state.activeTipId;
        if (tipId == null || _presenting) return;
        _presenting = true;
        await _showTip(tipId);
        if (!mounted) return;
        _presenting = false;
        this.context.read<MicroLearningBloc>().add(
          MicroLearningTipDismissed(tipId),
        );
      },
      child: widget.child,
    );
  }

  Future<void> _showTip(String tipId) {
    if (!mounted) return Future<void>.value();
    final l10n = context.l10n;
    final tip = _tipCopyFor(l10n, tipId);
    final tokens = TasklyTokens.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useRootNavigator: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            tokens.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tip.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.spaceSm),
              Text(
                tip.body,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: tokens.spaceMd),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.microLearningGotItLabel),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _TipCopy _tipCopyFor(AppLocalizations l10n, String tipId) {
    return switch (tipId) {
      MicroLearningTips.myDay => _TipCopy(
        title: l10n.microLearningMyDayTitle,
        body: l10n.microLearningMyDayBody,
      ),
      MicroLearningTips.planMyDay => _TipCopy(
        title: l10n.microLearningPlanMyDayTitle,
        body: l10n.microLearningPlanMyDayBody,
      ),
      MicroLearningTips.projects => _TipCopy(
        title: l10n.microLearningProjectsTitle,
        body: l10n.microLearningProjectsBody,
      ),
      MicroLearningTips.scheduled => _TipCopy(
        title: l10n.microLearningScheduledTitle,
        body: l10n.microLearningScheduledBody,
      ),
      MicroLearningTips.projectDetail => _TipCopy(
        title: l10n.microLearningProjectDetailTitle,
        body: l10n.microLearningProjectDetailBody,
      ),
      MicroLearningTips.routineDetail => _TipCopy(
        title: l10n.microLearningRoutineDetailTitle,
        body: l10n.microLearningRoutineDetailBody,
      ),
      _ => _TipCopy(
        title: l10n.settingsTitle,
        body: '',
      ),
    };
  }
}

final class _TipCopy {
  const _TipCopy({required this.title, required this.body});

  final String title;
  final String body;
}
