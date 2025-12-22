import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';

Future<void> showSortBottomSheet({
  required BuildContext context,
  required SortPreferences current,
  required List<SortField> availableSortFields,
  required ValueChanged<SortPreferences> onChanged,
}) {
  assert(availableSortFields.isNotEmpty, 'Provide at least one sort field');

  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final slotCount = availableSortFields.length.clamp(1, 3);
      final slotValues = List<SortCriterion?>.generate(
        slotCount,
        (index) =>
            index < current.criteria.length ? current.criteria[index] : null,
      );

      return StatefulBuilder(
        builder: (context, setState) {
          List<SortCriterion> sanitizeSelection() {
            final sanitized = <SortCriterion>[];
            for (final criterion in slotValues) {
              if (criterion == null) continue;
              if (!availableSortFields.contains(criterion.field)) continue;
              final exists = sanitized.any((c) => c.field == criterion.field);
              if (exists) continue;
              sanitized.add(criterion);
            }
            if (sanitized.isEmpty) {
              sanitized.add(
                SortCriterion(field: availableSortFields.first),
              );
            }
            return sanitized;
          }

          void emitSelection() {
            onChanged(
              SortPreferences(criteria: sanitizeSelection()),
            );
          }

          void updateSlotField(int index, SortField? value) {
            setState(() {
              for (var i = 0; i < slotValues.length; i++) {
                if (i == index) continue;
                if (slotValues[i]?.field == value) slotValues[i] = null;
              }
              if (value == null) {
                slotValues[index] = null;
              } else {
                final direction =
                    slotValues[index]?.direction ?? SortDirection.ascending;
                slotValues[index] = SortCriterion(
                  field: value,
                  direction: direction,
                );
              }
            });
            emitSelection();
          }

          void updateSlotDirection(int index, SortDirection? value) {
            if (value == null) return;
            setState(() {
              final current = slotValues[index];
              if (current == null) return;
              slotValues[index] = current.copyWith(direction: value);
            });
            emitSelection();
          }

          String fieldLabel(SortField field) {
            return switch (field) {
              SortField.name => l10n.sortFieldNameLabel,
              SortField.startDate => l10n.sortFieldStartDateLabel,
              SortField.deadlineDate => l10n.sortFieldDeadlineDateLabel,
              SortField.createdDate => 'Created date',
              SortField.updatedDate => 'Updated date',
            };
          }

          String slotLabel(int index) {
            return switch (index) {
              0 => l10n.sortSlotPrimaryLabel,
              1 => l10n.sortSlotSecondaryLabel,
              _ => l10n.sortSlotTertiaryLabel,
            };
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sortMenuTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.sortSortingLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < slotValues.length; i++) ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<SortField?>(
                          initialValue: slotValues[i]?.field,
                          decoration: InputDecoration(
                            labelText: slotLabel(i),
                          ),
                          onChanged: (value) => updateSlotField(i, value),
                          items: [
                            DropdownMenuItem<SortField?>(
                              child: Text(l10n.sortFieldNoneLabel),
                            ),
                            ...availableSortFields.map(
                              (field) => DropdownMenuItem<SortField?>(
                                value: field,
                                child: Text(fieldLabel(field)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<SortDirection>(
                          initialValue:
                              slotValues[i]?.direction ??
                              SortDirection.ascending,
                          decoration: InputDecoration(
                            labelText: l10n.sortDirectionLabel,
                          ),
                          onChanged: (value) => updateSlotDirection(i, value),
                          items: [
                            DropdownMenuItem(
                              value: SortDirection.ascending,
                              child: Text(l10n.sortDirectionAscending),
                            ),
                            DropdownMenuItem(
                              value: SortDirection.descending,
                              child: Text(l10n.sortDirectionDescending),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}
