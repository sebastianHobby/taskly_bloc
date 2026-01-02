import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// A FormBuilder field for selecting an icon from a predefined list.
///
/// Displays icons in a grid and allows selection with visual feedback.
/// Returns the icon name as a String for database storage.
class FormBuilderIconPicker extends FormBuilderFieldDecoration<String> {
  FormBuilderIconPicker({
    required super.name,
    super.key,
    super.validator,
    super.initialValue,
    super.onChanged,
    super.enabled = true,
    super.decoration = const InputDecoration(border: InputBorder.none),
    this.icons = defaultIcons,
    this.gridCrossAxisCount = 5,
    this.iconSize = 28.0,
  }) : super(
         builder: (FormFieldState<String> field) {
           final state =
               field
                   as FormBuilderFieldDecorationState<
                     FormBuilderIconPicker,
                     String
                   >;
           final widget = state.widget;

           return InputDecorator(
             decoration: state.decoration,
             child: _IconPickerGrid(
               icons: widget.icons,
               selected: state.value,
               enabled: state.enabled,
               onSelected: state.didChange,
               crossAxisCount: widget.gridCrossAxisCount,
               iconSize: widget.iconSize,
             ),
           );
         },
       );

  /// List of available icons to choose from.
  final List<IconPickerItem> icons;

  /// Number of columns in the icon grid.
  final int gridCrossAxisCount;

  /// Size of each icon.
  final double iconSize;

  @override
  FormBuilderFieldDecorationState<FormBuilderIconPicker, String>
  createState() => FormBuilderFieldDecorationState();

  /// Default icons for screens and workflows.
  static const List<IconPickerItem> defaultIcons = [
    // Task/Action Icons
    IconPickerItem(name: 'inbox', icon: Icons.inbox),
    IconPickerItem(name: 'today', icon: Icons.today),
    IconPickerItem(name: 'upcoming', icon: Icons.event),
    IconPickerItem(name: 'next_actions', icon: Icons.playlist_play),
    IconPickerItem(name: 'checklist', icon: Icons.checklist),
    IconPickerItem(name: 'task', icon: Icons.task_alt),
    IconPickerItem(name: 'done', icon: Icons.done_all),

    // Project Icons
    IconPickerItem(name: 'projects', icon: Icons.folder),
    IconPickerItem(name: 'folder_open', icon: Icons.folder_open),
    IconPickerItem(name: 'work', icon: Icons.work),
    IconPickerItem(name: 'business', icon: Icons.business_center),

    // Label/Category Icons
    IconPickerItem(name: 'labels', icon: Icons.label),
    IconPickerItem(name: 'tag', icon: Icons.local_offer),
    IconPickerItem(name: 'category', icon: Icons.category),
    IconPickerItem(name: 'bookmark', icon: Icons.bookmark),

    // Value/Goal Icons
    IconPickerItem(name: 'values', icon: Icons.star),
    IconPickerItem(name: 'flag', icon: Icons.flag),
    IconPickerItem(name: 'target', icon: Icons.gps_fixed),
    IconPickerItem(name: 'trophy', icon: Icons.emoji_events),

    // Review/Workflow Icons
    IconPickerItem(name: 'rate_review', icon: Icons.rate_review),
    IconPickerItem(name: 'review', icon: Icons.reviews),
    IconPickerItem(name: 'refresh', icon: Icons.refresh),
    IconPickerItem(name: 'sync', icon: Icons.sync),
    IconPickerItem(name: 'loop', icon: Icons.loop),

    // Time Icons
    IconPickerItem(name: 'schedule', icon: Icons.schedule),
    IconPickerItem(name: 'calendar', icon: Icons.calendar_month),
    IconPickerItem(name: 'timer', icon: Icons.timer),
    IconPickerItem(name: 'alarm', icon: Icons.alarm),

    // Wellbeing Icons
    IconPickerItem(name: 'wellbeing', icon: Icons.favorite),
    IconPickerItem(name: 'mood', icon: Icons.mood),
    IconPickerItem(name: 'journal', icon: Icons.book),
    IconPickerItem(name: 'self_care', icon: Icons.spa),

    // Settings Icons
    IconPickerItem(name: 'settings', icon: Icons.settings),
    IconPickerItem(name: 'tune', icon: Icons.tune),
    IconPickerItem(name: 'dashboard', icon: Icons.dashboard),

    // Misc Icons
    IconPickerItem(name: 'list', icon: Icons.list),
    IconPickerItem(name: 'view_list', icon: Icons.view_list),
    IconPickerItem(name: 'grid', icon: Icons.grid_view),
    IconPickerItem(name: 'filter', icon: Icons.filter_list),
    IconPickerItem(name: 'sort', icon: Icons.sort),
    IconPickerItem(name: 'search', icon: Icons.search),
    IconPickerItem(name: 'lightbulb', icon: Icons.lightbulb),
    IconPickerItem(name: 'info', icon: Icons.info),
  ];

  /// Get an IconData from a stored icon name.
  static IconData? getIconData(String? iconName) {
    if (iconName == null) return null;
    final item = defaultIcons.where((i) => i.name == iconName).firstOrNull;
    return item?.icon;
  }
}

/// Represents an icon option with its name and IconData.
class IconPickerItem {
  const IconPickerItem({
    required this.name,
    required this.icon,
  });

  /// The name stored in the database.
  final String name;

  /// The icon to display.
  final IconData icon;
}

class _IconPickerGrid extends StatelessWidget {
  const _IconPickerGrid({
    required this.icons,
    required this.selected,
    required this.enabled,
    required this.onSelected,
    required this.crossAxisCount,
    required this.iconSize,
  });

  final List<IconPickerItem> icons;
  final String? selected;
  final bool enabled;
  final ValueChanged<String?> onSelected;
  final int crossAxisCount;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final item = icons[index];
        final isSelected = selected == item.name;

        return Material(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: enabled ? () => onSelected(item.name) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : null,
              ),
              child: Icon(
                item.icon,
                size: iconSize,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}
