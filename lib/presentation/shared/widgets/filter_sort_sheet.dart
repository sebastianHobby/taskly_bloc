import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class FilterSortRadioOption {
  const FilterSortRadioOption({
    required this.value,
    required this.label,
  });

  final Object value;
  final String label;
}

class FilterSortRadioGroup {
  const FilterSortRadioGroup({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.popOnSelect = true,
  });

  final String title;
  final List<FilterSortRadioOption> options;
  final Object selectedValue;
  final ValueChanged<Object> onSelected;
  final bool popOnSelect;
}

class FilterSortToggle {
  const FilterSortToggle({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.popOnToggle = true,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final bool popOnToggle;
}

class FilterSortSection {
  const FilterSortSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;
}

Future<void> showFilterSortSheet({
  required BuildContext context,
  String title = 'Filter & sort',
  List<FilterSortRadioGroup> sortGroups = const <FilterSortRadioGroup>[],
  List<FilterSortToggle> toggles = const <FilterSortToggle>[],
  List<FilterSortSection> sections = const <FilterSortSection>[],
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final tokens = TasklyTokens.of(sheetContext);
      final theme = Theme.of(sheetContext);

      final children = <Widget>[
        Text(
          title,
          style: theme.textTheme.titleLarge,
        ),
      ];

      for (final group in sortGroups) {
        children.add(SizedBox(height: tokens.spaceSm));
        children.add(
          Text(
            group.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        for (final option in group.options) {
          children.add(
            RadioListTile<Object>(
              value: option.value,
              groupValue: group.selectedValue,
              title: Text(option.label),
              onChanged: (value) {
                if (value == null) return;
                group.onSelected(value);
                if (group.popOnSelect) {
                  Navigator.of(sheetContext).pop();
                }
              },
            ),
          );
        }
      }

      for (final section in sections) {
        children.add(SizedBox(height: tokens.spaceSm));
        children.add(
          Text(
            section.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        children.add(SizedBox(height: tokens.spaceSm));
        children.add(section.child);
      }

      if (toggles.isNotEmpty) {
        children.add(SizedBox(height: tokens.spaceSm));
        children.add(
          Text(
            'Filter',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        for (final toggle in toggles) {
          children.add(
            SwitchListTile(
              title: Text(toggle.title),
              subtitle: toggle.subtitle == null ? null : Text(toggle.subtitle!),
              value: toggle.value,
              onChanged: (value) {
                toggle.onChanged(value);
                if (toggle.popOnToggle) {
                  Navigator.of(sheetContext).pop();
                }
              },
              contentPadding: EdgeInsets.zero,
            ),
          );
        }
      }

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            tokens.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      );
    },
  );
}
