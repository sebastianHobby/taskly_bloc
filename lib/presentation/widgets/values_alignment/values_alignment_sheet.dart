import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/core.dart';

enum ValuesAlignmentTarget {
  primary,
  secondary,
}

Future<List<String>?> showValuesAlignmentSheetForTask(
  BuildContext context, {
  required List<Value> availableValues,
  required List<String> explicitValueIds,
  required ValuesAlignmentTarget target,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => ValuesAlignmentSheet.task(
      availableValues: availableValues,
      explicitValueIds: explicitValueIds,
      target: target,
    ),
  );
}

Future<List<String>?> showValuesAlignmentSheetForProject(
  BuildContext context, {
  required List<Value> availableValues,
  required List<String> valueIds,
  required ValuesAlignmentTarget target,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => ValuesAlignmentSheet.project(
      availableValues: availableValues,
      valueIds: valueIds,
      target: target,
    ),
  );
}

class ValuesAlignmentSheet extends StatefulWidget {
  const ValuesAlignmentSheet._({
    required this.availableValues,
    required this.requireSelection,
    required this.initialValueIds,
    required this.target,
    required this.title,
    super.key,
  });

  factory ValuesAlignmentSheet.task({
    required List<Value> availableValues,
    required List<String> explicitValueIds,
    required ValuesAlignmentTarget target,
  }) {
    return ValuesAlignmentSheet._(
      key: const ValueKey('values_alignment_sheet_task'),
      availableValues: availableValues,
      requireSelection: true,
      initialValueIds: explicitValueIds,
      target: target,
      title: null,
    );
  }

  factory ValuesAlignmentSheet.project({
    required List<Value> availableValues,
    required List<String> valueIds,
    required ValuesAlignmentTarget target,
  }) {
    return ValuesAlignmentSheet._(
      key: const ValueKey('values_alignment_sheet_project'),
      availableValues: availableValues,
      requireSelection: true,
      initialValueIds: valueIds,
      target: target,
      title: null,
    );
  }

  final List<Value> availableValues;
  final bool requireSelection;
  final List<String> initialValueIds;
  final ValuesAlignmentTarget target;

  /// Optional title override.
  final String? title;

  @override
  State<ValuesAlignmentSheet> createState() => _ValuesAlignmentSheetState();
}

class _ValuesAlignmentSheetState extends State<ValuesAlignmentSheet> {
  late List<String> _selectedValueIds;

  @override
  void initState() {
    super.initState();
    _selectedValueIds = List<String>.of(widget.initialValueIds);
    if (_selectedValueIds.length > 2) {
      _selectedValueIds = _selectedValueIds.take(2).toList(growable: false);
    }
  }

  String? get _primaryId =>
      _selectedValueIds.isNotEmpty ? _selectedValueIds.first : null;

  String? get _secondaryId =>
      _selectedValueIds.length > 1 ? _selectedValueIds[1] : null;

  void _setPrimary(String valueId) {
    setState(() {
      final primary = _primaryId;
      final secondary = _secondaryId;
      if (primary == valueId) return;
      if (secondary == valueId) {
        _selectedValueIds = <String>[valueId];
        if (primary != null) {
          _selectedValueIds.add(primary);
        }
        return;
      }
      _selectedValueIds = <String>[valueId];
      if (secondary != null) {
        _selectedValueIds.add(secondary);
      }
    });
  }

  void _setSecondary(String valueId) {
    setState(() {
      final primary = _primaryId;
      if (primary == null) {
        _selectedValueIds = <String>[valueId];
        return;
      }
      if (primary == valueId) return;
      if (_secondaryId == valueId) {
        _selectedValueIds = <String>[primary];
        return;
      }
      _selectedValueIds = <String>[primary, valueId];
    });
  }

  void _clearSecondary() {
    setState(() {
      final primary = _primaryId;
      _selectedValueIds = primary == null ? <String>[] : <String>[primary];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final title =
        widget.title ??
        (widget.target == ValuesAlignmentTarget.primary
            ? l10n.valuesSelectPrimaryTitle
            : l10n.valuesSelectSecondaryTitle);

    final canSave = !widget.requireSelection || _selectedValueIds.isNotEmpty;

    final hasSecondary = _secondaryId != null;

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
          Text(l10n.valuesMaxTwoHelper, style: theme.textTheme.bodySmall),
          if (widget.target == ValuesAlignmentTarget.secondary && hasSecondary)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _clearSecondary,
                child: Text(l10n.valuesSecondaryClearAction),
              ),
            ),
          const SizedBox(height: 8),

          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                if (widget.availableValues.isEmpty)
                  ListTile(
                    title: Text(l10n.noValuesFound),
                    leading: const Icon(Icons.info_outline),
                  )
                else
                  for (final v in widget.availableValues)
                    _SelectableValueTile(
                      value: v,
                      target: widget.target,
                      selectedPrimaryId: _primaryId,
                      selectedSecondaryId: _secondaryId,
                      onSelectPrimary: _setPrimary,
                      onSelectSecondary: _setSecondary,
                      onClearSecondary: _clearSecondary,
                    ),
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
                        Navigator.of(context).pop(_selectedValueIds);
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
    required this.target,
    required this.selectedPrimaryId,
    required this.selectedSecondaryId,
    required this.onSelectPrimary,
    required this.onSelectSecondary,
    required this.onClearSecondary,
  });

  final Value value;
  final ValuesAlignmentTarget target;
  final String? selectedPrimaryId;
  final String? selectedSecondaryId;
  final ValueChanged<String> onSelectPrimary;
  final ValueChanged<String> onSelectSecondary;
  final VoidCallback onClearSecondary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isPrimary = value.id == selectedPrimaryId;
    final isSecondary = value.id == selectedSecondaryId;
    final isDisabled = target == ValuesAlignmentTarget.secondary && isPrimary;
    final iconData = getIconDataFromName(value.iconName) ?? Icons.star;
    final color = ColorUtils.fromHexWithThemeFallback(context, value.color);
    final selectionLabel = isPrimary
        ? l10n.valuesPrimaryShortLabel
        : isSecondary
        ? l10n.valuesSecondaryShortLabel
        : null;

    VoidCallback? onTap;
    if (!isDisabled) {
      onTap = () {
        if (target == ValuesAlignmentTarget.secondary && isSecondary) {
          onClearSecondary();
          return;
        }
        if (target == ValuesAlignmentTarget.primary) {
          onSelectPrimary(value.id);
        } else {
          onSelectSecondary(value.id);
        }
      };
    }

    return ListTile(
      onTap: onTap,
      enabled: !isDisabled,
      selected: isPrimary || isSecondary,
      selectedTileColor: color.withValues(alpha: 0.12),
      leading: _ValueIconBadge(
        icon: iconData,
        color: color,
        disabled: isDisabled,
      ),
      title: Text(value.name),
      trailing: selectionLabel == null
          ? null
          : _ValueSelectionTag(
              label: selectionLabel,
              color: color,
              disabled: isDisabled,
            ),
      subtitle: isDisabled
          ? Text(
              l10n.valuesPrimaryShortLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            )
          : null,
    );
  }
}

class _ValueIconBadge extends StatelessWidget {
  const _ValueIconBadge({
    required this.icon,
    required this.color,
    required this.disabled,
  });

  final IconData icon;
  final Color color;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = disabled ? scheme.onSurfaceVariant : color;
    final background = disabled
        ? scheme.surfaceContainerLow
        : color.withValues(alpha: 0.16);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(
          color: foreground.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Icon(
        icon,
        color: foreground,
        size: 18,
      ),
    );
  }
}

class _ValueSelectionTag extends StatelessWidget {
  const _ValueSelectionTag({
    required this.label,
    required this.color,
    required this.disabled,
  });

  final String label;
  final Color color;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = disabled ? scheme.onSurfaceVariant : color;
    final bg = disabled
        ? scheme.surfaceContainerLow
        : color.withValues(alpha: 0.16);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: fg.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
