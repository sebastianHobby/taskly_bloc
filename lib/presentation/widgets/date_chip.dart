import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart';
import 'package:taskly_bloc/l10n/rrule_l10n_es.dart';

/// A compact chip showing a date or indicator.
///
/// App-owned copy of the Taskly UI `DateChip` so `taskly_ui` can keep chip
/// widgets out of its public API.
class DateChip extends StatelessWidget {
  /// Creates a date chip.
  const DateChip({
    required this.icon,
    required this.label,
    required this.color,
    this.backgroundColor,
    super.key,
  });

  /// Creates a date chip for start dates.
  DateChip.startDate({
    required BuildContext context,
    required String label,
    Key? key,
  }) : this(
         icon: Icons.play_arrow_rounded,
         label: label,
         color: Theme.of(context).colorScheme.onSurfaceVariant,
         key: key,
       );

  /// Creates a date chip for deadline dates.
  factory DateChip.deadline({
    required BuildContext context,
    required String label,
    required bool isOverdue,
    required bool isDueToday,
    required bool isDueSoon,
    Key? key,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    Color chipColor;
    Color? chipBackground;

    if (isOverdue) {
      chipColor = colorScheme.error;
      chipBackground = colorScheme.errorContainer.withValues(alpha: 0.3);
    } else if (isDueToday) {
      chipColor = colorScheme.primary;
      chipBackground = colorScheme.primaryContainer.withValues(alpha: 0.3);
    } else if (isDueSoon) {
      chipColor = colorScheme.primary;
    } else {
      chipColor = colorScheme.onSurfaceVariant;
    }

    return DateChip(
      icon: Icons.flag_outlined,
      label: label,
      color: chipColor,
      backgroundColor: chipBackground,
      key: key,
    );
  }

  /// Creates a date chip for repeat indicator.
  factory DateChip.repeat({
    required BuildContext context,
    required String label,
    Key? key,
  }) {
    return DateChip(
      icon: Icons.repeat_rounded,
      label: label,
      color: Theme.of(context).colorScheme.primary,
      key: key,
    );
  }

  /// The icon to display.
  final IconData icon;

  /// The label text.
  final String label;

  /// The foreground color for icon and text.
  final Color color;

  /// Optional background color for the chip.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: backgroundColor != null
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : EdgeInsets.zero,
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A date chip that displays RRule with full i18n support.
///
/// This widget loads RruleL10n asynchronously and displays the
/// human-readable recurrence text. Use this when you need proper
/// internationalization support for complex RRule patterns.
class RruleDateChip extends StatefulWidget {
  const RruleDateChip({
    required this.rrule,
    this.icon = Icons.repeat_rounded,
    this.fallbackLabel = 'Repeats',
    super.key,
  });

  /// The RRule string to display.
  final String? rrule;

  /// The icon to display.
  final IconData icon;

  /// Fallback label when RRule is null or parsing fails.
  final String fallbackLabel;

  @override
  State<RruleDateChip> createState() => _RruleDateChipState();
}

class _RruleDateChipState extends State<RruleDateChip> {
  String? _label;

  @override
  void initState() {
    super.initState();
    if (widget.rrule != null && widget.rrule!.isNotEmpty) {
      _loadLabel();
    }
  }

  @override
  void didUpdateWidget(RruleDateChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload label if rrule changed
    if (oldWidget.rrule != widget.rrule) {
      _label = null;
      if (widget.rrule != null && widget.rrule!.isNotEmpty) {
        _loadLabel();
      } else {
        setState(() {
          _label = null;
        });
      }
    }
  }

  Future<void> _loadLabel() async {
    if (widget.rrule == null || widget.rrule!.isEmpty) {
      return;
    }

    try {
      // Detect the current locale and load appropriate l10n
      final locale = Localizations.localeOf(context);
      final rruleL10n = locale.languageCode == 'es'
          ? await RruleL10nEs.create()
          : await RruleL10nEn.create();

      final recurrenceRule = RecurrenceRule.fromString(widget.rrule!);
      final text = recurrenceRule.toText(l10n: rruleL10n);

      if (mounted) {
        setState(() {
          _label = text;
        });
      }
    } catch (e) {
      // If parsing fails, keep null label (will use fallback)
      if (mounted) {
        setState(() {
          _label = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label ?? widget.fallbackLabel;
    return DateChip(
      icon: widget.icon,
      label: label,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
