// dart format off
// coverage:ignore-file

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get counterAppBarTitle => 'Contador';

  @override
  String get projectsTitle => 'Proyectos';

  @override
  String get tasksTitle => 'Tareas';

  @override
  String get valuesTitle => 'Valores';

  @override
  String get noProjectsFound => 'No se encontraron proyectos.';

  @override
  String get createProjectTooltip => 'Crear proyecto';

  @override
  String get createTaskTooltip => 'Crear tarea';

  @override
  String get createValueTooltip => 'Crear valor';

  @override
  String get genericErrorFallback => 'Algo salió mal. Por favor, inténtalo de nuevo.';
}
