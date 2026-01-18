export 'package:taskly_ui/taskly_ui.dart' show DateChip;

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
