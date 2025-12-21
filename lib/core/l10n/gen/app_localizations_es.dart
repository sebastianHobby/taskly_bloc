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

  @override
  String get taskCreatedSuccessfully => 'Tarea creada correctamente.';

  @override
  String get taskUpdatedSuccessfully => 'Tarea actualizada correctamente.';

  @override
  String get taskDeletedSuccessfully => 'Tarea eliminada correctamente.';

  @override
  String get projectCreatedSuccessfully => 'Proyecto creado correctamente.';

  @override
  String get projectUpdatedSuccessfully => 'Proyecto actualizado correctamente.';

  @override
  String get projectDeletedSuccessfully => 'Proyecto eliminado correctamente.';

  @override
  String get valueCreatedSuccessfully => 'Valor creado correctamente.';

  @override
  String get valueUpdatedSuccessfully => 'Valor actualizado correctamente.';

  @override
  String get valueDeletedSuccessfully => 'Valor eliminado correctamente.';

  @override
  String get labelCreatedSuccessfully => 'Etiqueta creada correctamente.';

  @override
  String get labelUpdatedSuccessfully => 'Etiqueta actualizada correctamente.';

  @override
  String get labelDeletedSuccessfully => 'Etiqueta eliminada correctamente.';

  @override
  String get actionCreate => 'Crear';

  @override
  String get actionUpdate => 'Actualizar';

  @override
  String get projectFormTitleHint => 'Título';

  @override
  String get projectFormTitleRequired => 'El título es obligatorio';

  @override
  String get projectFormTitleEmpty => 'El título no puede estar vacío';

  @override
  String get projectFormTitleTooLong => 'El título debe tener 120 caracteres o menos';

  @override
  String get projectFormDescriptionHint => 'Descripción';

  @override
  String get projectFormDescriptionTooLong => 'La descripción es demasiado larga';

  @override
  String get projectFormStartDateHint => 'Fecha de inicio (opcional)';

  @override
  String get projectFormDeadlineDateHint => 'Fecha límite (opcional)';

  @override
  String get projectFormDeadlineAfterStartError => 'La fecha límite debe ser posterior a la fecha de inicio';

  @override
  String get projectFormCompletedLabel => 'Completado';

  @override
  String get projectFormValuesLabel => 'Valores';

  @override
  String get projectFormLabelsLabel => 'Etiquetas';

  @override
  String get projectFormRepeatRuleHint => 'Regla de repetición (RRULE, opcional)';

  @override
  String get projectFormRepeatRuleTooLong => 'La regla de repetición es demasiado larga';
}
