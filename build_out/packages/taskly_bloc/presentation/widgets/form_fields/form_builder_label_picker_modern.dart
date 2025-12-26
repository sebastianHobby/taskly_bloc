import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A modern label picker with improved chip design and organization.
///
/// Features:
/// - Modern Material 3 chip design
/// - Organized by label types (values vs labels)
/// - Color-coded chips with proper contrast
/// - Smooth animations and interactions
/// - Better visual hierarchy
/// - "Add new" option for creating labels/values inline
class FormBuilderLabelPickerModern
    extends FormBuilderFieldDecoration<List<String>> {
  FormBuilderLabelPickerModern({
    required super.name,
    required this.availableLabels,
    this.valuesHeading = 'Values',
    this.labelsHeading = 'Labels',
    this.emptyMessage = 'No labels available',
    this.onAddNewValue,
    this.onAddNewLabel,
    super.key,
    super.initialValue,
    super.validator,
    super.decoration = const InputDecoration(border: InputBorder.none),
    super.enabled,
    super.onChanged,
    super.valueTransformer,
    super.onReset,
    super.focusNode,
    super.autovalidateMode,
  }) : super(
         builder: (FormFieldState<List<String>> field) {
           final state = field as _FormBuilderLabelPickerModernState;
           return state._buildContent();
         },
       );

  /// All available labels to choose from.
  final List<Label> availableLabels;

  /// Heading displayed above the "values" section.
  final String valuesHeading;

  /// Heading displayed above the "labels" section.
  final String labelsHeading;

  /// Message shown when no labels are available.
  final String emptyMessage;

  /// Callback when user wants to add a new value.
  /// If null, the "Add value" chip won't be shown.
  /// Should return true if a new value was successfully created.
  final Future<bool> Function()? onAddNewValue;

  /// Callback when user wants to add a new label.
  /// If null, the "Add label" chip won't be shown.
  /// Should return true if a new label was successfully created.
  final Future<bool> Function()? onAddNewLabel;

  @override
  FormBuilderFieldDecorationState<FormBuilderLabelPickerModern, List<String>>
  createState() => _FormBuilderLabelPickerModernState();
}

class _FormBuilderLabelPickerModernState
    extends
        FormBuilderFieldDecorationState<
          FormBuilderLabelPickerModern,
          List<String>
        > {
  List<Label> get _labelTypeLabels =>
      widget.availableLabels.where((l) => l.type == LabelType.label).toList();

  List<Label> get _labelTypeValues =>
      widget.availableLabels.where((l) => l.type == LabelType.value).toList();

  List<String> get _selected => List<String>.from(value ?? const <String>[]);

  void _toggle(String id, bool isSelected) {
    final updated = List<String>.from(_selected);
    if (isSelected) {
      if (!updated.contains(id)) {
        updated.add(id);
      }
    } else {
      updated.remove(id);
    }
    didChange(updated);
  }

  Widget _buildContent() {
    // Filter to only show selected labels/values
    final selectedValues = _labelTypeValues
        .where((label) => _selected.contains(label.id))
        .toList();
    final selectedLabels = _labelTypeLabels
        .where((label) => _selected.contains(label.id))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always show value section with Add button
          _buildSection(
            widget.valuesHeading,
            selectedValues,
            LabelType.value,
          ),
          const SizedBox(height: 24),
          // Always show label section with Add button
          _buildSection(
            widget.labelsHeading,
            selectedLabels,
            LabelType.label,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String heading,
    List<Label> items,
    LabelType type,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onAddNew = type == LabelType.value
        ? widget.onAddNewValue
        : widget.onAddNewLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Always show header
        Row(
          children: [
            Icon(
              type == LabelType.value ? Icons.favorite : Icons.label,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              heading,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...items.map(_buildLabelChip),
            _buildAddNewChip(type, onAddNew),
          ],
        ),
      ],
    );
  }

  Widget _buildAddNewChip(
    LabelType type,
    Future<bool> Function()? onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = type == LabelType.value ? 'Add value' : 'Add label';

    return ActionChip(
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      avatar: Icon(
        Icons.add,
        size: 18,
        color: colorScheme.primary,
      ),
      onPressed: widget.enabled
          ? () => _showSelectionDialog(type, onTap)
          : null,
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      side: BorderSide(
        color: colorScheme.primary.withValues(alpha: 0.4),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _showSelectionDialog(
    LabelType type,
    Future<bool> Function()? onAddNew,
  ) async {
    final items = type == LabelType.value ? _labelTypeValues : _labelTypeLabels;
    final title = type == LabelType.value ? 'Select Values' : 'Select Labels';

    // Create a copy of current selection to track changes
    final tempSelection = Set<String>.from(_selected);

    final result = await showDialog<_DialogResult>(
      context: context,
      builder: (context) => _SelectionDialog(
        title: title,
        items: items,
        selectedIds: tempSelection,
        onAddNew: onAddNew,
        type: type,
      ),
    );

    // Handle the result
    if (result == _DialogResult.confirmed) {
      // User confirmed selection
      didChange(tempSelection.toList());
    } else if (result == _DialogResult.createNew && onAddNew != null) {
      // User wants to create a new label/value
      final created = await onAddNew();
      // If a new item was created, reopen the dialog
      if (created && mounted) {
        await _showSelectionDialog(type, onAddNew);
      }
    }
  }

  Widget _buildLabelChip(Label label) {
    final isSelected = _selected.contains(label.id);
    final color = ColorUtils.fromHex(label.color);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isValue = label.type == LabelType.value;

    // For values: use colored background when selected
    // For labels: use neutral background with colored icon
    final backgroundColor = isValue && isSelected
        ? color
        : colorScheme.surfaceContainerLow;
    final selectedColor = isValue ? color : colorScheme.surfaceContainerHighest;
    final textColor = isValue && isSelected
        ? (color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
        : colorScheme.onSurface;

    // Get the icon - emoji for values, colored label icon for labels
    final Widget icon;
    if (isValue) {
      final emoji = label.iconName?.isNotEmpty ?? false
          ? label.iconName!
          : 'â¤ï¸';
      icon = Text(
        emoji,
        style: const TextStyle(fontSize: 14),
      );
    } else {
      icon = Icon(
        Icons.label,
        size: 14,
        color: color,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: FilterChip(
        label: Text(
          label.name,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        avatar: icon,
        selected: isSelected,
        onSelected: !widget.enabled
            ? null
            : (selected) => _toggle(label.id, selected),
        onDeleted: isSelected && widget.enabled
            ? () => _toggle(label.id, false)
            : null,
        deleteIcon: Icon(
          Icons.close,
          size: 16,
          color: isValue && isSelected ? textColor : colorScheme.onSurface,
        ),
        deleteIconColor: isValue && isSelected
            ? textColor
            : colorScheme.onSurface,
        backgroundColor: backgroundColor,
        selectedColor: selectedColor,
        checkmarkColor: Colors.transparent,
        side: BorderSide(
          color: isSelected
              ? color
              : colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        elevation: isSelected ? 2 : 0,
        shadowColor: color.withValues(alpha: 0.3),
      ),
    );
  }
}

// Dialog result enum
enum _DialogResult {
  confirmed,
  cancelled,
  createNew,
}

// Dialog for selecting labels/values with option to add new
class _SelectionDialog extends StatefulWidget {
  const _SelectionDialog({
    required this.title,
    required this.items,
    required this.selectedIds,
    required this.onAddNew,
    required this.type,
  });
  final String title;
  final List<Label> items;
  final Set<String> selectedIds;
  final Future<bool> Function()? onAddNew;
  final LabelType type;

  @override
  State<_SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<_SelectionDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: [
                  Icon(
                    widget.type == LabelType.value
                        ? Icons.favorite_outline
                        : Icons.label_outline,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        Navigator.of(context).pop(_DialogResult.cancelled),
                    tooltip: 'Cancel',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Items list
            if (widget.items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      widget.type == LabelType.value
                          ? Icons.favorite_border
                          : Icons.label_off_outlined,
                      size: 48,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.type == LabelType.value
                          ? 'No values available'
                          : 'No labels available',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first one below',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final isSelected = widget.selectedIds.contains(item.id);
                    final color = ColorUtils.fromHex(item.color);
                    final hasEmoji =
                        item.iconName != null && item.iconName!.isNotEmpty;

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value ?? false) {
                            widget.selectedIds.add(item.id);
                          } else {
                            widget.selectedIds.remove(item.id);
                          }
                        });
                      },
                      title: Text(
                        item.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      secondary: hasEmoji
                          ? Text(
                              item.iconName!,
                              style: const TextStyle(fontSize: 24),
                            )
                          : Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                            ),
                      activeColor: colorScheme.primary,
                    );
                  },
                ),
              ),

            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Create new button (only shown if callback is provided)
                  if (widget.onAddNew != null) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(_DialogResult.createNew);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        widget.type == LabelType.value
                            ? 'Create new value'
                            : 'Create new label',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Confirm/Cancel buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_DialogResult.cancelled),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_DialogResult.confirmed),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
