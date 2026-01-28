import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class GuidedTourTargetRegistry extends ChangeNotifier {
  final Map<String, Rect> _targets = {};
  bool _notifyQueued = false;

  void register(String id, Rect rect) {
    _targets[id] = rect;
    _notifySafely();
  }

  void unregister(String id) {
    if (_targets.remove(id) != null) {
      _notifySafely();
    }
  }

  Rect? rectFor(String id) => _targets[id];

  void _notifySafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
      return;
    }

    if (_notifyQueued) return;
    _notifyQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyQueued = false;
      if (!hasListeners) return;
      notifyListeners();
    });
  }
}

class GuidedTourTargetScope
    extends InheritedNotifier<GuidedTourTargetRegistry> {
  const GuidedTourTargetScope({
    required GuidedTourTargetRegistry registry,
    required super.child,
    super.key,
  }) : super(notifier: registry);

  static GuidedTourTargetRegistry? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GuidedTourTargetScope>()
        ?.notifier;
  }
}

class GuidedTourTarget extends StatefulWidget {
  const GuidedTourTarget({
    required this.id,
    required this.child,
    super.key,
  });

  final String id;
  final Widget child;

  @override
  State<GuidedTourTarget> createState() => _GuidedTourTargetState();
}

class _GuidedTourTargetState extends State<GuidedTourTarget> {
  GuidedTourTargetRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextRegistry = GuidedTourTargetScope.of(context);
    if (!identical(_registry, nextRegistry)) {
      _registry?.unregister(widget.id);
      _registry = nextRegistry;
    }
    _updateTarget();
  }

  @override
  void didUpdateWidget(covariant GuidedTourTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _registry?.unregister(oldWidget.id);
    }
    _updateTarget();
  }

  @override
  void dispose() {
    _registry?.unregister(widget.id);
    super.dispose();
  }

  void _updateTarget() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final registry = _registry;
      if (registry == null) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final topLeft = box.localToGlobal(Offset.zero);
      final rect = topLeft & box.size;
      registry.register(widget.id, rect);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
