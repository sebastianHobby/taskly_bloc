import 'package:flutter/material.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

enum ValuesAlignmentMode {
  inherit,
  override,
}

Future<List<String>?> showValuesAlignmentSheetForTask(
  BuildContext context, {
  required List<Value> availableValues,
  required List<String> explicitValueIds,
  required Project? selectedProject,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => ValuesAlignmentSheet.task(
      availableValues: availableValues,
      explicitValueIds: explicitValueIds,
      selectedProject: selectedProject,
    ),
  );
}

Future<List<String>?> showValuesAlignmentSheetForProject(
  BuildContext context, {
  required List<Value> availableValues,
  required List<String> valueIds,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => ValuesAlignmentSheet.project(
      availableValues: availableValues,
      valueIds: valueIds,
    ),
  );
}

class ValuesAlignmentSheet extends StatefulWidget {
  const ValuesAlignmentSheet._({
    required this.availableValues,
    required this.requireSelection,
    required this.allowInherit,
    required this.selectedProject,
    required this.initialExplicitValueIds,
    required this.title,
    super.key,
  });

  factory ValuesAlignmentSheet.task({
    required List<Value> availableValues,
    required List<String> explicitValueIds,
    required Project? selectedProject,
  }) {
    return ValuesAlignmentSheet._(
      key: const ValueKey('values_alignment_sheet_task'),
      availableValues: availableValues,
      requireSelection: false,
      allowInherit: selectedProject != null,
      selectedProject: selectedProject,
      initialExplicitValueIds: explicitValueIds,
      title: null,
    );
  }

  factory ValuesAlignmentSheet.project({
    required List<Value> availableValues,
    required List<String> valueIds,
  }) {
    return ValuesAlignmentSheet._(
      key: const ValueKey('values_alignment_sheet_project'),
      availableValues: availableValues,
      requireSelection: true,
      allowInherit: false,
      selectedProject: null,
      initialExplicitValueIds: valueIds,
      title: null,
    );
  }

  final List<Value> availableValues;
  final bool requireSelection;
  final bool allowInherit;
  final Project? selectedProject;
  final List<String> initialExplicitValueIds;

  /// Optional title override.
  final String? title;

  @override
  State<ValuesAlignmentSheet> createState() => _ValuesAlignmentSheetState();
}

class _ValuesAlignmentSheetState extends State<ValuesAlignmentSheet> {
  late ValuesAlignmentMode _mode;
  late List<String> _explicitValueIds;

  @override
  void initState() {
    super.initState();
    _explicitValueIds = List<String>.of(widget.initialExplicitValueIds);

    if (widget.allowInherit && _explicitValueIds.isEmpty) {
      _mode = ValuesAlignmentMode.inherit;
    } else {
      _mode = ValuesAlignmentMode.override;
    }
  }

  void _toggleSelected(String valueId, bool selected) {
    setState(() {
      if (selected) {
        if (_explicitValueIds.contains(valueId)) return;
        _explicitValueIds.add(valueId);
      } else {
        _explicitValueIds.remove(valueId);
      }

      // Ensure a stable primary ordering: first item is primary.
      // If primary was removed, the new first becomes primary.
    });
  }

  void _setPrimary(String valueId) {
    setState(() {
      if (!_explicitValueIds.contains(valueId)) {
        _explicitValueIds.insert(0, valueId);
      } else {
        _explicitValueIds.remove(valueId);
        _explicitValueIds.insert(0, valueId);
      }
    });
  }

  void _setMode(ValuesAlignmentMode mode) {
    if (!widget.allowInherit) return;

    setState(() {
      if (_mode == mode) return;
      _mode = mode;

      if (_mode == ValuesAlignmentMode.inherit) {
        _explicitValueIds = <String>[];
      } else {
        // Switching to override should start blank (do not prefill project).
        _explicitValueIds = <String>[];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final isTask = widget.allowInherit;
    final title = widget.title ?? l10n.valuesTitle;

    final inheritedValues = widget.selectedProject?.values ?? const <Value>[];
    final showInherited = isTask && _mode == ValuesAlignmentMode.inherit;
    final canSave =
        !widget.requireSelection ||
        (showInherited
            ? inheritedValues.isNotEmpty
            : _explicitValueIds.isNotEmpty);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),

          if (isTask && widget.allowInherit) ...[
            SegmentedButton<ValuesAlignmentMode>(
              segments: <ButtonSegment<ValuesAlignmentMode>>[
                ButtonSegment(
                  value: ValuesAlignmentMode.inherit,
                  label: Text(l10n.valuesInheritLabel),
                ),
                ButtonSegment(
                  value: ValuesAlignmentMode.override,
                  label: Text(l10n.valuesOverrideLabel),
                ),
              ],
              selected: <ValuesAlignmentMode>{_mode},
              onSelectionChanged: (selection) {
                final next = selection.first;
                _setMode(next);
              },
            ),
            const SizedBox(height: 8),
            Text(
              _mode == ValuesAlignmentMode.inherit
                  ? l10n.valuesInheritHelp
                  : l10n.valuesOverrideHelp,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
          ] else ...[
            Text(l10n.valuesProjectHelp, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
          ],

          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                if (showInherited) ...[
                  if (widget.selectedProject == null)
                    ListTile(
                      title: Text(l10n.valuesNoProjectSelected),
                      leading: const Icon(Icons.info_outline),
                    )
                  else ...[
                    ListTile(
                      title: Text(widget.selectedProject!.name),
                      subtitle: Text(l10n.valuesInheritedFromProject),
                      leading: const Icon(Icons.folder_outlined),
                    ),
                    for (final v in inheritedValues)
                      ListTile(
                        title: Text(v.name),
                        leading: Icon(
                          v.id == widget.selectedProject!.primaryValueId
                              ? Icons.star
                              : Icons.label_outline,
                        ),
                      ),
                    if (inheritedValues.isEmpty)
                      ListTile(
                        title: Text(l10n.valuesProjectHasNoValues),
                        leading: const Icon(Icons.info_outline),
                      ),
                  ],
                ] else ...[
                  for (final v in widget.availableValues)
                    _SelectableValueTile(
                      value: v,
                      selected: _explicitValueIds.contains(v.id),
                      isPrimary:
                          _explicitValueIds.isNotEmpty &&
                          _explicitValueIds.first == v.id,
                      onChanged: (selected) => _toggleSelected(v.id, selected),
                      onMakePrimary: () => _setPrimary(v.id),
                    ),
                  if (!widget.requireSelection)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.valuesOptionalFooter,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancelLabel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: canSave
                    ? () {
                        final result = showInherited
                            ? <String>[]
                            : _explicitValueIds;
                        Navigator.of(context).pop(result);
                      }
                    : null,
                child: Text(l10n.doneLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectableValueTile extends StatelessWidget {
  const _SelectableValueTile({
    required this.value,
    required this.selected,
    required this.isPrimary,
    required this.onChanged,
    required this.onMakePrimary,
  });

  final Value value;
  final bool selected;
  final bool isPrimary;
  final ValueChanged<bool> onChanged;
  final VoidCallback onMakePrimary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListTile(
      onTap: () => onChanged(!selected),
      leading: Checkbox(
        value: selected,
        onChanged: (v) => onChanged(v ?? false),
      ),
      title: Text(value.name),
      trailing: selected
          ? IconButton(
              icon: Icon(isPrimary ? Icons.star : Icons.star_border),
              tooltip: l10n.valuesPrimaryTooltip,
              onPressed: onMakePrimary,
            )
          : null,
    );
  }
}
