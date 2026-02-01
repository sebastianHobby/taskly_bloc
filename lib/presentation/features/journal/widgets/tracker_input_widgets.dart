import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/shared/utils/debouncer.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class TrackerChoiceInput extends StatelessWidget {
  const TrackerChoiceInput({
    required this.choices,
    required this.selectedKey,
    required this.enabled,
    required this.onSelected,
    this.searchThreshold = 6,
    super.key,
  });

  final List<TrackerDefinitionChoice> choices;
  final String? selectedKey;
  final bool enabled;
  final ValueChanged<String?> onSelected;
  final int searchThreshold;

  @override
  Widget build(BuildContext context) {
    if (choices.length <= searchThreshold) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in choices)
            ChoiceChip(
              label: Text(c.label),
              selected: selectedKey == c.choiceKey,
              onSelected: !enabled
                  ? null
                  : (selected) => onSelected(
                      selected ? c.choiceKey : null,
                    ),
            ),
        ],
      );
    }

    final selectedLabel = choices
        .firstWhere(
          (c) => c.choiceKey == selectedKey,
          orElse: () => TrackerDefinitionChoice(
            id: '',
            trackerId: '',
            choiceKey: '',
            label: 'Choose option',
            createdAt: DateTime(2000),
            updatedAt: DateTime(2000),
          ),
        )
        .label;

    return Card(
      child: ListTile(
        title: Text(selectedLabel),
        trailing: const Icon(Icons.expand_more),
        onTap: !enabled ? null : () => _showChoiceSheet(context),
      ),
    );
  }

  Future<void> _showChoiceSheet(BuildContext context) async {
    final controller = TextEditingController();
    final debouncer = Debouncer(const Duration(milliseconds: 300));
    var isOpen = true;
    String? next = selectedKey;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              final query = controller.text.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? choices
                  : choices
                        .where(
                          (c) => c.label.toLowerCase().contains(query),
                        )
                        .toList(growable: false);

              return Padding(
                padding: EdgeInsets.only(
                  left: TasklyTokens.of(context).spaceLg,
                  right: TasklyTokens.of(context).spaceLg,
                  top: TasklyTokens.of(context).spaceLg,
                  bottom:
                      MediaQuery.viewInsetsOf(context).bottom +
                      TasklyTokens.of(context).spaceLg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Search options',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) {
                        debouncer.schedule(() {
                          if (!isOpen) return;
                          setState(() {});
                        });
                      },
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    if (selectedKey != null)
                      ListTile(
                        leading: const Icon(Icons.clear),
                        title: const Text('Clear selection'),
                        onTap: () {
                          next = null;
                          Navigator.of(context).pop();
                        },
                      ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final choice = filtered[index];
                          final selected = choice.choiceKey == selectedKey;
                          return ListTile(
                            title: Text(choice.label),
                            trailing: selected ? const Icon(Icons.check) : null,
                            onTap: () {
                              next = choice.choiceKey;
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      isOpen = false;
      debouncer.dispose();
      controller.dispose();
    }

    onSelected(next);
  }
}

class TrackerQuantityInput extends StatelessWidget {
  const TrackerQuantityInput({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.onClear,
    super.key,
  });

  final String label;
  final int? value;
  final int? min;
  final int? max;
  final int step;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final intValue = value ?? 0;
    final showEditHint = (max ?? 0) > 10 || intValue >= 10;

    int clamp(int v) {
      var out = v;
      if (min != null) out = out < min! ? min! : out;
      if (max != null) out = out > max! ? max! : out;
      return out;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: tokens.spaceSm),
        Row(
          children: [
            IconButton(
              onPressed: !enabled
                  ? null
                  : () => onChanged(clamp(intValue - step)),
              icon: const Icon(Icons.remove),
            ),
            TextButton(
              onPressed: !enabled ? null : () => _showEditSheet(context),
              child: Text('$intValue'),
            ),
            IconButton(
              onPressed: !enabled
                  ? null
                  : () => onChanged(clamp(intValue + step)),
              icon: const Icon(Icons.add),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: !enabled ? null : () => _showEditSheet(context),
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
          ],
        ),
        if (showEditHint)
          Text(
            'Tap to type a larger number.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Future<void> _showEditSheet(BuildContext context) async {
    final controller = TextEditingController(text: '${value ?? 0}');
    int? nextValue = value ?? 0;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              left: TasklyTokens.of(context).spaceLg,
              right: TasklyTokens.of(context).spaceLg,
              top: TasklyTokens.of(context).spaceLg,
              bottom:
                  MediaQuery.viewInsetsOf(context).bottom +
                  TasklyTokens.of(context).spaceLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit value',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Value'),
                  onChanged: (value) => nextValue = int.tryParse(value),
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                Row(
                  children: [
                    if (onClear != null)
                      TextButton(
                        onPressed: () {
                          nextValue = null;
                          Navigator.of(context).pop();
                        },
                        child: const Text('Clear'),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } finally {
      controller.dispose();
    }

    if (nextValue != null) {
      var output = nextValue!;
      if (min != null && output < min!) output = min!;
      if (max != null && output > max!) output = max!;
      onChanged(output);
    } else {
      onClear?.call();
    }
  }
}
