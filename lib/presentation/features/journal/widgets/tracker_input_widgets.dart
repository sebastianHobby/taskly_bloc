import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
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
            label: context.l10n.journalChooseOptionLabel,
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
    final result = await showModalBottomSheet<_ChoiceSelectionResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _TrackerChoiceBottomSheet(
        choices: choices,
        selectedKey: selectedKey,
      ),
    );

    if (result == null) return;
    onSelected(result.nextSelection);
  }
}

class TrackerQuantityInput extends StatelessWidget {
  const TrackerQuantityInput({
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.onClear,
    this.label,
    super.key,
  });

  final String? label;
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

    int clamp(int v) {
      var out = v;
      if (min != null) out = out < min! ? min! : out;
      if (max != null) out = out > max! ? max! : out;
      return out;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null && label!.trim().isNotEmpty) ...[
          Text(label!, style: Theme.of(context).textTheme.titleSmall),
          SizedBox(height: tokens.spaceSm),
        ],
        Row(
          children: [
            _StepperHoldButton(
              icon: Icons.remove,
              enabled: enabled,
              onTap: () => onChanged(clamp(intValue - step)),
              onRepeat: () => onChanged(clamp(intValue - step)),
            ),
            TextButton(
              onPressed: !enabled ? null : () => _showEditSheet(context),
              child: Text('$intValue'),
            ),
            _StepperHoldButton(
              icon: Icons.add,
              enabled: enabled,
              onTap: () => onChanged(clamp(intValue + step)),
              onRepeat: () => onChanged(clamp(intValue + step)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showEditSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_QuantityEditResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _TrackerQuantityEditBottomSheet(
        initialValue: value ?? 0,
        allowClear: onClear != null,
      ),
    );

    if (result == null || result.isCancelled) return;
    if (result.isClear) {
      onClear?.call();
      return;
    }

    final nextValue = result.value;
    if (nextValue != null) {
      var output = nextValue;
      if (min != null && output < min!) output = min!;
      if (max != null && output > max!) output = max!;
      onChanged(output);
    } else {
      onClear?.call();
    }
  }
}

class _TrackerChoiceBottomSheet extends StatefulWidget {
  const _TrackerChoiceBottomSheet({
    required this.choices,
    required this.selectedKey,
  });

  final List<TrackerDefinitionChoice> choices;
  final String? selectedKey;

  @override
  State<_TrackerChoiceBottomSheet> createState() =>
      _TrackerChoiceBottomSheetState();
}

class _TrackerChoiceBottomSheetState extends State<_TrackerChoiceBottomSheet> {
  late final TextEditingController _controller = TextEditingController();
  late final Debouncer _debouncer = Debouncer(
    const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.choices
        : widget.choices
              .where((c) => c.label.toLowerCase().contains(query))
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
            controller: _controller,
            decoration: InputDecoration(
              labelText: context.l10n.journalSearchOptionsLabel,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (_) {
              _debouncer.schedule(() {
                if (!mounted) return;
                setState(() {});
              });
            },
          ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          if (widget.selectedKey != null)
            ListTile(
              leading: const Icon(Icons.clear),
              title: Text(context.l10n.journalClearSelectionLabel),
              onTap: () => Navigator.of(context).pop(
                const _ChoiceSelectionResult(nextSelection: null),
              ),
            ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final choice = filtered[index];
                final selected = choice.choiceKey == widget.selectedKey;
                return ListTile(
                  title: Text(choice.label),
                  trailing: selected ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(
                    _ChoiceSelectionResult(nextSelection: choice.choiceKey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceSelectionResult {
  const _ChoiceSelectionResult({required this.nextSelection});

  final String? nextSelection;
}

class _TrackerQuantityEditBottomSheet extends StatefulWidget {
  const _TrackerQuantityEditBottomSheet({
    required this.initialValue,
    required this.allowClear,
  });

  final int initialValue;
  final bool allowClear;

  @override
  State<_TrackerQuantityEditBottomSheet> createState() =>
      _TrackerQuantityEditBottomSheetState();
}

class _TrackerQuantityEditBottomSheetState
    extends State<_TrackerQuantityEditBottomSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.initialValue}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            context.l10n.journalEditValueTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.l10n.valueLabel,
            ),
          ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          Row(
            children: [
              if (widget.allowClear)
                TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(const _QuantityEditResult.clear()),
                  child: Text(context.l10n.clearLabel),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(const _QuantityEditResult.cancel()),
                child: Text(context.l10n.cancelLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  _QuantityEditResult.save(
                    int.tryParse(_controller.text.trim()),
                  ),
                ),
                child: Text(context.l10n.saveLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityEditResult {
  const _QuantityEditResult._({
    this.value,
    this.isClear = false,
    this.isCancelled = false,
  });

  const _QuantityEditResult.save(int? value) : this._(value: value);
  const _QuantityEditResult.clear() : this._(isClear: true);
  const _QuantityEditResult.cancel() : this._(isCancelled: true);

  final int? value;
  final bool isClear;
  final bool isCancelled;
}

class _StepperHoldButton extends StatefulWidget {
  const _StepperHoldButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.onRepeat,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onRepeat;

  @override
  State<_StepperHoldButton> createState() => _StepperHoldButtonState();
}

class _StepperHoldButtonState extends State<_StepperHoldButton> {
  Timer? _repeatTimer;
  Timer? _startDelayTimer;

  void _cancelTimers() {
    _startDelayTimer?.cancel();
    _repeatTimer?.cancel();
    _startDelayTimer = null;
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _startRepeat() {
    if (!widget.enabled) return;
    _cancelTimers();
    _startDelayTimer = Timer(const Duration(milliseconds: 350), () {
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 160), (_) {
        if (!mounted || !widget.enabled) return;
        widget.onRepeat();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startRepeat(),
      onLongPressEnd: (_) => _cancelTimers(),
      onLongPressCancel: _cancelTimers,
      child: IconButton(
        onPressed: widget.enabled ? widget.onTap : null,
        icon: Icon(widget.icon),
      ),
    );
  }
}
