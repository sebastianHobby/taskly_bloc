import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/theme/taskly_semantic_themes.dart';

class TasklyReveal extends StatefulWidget {
  const TasklyReveal({
    required this.child,
    this.delay = Duration.zero,
    this.duration,
    this.curve,
    this.offset,
    this.startScale,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration? duration;
  final Curve? curve;
  final Offset? offset;
  final double? startScale;

  @override
  State<TasklyReveal> createState() => _TasklyRevealState();
}

class _TasklyRevealState extends State<TasklyReveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.delay > Duration.zero) {
        await Future<void>.delayed(widget.delay);
      }
      if (!mounted) return;
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final motion = TasklyMotionTheme.of(context);
    return AnimatedSlide(
      duration: widget.duration ?? motion.mediumDuration,
      curve: widget.curve ?? motion.emphasizedCurve,
      offset: _visible ? Offset.zero : (widget.offset ?? motion.sectionOffset),
      child: AnimatedScale(
        duration: widget.duration ?? motion.mediumDuration,
        curve: widget.curve ?? motion.emphasizedCurve,
        scale: _visible ? 1 : (widget.startScale ?? motion.pageScale),
        child: AnimatedOpacity(
          duration: widget.duration ?? motion.mediumDuration,
          curve: widget.curve ?? motion.standardCurve,
          opacity: _visible ? 1 : 0,
          child: widget.child,
        ),
      ),
    );
  }
}
