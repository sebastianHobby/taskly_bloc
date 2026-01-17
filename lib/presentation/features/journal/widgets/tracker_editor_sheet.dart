import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition_choice.dart';

enum TrackerEditorSegment { yesNo, rating, number, choice }

class TrackerEditorResult {
  const TrackerEditorResult({
    required this.definition,
    required this.pinned,
    required this.showInQuickAdd,
    required this.choices,
  });

  final TrackerDefinition definition;
  final bool pinned;
  final bool showInQuickAdd;
  final List<TrackerDefinitionChoice> choices;
}

Future<TrackerEditorResult?> showTrackerEditorSheet({
  required BuildContext context,
  TrackerDefinition? initialDefinition,
  bool initialPinned = false,
  bool initialShowInQuickAdd = false,
  List<TrackerDefinitionChoice> initialChoices =
      const <TrackerDefinitionChoice>[],
}) {
  return showModalBottomSheet<TrackerEditorResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return _TrackerEditorSheet(
        initialDefinition: initialDefinition,
        initialPinned: initialPinned,
        initialShowInQuickAdd: initialShowInQuickAdd,
        initialChoices: initialChoices,
      );
    },
  );
}

class _TrackerEditorSheet extends StatefulWidget {
  const _TrackerEditorSheet({
    required this.initialDefinition,
    required this.initialPinned,
    required this.initialShowInQuickAdd,
    required this.initialChoices,
  });

  final TrackerDefinition? initialDefinition;
  final bool initialPinned;
  final bool initialShowInQuickAdd;
  final List<TrackerDefinitionChoice> initialChoices;

  @override
  State<_TrackerEditorSheet> createState() => _TrackerEditorSheetState();
}

class _ChoiceDraft {
  _ChoiceDraft({required this.choiceKey, required this.label});

  String choiceKey;
  String label;
}

class _TrackerEditorSheetState extends State<_TrackerEditorSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final TextEditingController _stepController;
  late final TextEditingController _unitController;

  late TrackerEditorSegment _segment;
  late bool _pinned;
  late bool _quickAdd;
  late bool _isOutcome;
  late bool _archived;
  late bool _higherIsBetter;
  late String _scope;

  late final List<_ChoiceDraft> _choices;

  @override
  void initState() {
    super.initState();

    final d = widget.initialDefinition;
    _nameController = TextEditingController(text: d?.name ?? '');
    _descriptionController = TextEditingController(text: d?.description ?? '');

    _minController = TextEditingController(text: d?.minInt?.toString() ?? '');
    _maxController = TextEditingController(text: d?.maxInt?.toString() ?? '');
    _stepController = TextEditingController(text: d?.stepInt?.toString() ?? '');
    _unitController = TextEditingController(text: d?.unitKind ?? '');

    _segment = _segmentFromDefinition(d);
    _pinned = widget.initialPinned;
    _quickAdd = widget.initialShowInQuickAdd;
    _isOutcome = d?.isOutcome ?? false;
    _archived = !(d == null) && !d.isActive;
    _higherIsBetter = d?.higherIsBetter ?? true;
    _scope = d?.scope ?? 'entry';

    final activeChoices = widget.initialChoices
        .where((c) => c.isActive)
        .toList(growable: false);

    _choices = [
      for (final c in activeChoices)
        _ChoiceDraft(choiceKey: c.choiceKey, label: c.label),
    ];

    if (_choices.isEmpty && _segment == TrackerEditorSegment.choice) {
      _choices.add(_ChoiceDraft(choiceKey: 'option_1', label: 'Option 1'));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _stepController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  TrackerEditorSegment _segmentFromDefinition(TrackerDefinition? d) {
    final valueType = (d?.valueType ?? 'yes_no').trim();
    return switch (valueType) {
      'rating' => TrackerEditorSegment.rating,
      'choice' => TrackerEditorSegment.choice,
      'number' || 'int' => TrackerEditorSegment.number,
      _ => TrackerEditorSegment.yesNo,
    };
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final d = widget.initialDefinition;
    final isEditing = d != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  isEditing ? 'Edit tracker' : 'Create tracker',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton(
                onPressed: _onSave,
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: !isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Read, Walk, Stretch',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) return 'Name is required.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TrackerEditorSegment>(
                  value: _segment,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                      value: TrackerEditorSegment.yesNo,
                      child: Text('Yes/No'),
                    ),
                    DropdownMenuItem(
                      value: TrackerEditorSegment.rating,
                      child: Text('Rating (integer range)'),
                    ),
                    DropdownMenuItem(
                      value: TrackerEditorSegment.number,
                      child: Text('Number (integer)'),
                    ),
                    DropdownMenuItem(
                      value: TrackerEditorSegment.choice,
                      child: Text('Choice (select one)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _segment = value;
                      if (_segment == TrackerEditorSegment.choice &&
                          _choices.isEmpty) {
                        _choices.add(
                          _ChoiceDraft(
                            choiceKey: 'option_1',
                            label: 'Option 1',
                          ),
                        );
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  textInputAction: TextInputAction.newline,
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _scope,
                  decoration: const InputDecoration(labelText: 'Scope'),
                  items: const [
                    DropdownMenuItem(value: 'entry', child: Text('Per entry')),
                    DropdownMenuItem(value: 'day', child: Text('Per day')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _scope = value);
                  },
                ),
                const SizedBox(height: 12),
                if (_segment == TrackerEditorSegment.rating ||
                    _segment == TrackerEditorSegment.number)
                  _RangeFields(
                    minController: _minController,
                    maxController: _maxController,
                    stepController: _stepController,
                    unitController: _unitController,
                  ),
                if (_segment == TrackerEditorSegment.choice) ...[
                  const SizedBox(height: 8),
                  _ChoicesEditor(
                    choices: _choices,
                    onChanged: () => setState(() {}),
                  ),
                ],
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Outcome (vs factor)'),
                  value: _isOutcome,
                  onChanged: (value) => setState(() => _isOutcome = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pinned'),
                  value: _pinned,
                  onChanged: _archived
                      ? null
                      : (v) => setState(() => _pinned = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show in quick add'),
                  value: _quickAdd,
                  onChanged: _archived
                      ? null
                      : (v) => setState(() => _quickAdd = v),
                ),
                if (_segment != TrackerEditorSegment.yesNo) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Higher is better'),
                    value: _higherIsBetter,
                    onChanged: (v) => setState(() => _higherIsBetter = v),
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Archived'),
                  value: _archived,
                  onChanged: (v) => setState(() => _archived = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    final minInt = _tryParseInt(_minController.text);
    final maxInt = _tryParseInt(_maxController.text);
    final stepInt = _tryParseInt(_stepController.text);
    final unitKind = _unitController.text.trim();

    if (_segment == TrackerEditorSegment.rating ||
        _segment == TrackerEditorSegment.number) {
      if (minInt == null || maxInt == null || stepInt == null) {
        _showError('Min, max, and step are required for this type.');
        return;
      }
      if (stepInt <= 0) {
        _showError('Step must be greater than 0.');
        return;
      }
      if (minInt >= maxInt) {
        _showError('Min must be less than max.');
        return;
      }
    }

    if (_segment == TrackerEditorSegment.choice) {
      final active = _choices
          .map((c) => c.label.trim())
          .where((l) => l.isNotEmpty)
          .toList(growable: false);
      if (active.isEmpty) {
        _showError('Add at least one choice.');
        return;
      }
    }

    final nowUtc = DateTime.now().toUtc();
    final existing = widget.initialDefinition;

    final (valueType, valueKind) = switch (_segment) {
      TrackerEditorSegment.yesNo => ('yes_no', 'boolean'),
      TrackerEditorSegment.rating => ('rating', 'rating'),
      TrackerEditorSegment.number => ('number', 'int'),
      TrackerEditorSegment.choice => ('choice', 'choice'),
    };

    final definition = TrackerDefinition(
      id: existing?.id ?? '',
      name: name,
      description: description.isEmpty ? null : description,
      scope: _scope,
      valueType: valueType,
      valueKind: valueKind,
      opKind: 'set',
      createdAt: existing?.createdAt ?? nowUtc,
      updatedAt: nowUtc,
      roles: existing?.roles ?? const <String>[],
      config: existing?.config ?? const <String, dynamic>{},
      goal: existing?.goal ?? const <String, dynamic>{},
      isActive: !_archived,
      sortOrder: existing?.sortOrder ?? 0,
      deletedAt: existing?.deletedAt,
      source: existing?.source ?? 'user',
      systemKey: existing?.systemKey,
      minInt:
          (_segment == TrackerEditorSegment.rating ||
              _segment == TrackerEditorSegment.number)
          ? minInt
          : null,
      maxInt:
          (_segment == TrackerEditorSegment.rating ||
              _segment == TrackerEditorSegment.number)
          ? maxInt
          : null,
      stepInt:
          (_segment == TrackerEditorSegment.rating ||
              _segment == TrackerEditorSegment.number)
          ? stepInt
          : null,
      unitKind:
          (_segment == TrackerEditorSegment.rating ||
              _segment == TrackerEditorSegment.number)
          ? (unitKind.isEmpty ? null : unitKind)
          : null,
      linkedValueId: existing?.linkedValueId,
      isOutcome: _isOutcome,
      isInsightEnabled: existing?.isInsightEnabled ?? false,
      higherIsBetter: (_segment == TrackerEditorSegment.yesNo)
          ? null
          : _higherIsBetter,
      userId: existing?.userId,
    );

    final choices = <TrackerDefinitionChoice>[];
    if (_segment == TrackerEditorSegment.choice) {
      var sort = 100;
      final usedKeys = <String>{};
      for (final c in _choices) {
        final label = c.label.trim();
        if (label.isEmpty) continue;

        var choiceKey = c.choiceKey.trim();
        if (choiceKey.isEmpty) {
          choiceKey = _slugify(label);
        }
        choiceKey = _dedupeKey(choiceKey, usedKeys);
        usedKeys.add(choiceKey);

        choices.add(
          TrackerDefinitionChoice(
            id: '',
            trackerId: existing?.id ?? '',
            choiceKey: choiceKey,
            label: label,
            createdAt: nowUtc,
            updatedAt: nowUtc,
            sortOrder: sort,
            isActive: true,
            userId: null,
          ),
        );
        sort += 10;
      }
    }

    Navigator.of(context).pop(
      TrackerEditorResult(
        definition: definition,
        pinned: _pinned,
        showInQuickAdd: _quickAdd,
        choices: choices,
      ),
    );
  }

  int? _tryParseInt(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _RangeFields extends StatelessWidget {
  const _RangeFields({
    required this.minController,
    required this.maxController,
    required this.stepController,
    required this.unitController,
  });

  final TextEditingController minController;
  final TextEditingController maxController;
  final TextEditingController stepController;
  final TextEditingController unitController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: stepController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Step'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: unitController,
          decoration: const InputDecoration(
            labelText: 'Unit (optional)',
            hintText: 'e.g. min, kg, pages',
          ),
        ),
      ],
    );
  }
}

class _ChoicesEditor extends StatelessWidget {
  const _ChoicesEditor({required this.choices, required this.onChanged});

  final List<_ChoiceDraft> choices;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choices',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = choices.removeAt(oldIndex);
            choices.insert(newIndex, item);
            onChanged();
          },
          children: [
            for (final (index, c) in choices.indexed)
              Padding(
                key: ValueKey('choice_${index}_${c.choiceKey}'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: c.label,
                        decoration: const InputDecoration(
                          labelText: 'Label',
                        ),
                        onChanged: (v) {
                          c.label = v;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: choices.length <= 1
                          ? null
                          : () {
                              choices.removeAt(index);
                              onChanged();
                            },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            choices.add(
              _ChoiceDraft(
                choiceKey: 'option_${choices.length + 1}',
                label: 'Option ${choices.length + 1}',
              ),
            );
            onChanged();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add choice'),
        ),
      ],
    );
  }
}

String _slugify(String input) {
  final lower = input.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final isAlphaNum = RegExp('[a-z0-9]').hasMatch(ch);
    if (isAlphaNum) {
      buffer.write(ch);
    } else if (buffer.isNotEmpty && !buffer.toString().endsWith('_')) {
      buffer.write('_');
    }
  }
  final out = buffer.toString();
  return out.isEmpty ? 'option' : out;
}

String _dedupeKey(String key, Set<String> used) {
  var candidate = key;
  var i = 2;
  while (used.contains(candidate)) {
    candidate = '${key}_$i';
    i += 1;
  }
  return candidate;
}
