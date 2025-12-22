import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A widget that displays label chips with colored icons.
///
/// In truncated mode (default), shows labels in up to 2 lines with a "+X more"
/// indicator if there are more labels than can fit.
///
/// In expanded mode, shows all labels without truncation.
class TruncatedLabelChips extends StatelessWidget {
  const TruncatedLabelChips({
    required this.labels,
    this.truncate = true,
    this.spacing = 8,
    this.runSpacing = 6,
    this.maxLines = 2,
    super.key,
  });

  /// The labels to display.
  final List<Label> labels;

  /// Whether to truncate to [maxLines] with "+X more" indicator.
  /// When false, all labels are shown.
  final bool truncate;

  /// Horizontal spacing between chips.
  final double spacing;

  /// Vertical spacing between lines.
  final double runSpacing;

  /// Maximum number of lines to show when [truncate] is true.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    if (!truncate) {
      // Show all labels without truncation
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: labels.map((label) => _LabelChip(label: label)).toList(),
      );
    }

    // Use the two-line wrap with truncation
    const chipHeight = 22.0;
    final maxHeight = (chipHeight * maxLines) + (runSpacing * (maxLines - 1));

    return _TwoLineWrap(
      maxHeight: maxHeight,
      spacing: spacing,
      runSpacing: runSpacing,
      labels: labels,
      chipBuilder: (label) => _LabelChip(label: label),
      moreTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

/// A chip displaying a single label with its color.
class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label});

  final Label label;

  Color _colorFromHexOrFallback(BuildContext context, String? hex) {
    final normalized = (hex ?? '').replaceAll('#', '');
    if (normalized.length != 6) {
      return Theme.of(context).colorScheme.primary;
    }
    final value = int.tryParse('FF$normalized', radix: 16);
    if (value == null) {
      return Theme.of(context).colorScheme.primary;
    }
    return Color(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorFromHexOrFallback(context, label.color);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label.name,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Internal widget that displays labels in up to a specified number of lines.
class _TwoLineWrap extends StatefulWidget {
  const _TwoLineWrap({
    required this.maxHeight,
    required this.spacing,
    required this.runSpacing,
    required this.labels,
    required this.chipBuilder,
    this.moreTextStyle,
  });

  final double maxHeight;
  final double spacing;
  final double runSpacing;
  final List<Label> labels;
  final Widget Function(Label) chipBuilder;
  final TextStyle? moreTextStyle;

  @override
  State<_TwoLineWrap> createState() => _TwoLineWrapState();
}

class _TwoLineWrapState extends State<_TwoLineWrap> {
  int _visibleCount = 0;
  bool _measured = false;
  final List<GlobalKey> _chipKeys = [];

  @override
  void initState() {
    super.initState();
    _initKeys();
  }

  @override
  void didUpdateWidget(_TwoLineWrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels.length != widget.labels.length ||
        !_listsEqual(oldWidget.labels, widget.labels)) {
      _measured = false;
      _initKeys();
    }
  }

  bool _listsEqual(List<Label> a, List<Label> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _initKeys() {
    _chipKeys.clear();
    for (var i = 0; i < widget.labels.length; i++) {
      _chipKeys.add(GlobalKey());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureChips();
    });
  }

  void _measureChips() {
    if (!mounted) return;

    // Count how many chips fit within maxHeight
    double currentY = 0;
    double currentX = 0;
    double lineHeight = 0;
    int count = 0;

    for (var i = 0; i < _chipKeys.length; i++) {
      final key = _chipKeys[i];
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;

      final size = renderBox.size;
      lineHeight = size.height;

      // Check if we need a new line (use a reasonable max width estimate)
      if (currentX > 0 && currentX + size.width > 280) {
        currentX = 0;
        currentY += lineHeight + widget.runSpacing;
      }

      // Check if still within max height
      if (currentY + lineHeight <= widget.maxHeight) {
        count++;
        currentX += size.width + widget.spacing;
      } else {
        break;
      }
    }

    if (mounted && count != _visibleCount) {
      setState(() {
        _visibleCount = count > 0 ? count : widget.labels.length;
        _measured = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveVisible = _measured ? _visibleCount : widget.labels.length;
    final remaining = widget.labels.length - effectiveVisible;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight + 4),
      child: Wrap(
        spacing: widget.spacing,
        runSpacing: widget.runSpacing,
        clipBehavior: Clip.hardEdge,
        children: [
          // Build chips with keys for measuring
          for (var i = 0; i < widget.labels.length; i++)
            if (!_measured || i < effectiveVisible)
              KeyedSubtree(
                key: _chipKeys.length > i ? _chipKeys[i] : null,
                child: widget.chipBuilder(widget.labels[i]),
              ),
          // Show "+X more" if items are hidden
          if (_measured && remaining > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '+$remaining more',
                style: widget.moreTextStyle,
              ),
            ),
        ],
      ),
    );
  }
}
