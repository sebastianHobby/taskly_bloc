import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart';
import 'package:taskly_bloc/l10n/rrule_l10n_es.dart';
import 'package:taskly_ui/taskly_ui.dart';

/// A recurrence form chip that renders an RRULE with locale-aware text.
///
/// This lives in the app (presentation) because RRULE parsing + i18n is not a
/// pure-UI concern for `taskly_ui`.
class RruleFormRecurrenceChip extends StatefulWidget {
  const RruleFormRecurrenceChip({
    required this.rrule,
    required this.emptyLabel,
    required this.onTap,
    this.onClear,
    super.key,
  });

  final String? rrule;

  /// Label shown when [rrule] is null/empty.
  final String emptyLabel;

  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  State<RruleFormRecurrenceChip> createState() =>
      _RruleFormRecurrenceChipState();
}

class _RruleFormRecurrenceChipState extends State<RruleFormRecurrenceChip> {
  String? _label;

  bool get _hasValue => widget.rrule != null && widget.rrule!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasValue) {
      _loadLabel();
    }
  }

  @override
  void didUpdateWidget(RruleFormRecurrenceChip oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.rrule != widget.rrule) {
      _label = null;
      if (_hasValue) {
        _loadLabel();
      } else {
        setState(() {
          _label = null;
        });
      }
    }
  }

  Future<void> _loadLabel() async {
    final rrule = widget.rrule;
    if (rrule == null || rrule.isEmpty) return;

    try {
      final locale = Localizations.localeOf(context);
      final rruleL10n = locale.languageCode == 'es'
          ? await RruleL10nEs.create()
          : await RruleL10nEn.create();

      final recurrenceRule = RecurrenceRule.fromString(rrule);
      final text = recurrenceRule.toText(l10n: rruleL10n);

      if (!mounted) return;
      setState(() {
        _label = text;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _label = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormRecurrenceChip(
      hasValue: _hasValue,
      label: _label,
      emptyLabel: widget.emptyLabel,
      onTap: widget.onTap,
      onClear: widget.onClear,
    );
  }
}
