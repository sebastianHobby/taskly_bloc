import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart';

/// A chip widget for displaying and editing recurrence rules.
class FormRecurrenceChip extends StatefulWidget {
  const FormRecurrenceChip({
    required this.rrule,
    required this.onTap,
    this.onClear,
    super.key,
  });

  final String? rrule;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  State<FormRecurrenceChip> createState() => _FormRecurrenceChipState();
}

class _FormRecurrenceChipState extends State<FormRecurrenceChip> {
  String? _label;

  Future<String> _getLabel(String rruleString) async {
    final l10n = await RruleL10nEn.create();
    final recurrenceRule = RecurrenceRule.fromString(rruleString);
    final String labelStr = recurrenceRule.toText(l10n: l10n);
    return labelStr;
  }

  @override
  void initState() {
    super.initState();
    if (widget.rrule != null && widget.rrule!.isNotEmpty) {
      _loadLabel();
    }
  }

  @override
  void didUpdateWidget(FormRecurrenceChip oldWidget) {
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
    final label = await _getLabel(widget.rrule!);
    if (mounted) {
      setState(() {
        _label = label;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasValue = widget.rrule != null && widget.rrule!.isNotEmpty;

    return InputChip(
      avatar: Icon(
        Icons.repeat,
        size: 18,
        color: hasValue ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      label: Text(_label ?? 'Repeat'),
      deleteIcon: hasValue && widget.onClear != null
          ? Icon(
              Icons.close,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
      onDeleted: hasValue && widget.onClear != null ? widget.onClear : null,
      onPressed: widget.onTap,
      side: BorderSide(
        color: hasValue
            ? colorScheme.primary.withValues(alpha: 0.5)
            : colorScheme.outlineVariant,
      ),
      backgroundColor: hasValue
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.surface,
    );
  }
}
