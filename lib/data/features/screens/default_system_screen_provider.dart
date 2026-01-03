import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';

/// Default implementation of [SystemScreenProvider].
///
/// Delegates to [SystemScreenDefinitions] for screen templates and
/// uses [IdGenerator] to assign deterministic v5 UUIDs based on screenKey.
class DefaultSystemScreenProvider implements SystemScreenProvider {
  DefaultSystemScreenProvider(this._idGenerator);

  final IdGenerator _idGenerator;

  /// Cache of system screens (lazy initialized).
  List<ScreenDefinition>? _cachedScreens;

  @override
  List<ScreenDefinition> getSystemScreens() {
    return _cachedScreens ??= _buildSystemScreens();
  }

  @override
  ScreenDefinition? getSystemScreen(String screenKey) {
    final template = SystemScreenDefinitions.getByKey(screenKey);
    if (template == null) return null;
    return _assignId(template);
  }

  @override
  bool isSystemScreen(String screenKey) {
    return SystemScreenDefinitions.isSystemScreen(screenKey);
  }

  @override
  List<String> get allSystemScreenKeys => SystemScreenDefinitions.allKeys;

  @override
  int getDefaultSortOrder(String screenKey) {
    return SystemScreenDefinitions.getDefaultSortOrder(screenKey);
  }

  /// Builds all system screens with IDs assigned.
  List<ScreenDefinition> _buildSystemScreens() {
    return SystemScreenDefinitions.all.map(_assignId).toList();
  }

  /// Assigns a deterministic v5 UUID to a screen template.
  ScreenDefinition _assignId(ScreenDefinition template) {
    final id = _idGenerator.screenDefinitionId(screenKey: template.screenKey);
    return template.copyWith(id: id);
  }
}
