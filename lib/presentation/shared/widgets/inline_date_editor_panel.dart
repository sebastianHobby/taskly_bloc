import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class InlineDateEditorPanel extends StatelessWidget {
  const InlineDateEditorPanel({
    required this.label,
    required this.icon,
    required this.now,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onClose,
    super.key,
  });

  final String label;
  final IconData icon;
  final DateTime now;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final today = dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));
    final effectiveSelected = dateOnly(selectedDate ?? today);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMd),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              primary: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(icon, size: tokens.spaceMd2),
                            SizedBox(width: tokens.spaceXs),
                            Expanded(
                              child: Text(
                                label,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        tooltip: l10n.closeLabel,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceSm),
                  Wrap(
                    spacing: tokens.spaceXs2,
                    runSpacing: tokens.spaceXs2,
                    children: [
                      _QuickDateChip(
                        label: l10n.dateToday,
                        onTap: () => onDateSelected(today),
                      ),
                      _QuickDateChip(
                        label: l10n.dateTomorrow,
                        onTap: () => onDateSelected(tomorrow),
                      ),
                      _QuickDateChip(
                        label: l10n.dateNextWeek,
                        onTap: () => onDateSelected(nextWeek),
                      ),
                      _QuickDateChip(
                        label: l10n.sortFieldNoneLabel,
                        onTap: () => onDateSelected(null),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceSm),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: effectiveSelected,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      onDateChanged: (date) => onDateSelected(dateOnly(date)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  const _QuickDateChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: scheme.surface,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceXs,
        vertical: tokens.spaceXxs,
      ),
    );
  }
}
