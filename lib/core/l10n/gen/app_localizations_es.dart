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
  String get labelsTitle => 'Etiquetas';

  @override
  String get noProjectsFound => 'No se encontraron proyectos.';

  @override
  String get createProjectTooltip => 'Crear proyecto';

  @override
  String get createTaskTooltip => 'Crear tarea';

  @override
  String get createValueTooltip => 'Crear valor';

  @override
  String get createLabelTooltip => 'Crear etiqueta';

  @override
  String get noLabelsFound => 'No se encontraron etiquetas.';

  @override
  String get genericErrorFallback => 'Algo salió mal. Por favor, inténtalo de nuevo.';

  @override
  String get taskNotFound => 'No se encontró la tarea.';

  @override
  String get projectNotFound => 'No se encontró el proyecto.';

  @override
  String get valueNotFound => 'No se encontró el valor.';

  @override
  String get labelNotFound => 'No se encontró la etiqueta.';

  @override
  String get taskFilterAll => 'Todas las tareas';

  @override
  String get taskFilterActive => 'Tareas activas';

  @override
  String get taskFilterCompleted => 'Tareas completadas';

  @override
  String get taskSortByName => 'Ordenar por nombre';

  @override
  String get taskSortByDeadline => 'Ordenar por fecha límite';

  @override
  String get inboxTitle => 'Bandeja de entrada';

  @override
  String get todayTitle => 'Hoy';

  @override
  String get upcomingTitle => 'Próximas';
}
