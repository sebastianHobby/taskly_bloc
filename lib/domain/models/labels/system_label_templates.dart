import 'package:taskly_bloc/domain/models/label.dart';

/// System label templates defined in code.
///
/// These labels are never stored in the database. Instead, they are
/// merged with database labels at runtime by the LabelRepository.
///
/// This eliminates sync conflicts that occur when seeding system data
/// after authentication races with PowerSync's initial sync.
class SystemLabelTemplates {
  SystemLabelTemplates._();

  /// All system label types.
  static const List<SystemLabelType> allTypes = [
    SystemLabelType.pinned,
  ];

  /// Get a system label template by type.
  ///
  /// The returned [Label] has placeholder values for:
  /// - `id`: Empty string (system labels have no database ID)
  /// - `createdAt`/`updatedAt`: Epoch time
  ///
  /// Returns `null` if the type is not recognized.
  static Label? getTemplate(SystemLabelType type) {
    return _templates[type];
  }

  /// Get all system label templates.
  static List<Label> getAllTemplates() {
    return allTypes.map((type) => _templates[type]!).toList();
  }

  /// Get the display name for a system label type.
  static String getNameForType(SystemLabelType type) {
    switch (type) {
      case SystemLabelType.pinned:
        return 'Pinned';
    }
  }

  /// Get the icon name for a system label type.
  static String getIconNameForType(SystemLabelType type) {
    switch (type) {
      case SystemLabelType.pinned:
        return 'pin';
    }
  }

  /// Get the color for a system label type.
  static String getColorForType(SystemLabelType type) {
    switch (type) {
      case SystemLabelType.pinned:
        return '#FF9800'; // Orange
    }
  }

  static final Map<SystemLabelType, Label> _templates = {
    SystemLabelType.pinned: Label(
      id: '', // System labels have no database ID
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      name: getNameForType(SystemLabelType.pinned),
      color: getColorForType(SystemLabelType.pinned),
      iconName: getIconNameForType(SystemLabelType.pinned),
      isSystemLabel: true,
      systemLabelType: SystemLabelType.pinned,
    ),
  };

  /// Check if a label is a system label by its systemLabelType.
  static bool isSystemLabel(Label label) {
    return label.isSystemLabel && label.systemLabelType != null;
  }
}
