import 'package:flutter/material.dart';

enum TaskCompletionFilter {
  all,
  open,
  completed,
}

/// Compact status filter bar for task lists.
///
/// This is presentation-only, ephemeral UI state and should be owned by the
/// screen/template that displays it.
class TaskStatusFilterBar extends StatelessWidget {
  const TaskStatusFilterBar({
    required this.filter,
    required this.onChanged,
    required this.allLabel,
    required this.openLabel,
    required this.completedLabel,
    this.sheetTitle,
    super.key,
    this.singleLine = false,
  });

  final TaskCompletionFilter filter;
  final ValueChanged<TaskCompletionFilter> onChanged;

  final String allLabel;
  final String openLabel;
  final String completedLabel;

  /// Optional sheet title shown at the top of the picker bottom sheet.
  ///
  /// Shared UI must not hardcode user-facing strings; provide localized text
  /// from the app.
  final String? sheetTitle;

  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final label = switch (filter) {
      TaskCompletionFilter.all => allLabel,
      TaskCompletionFilter.open => openLabel,
      TaskCompletionFilter.completed => completedLabel,
    };

    final chip = ActionChip(
      avatar: Icon(
        Icons.filter_alt_outlined,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
      label: Text(label),
      onPressed: () async {
        final selected = await _pick(context);
        if (selected == null) return;
        onChanged(selected);
      },
    );

    if (singleLine) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [chip]),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [chip],
    );
  }

  Future<TaskCompletionFilter?> _pick(BuildContext context) {
    return showModalBottomSheet<TaskCompletionFilter?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        Widget row({
          required String title,
          required TaskCompletionFilter mode,
        }) {
          return ListTile(
            leading: filter == mode
                ? const Icon(Icons.check)
                : const SizedBox(width: 24),
            title: Text(title),
            onTap: () => Navigator.of(context).pop(mode),
          );
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (sheetTitle != null)
                ListTile(
                  title: Text(
                    sheetTitle!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              row(title: allLabel, mode: TaskCompletionFilter.all),
              row(title: openLabel, mode: TaskCompletionFilter.open),
              row(title: completedLabel, mode: TaskCompletionFilter.completed),
            ],
          ),
        );
      },
    );
  }
}
