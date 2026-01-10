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
  String get editLabel => 'Editar';

  @override
  String get cancelLabel => 'Cancelar';

  @override
  String get deleteLabel => 'Eliminar';

  @override
  String get projectsTitle => 'Proyectos';

  @override
  String get tasksTitle => 'Tareas';

  @override
  String get labelsTitle => 'Etiquetas';

  @override
  String get valuesTitle => 'Valores';

  @override
  String get browseTitle => 'Explorar';

  @override
  String get noProjectsFound => 'No se encontraron proyectos.';

  @override
  String get createProjectTooltip => 'Crear proyecto';

  @override
  String get createTaskTooltip => 'Crear tarea';

  @override
  String get deleteValue => 'Delete value';

  @override
  String get editValue => 'Edit value';

  @override
  String get createLabelTooltip => 'Crear etiqueta';

  @override
  String get createValueTooltip => 'Crear valor';

  @override
  String get createLabelOption => 'Crear etiqueta';

  @override
  String get createValueOption => 'Crear valor';

  @override
  String get labelTypeLabelHeading => 'Etiqueta';

  @override
  String get labelTypeValueHeading => 'Valor';

  @override
  String get noLabelsFound => 'No se encontraron etiquetas.';

  @override
  String get noValuesFound => 'No se encontraron valores.';

  @override
  String get genericErrorFallback => 'Algo salió mal. Por favor, inténtalo de nuevo.';

  @override
  String get taskNotFound => 'No se encontró la tarea.';

  @override
  String get projectNotFound => 'No se encontró el proyecto.';

  @override
  String get labelNotFound => 'No se encontró la etiqueta.';

  @override
  String get valueNotFound => 'Value not found.';

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
  String get groupSortMenuTitle => 'Agrupar y ordenar';

  @override
  String get groupSortGroupingLabel => 'Agrupación';

  @override
  String get groupSortSortingLabel => 'Ordenamiento';

  @override
  String get groupOptionNone => 'Sin agrupación';

  @override
  String get groupOptionLabels => 'Agrupar por etiquetas';

  @override
  String get groupOptionValues => 'Agrupar por valores';

  @override
  String get sortFieldNameLabel => 'Nombre';

  @override
  String get sortFieldStartDateLabel => 'Fecha de inicio';

  @override
  String get sortFieldDeadlineDateLabel => 'Fecha límite';

  @override
  String get sortFieldNoneLabel => 'Ninguno';

  @override
  String get sortSlotPrimaryLabel => 'Orden principal';

  @override
  String get sortSlotSecondaryLabel => 'Orden secundario';

  @override
  String get sortSlotTertiaryLabel => 'Orden terciario';

  @override
  String get sortMenuTitle => 'Ordenar';

  @override
  String get sortSortingLabel => 'Orden';

  @override
  String get sortDirectionLabel => 'Dirección';

  @override
  String get sortDirectionAscending => 'Ascendente';

  @override
  String get sortDirectionDescending => 'Descendente';

  @override
  String get groupingMissingLabels => 'Sin etiquetas';

  @override
  String get groupingMissingValues => 'Sin valores';

  @override
  String get groupSortApplyButton => 'Aplicar';

  @override
  String get todayTitle => 'Hoy';

  @override
  String get upcomingTitle => 'Próximas';

  @override
  String get nextActionsTitle => 'Siguientes acciones';

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

  @override
  String get emptyTodayTitle => 'Nada para hoy';

  @override
  String get emptyTodayDescription => 'Las tareas y proyectos del día aparecerán aquí';

  @override
  String get emptyUpcomingTitle => 'Nada próximo';

  @override
  String get emptyUpcomingDescription => 'Las tareas y proyectos futuros aparecerán aquí';

  @override
  String get emptyProjectsTitle => 'Sin proyectos aún';

  @override
  String get emptyProjectsDescription => 'Crea un proyecto para organizar tus tareas';

  @override
  String get emptyTasksTitle => 'Sin tareas aún';

  @override
  String get emptyTasksDescription => 'Añade una tarea para empezar';

  @override
  String get addTaskAction => 'Añadir tarea';

  @override
  String get addProjectAction => 'Añadir proyecto';

  @override
  String get taskFormNameHint => 'Nombre de la tarea';

  @override
  String get taskFormDescriptionHint => 'Descripción';

  @override
  String get taskFormStartDateHint => 'Fecha de inicio (opcional)';

  @override
  String get taskFormDeadlineDateHint => 'Fecha límite (opcional)';

  @override
  String get taskFormProjectHint => 'Proyecto (opcional)';

  @override
  String get taskFormCompletedLabel => 'Completada';

  @override
  String get taskFormNameRequired => 'El nombre es obligatorio';

  @override
  String get taskFormNameEmpty => 'El nombre no puede estar vacío';

  @override
  String get taskFormNameTooLong => 'El nombre debe tener 120 caracteres o menos';

  @override
  String get taskFormDescriptionTooLong => 'La descripción es muy larga';

  @override
  String get taskFormDeadlineAfterStartError => 'La fecha límite debe ser posterior a la fecha de inicio';

  @override
  String get dateToday => 'Hoy';

  @override
  String get dateTomorrow => 'Mañana';

  @override
  String get dateYesterday => 'Ayer';

  @override
  String dateInDays(int days) {
    return 'En $days días';
  }

  @override
  String dateDaysAgo(int days) {
    return 'Hace $days días';
  }

  @override
  String get repeatsLabel => 'Se repite';

  @override
  String get labelTypeLabel => 'Etiqueta';

  @override
  String get labelTypeValue => 'Valor';

  @override
  String get retryButton => 'Reintentar';

  @override
  String get rruleDaily => 'Cada día';

  @override
  String get rruleWeekly => 'Cada semana';

  @override
  String get rruleMonthly => 'Cada mes';

  @override
  String get rruleYearly => 'Cada año';

  @override
  String rruleEveryNDays(int n) {
    return 'Cada $n días';
  }

  @override
  String rruleEveryNWeeks(int n) {
    return 'Cada $n semanas';
  }

  @override
  String rruleEveryNMonths(int n) {
    return 'Cada $n meses';
  }

  @override
  String rruleEveryNYears(int n) {
    return 'Cada $n años';
  }

  @override
  String get rruleOn => 'el';

  @override
  String get rruleOnDay => 'el día';

  @override
  String rruleTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veces',
      one: '1 vez',
    );
    return '$_temp0';
  }

  @override
  String get rruleUntil => 'hasta';

  @override
  String get dayMon => 'Lun';

  @override
  String get dayTue => 'Mar';

  @override
  String get dayWed => 'Mié';

  @override
  String get dayThu => 'Jue';

  @override
  String get dayFri => 'Vie';

  @override
  String get daySat => 'Sáb';

  @override
  String get daySun => 'Dom';

  @override
  String get projectDetailTasksTitle => 'Tareas';

  @override
  String projectDetailTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tareas',
      one: '1 tarea',
      zero: 'Sin tareas',
    );
    return '$_temp0';
  }

  @override
  String projectDetailCompletedCount(int completed, int total) {
    return '$completed de $total completadas';
  }

  @override
  String get projectDetailEmptyTasksDescription => 'Añade tareas a este proyecto para seguir tu progreso';

  @override
  String get projectStatusCompleted => 'Completado';

  @override
  String get projectStatusActive => 'Activo';

  @override
  String get deleteProjectAction => 'Eliminar proyecto';

  @override
  String get markCompleteAction => 'Marcar como completado';

  @override
  String get markIncompleteAction => 'Marcar como incompleto';

  @override
  String get settings => 'Configuración';

  @override
  String get retry => 'Reintentar';

  @override
  String get noTasksToFocusOn => 'No hay tareas en las que enfocarse';

  @override
  String get pinnedTasksSection => 'Tareas Fijadas';

  @override
  String get unpinTask => 'Desfijar tarea';

  @override
  String get pinTask => 'Fijar tarea';

  @override
  String taskUrgentExcludedWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tareas urgentes excluidas de Focus',
      one: '1 tarea urgente excluida de Focus',
    );
    return '$_temp0';
  }

  @override
  String get reviewExcludedTasks => 'Revisar';

  @override
  String get dismissWarning => 'Descartar';

  @override
  String get recurrenceRepeatTitle => 'Repetir';

  @override
  String get recurrenceNever => 'Nunca';

  @override
  String get recurrenceDaily => 'Diario';

  @override
  String get recurrenceWeekly => 'Semanal';

  @override
  String get recurrenceMonthly => 'Mensual';

  @override
  String get recurrenceYearly => 'Anual';

  @override
  String get recurrenceEvery => 'Cada';

  @override
  String get recurrenceOnDays => 'En los días';

  @override
  String get recurrenceEnds => 'Termina';

  @override
  String get recurrenceAfter => 'Después de';

  @override
  String get recurrenceTimesLabel => 'veces';

  @override
  String get recurrenceOn => 'El';

  @override
  String get recurrenceSelectDate => 'Seleccionar fecha';

  @override
  String get recurrenceDoesNotRepeat => 'No se repite';

  @override
  String get validationRequired => 'Requerido';

  @override
  String get validationInvalid => 'Inválido';

  @override
  String get validationMustBeGreaterThanZero => 'Debe ser > 0';

  @override
  String validationMaxValue(int max) {
    return 'Máx $max';
  }

  @override
  String get doneButton => 'Listo';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsAppearanceSection => 'Apariencia';

  @override
  String get settingsLanguageRegionSection => 'Idioma y región';

  @override
  String get settingsAdvancedSection => 'Avanzado';

  @override
  String get settingsThemeMode => 'Modo de tema';

  @override
  String get settingsThemeModeSubtitle => 'Elige entre tema claro, oscuro o del sistema';

  @override
  String get settingsTextSize => 'Tamaño del texto';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Selecciona tu idioma preferido';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsDateFormat => 'Formato de fecha';

  @override
  String get settingsDateFormatShort => 'Corto';

  @override
  String get settingsDateFormatMedium => 'Medio';

  @override
  String get settingsDateFormatLong => 'Largo';

  @override
  String get settingsDateFormatFull => 'Completo';

  @override
  String get settingsDateFormatCustom => 'Personalizado';

  @override
  String settingsDateFormatExample(String example) {
    return 'Ejemplo: $example';
  }

  @override
  String get settingsResetToDefaults => 'Restablecer valores predeterminados';

  @override
  String get settingsResetTitle => 'Restablecer configuración';

  @override
  String get settingsResetConfirmation => '¿Estás seguro de que quieres restablecer toda la configuración a sus valores predeterminados?';

  @override
  String get settingsResetSuccess => 'Configuración restablecida a valores predeterminados';

  @override
  String get resetButton => 'Restablecer';

  @override
  String get sortFieldCreatedDate => 'Fecha de creación';

  @override
  String get sortFieldUpdatedDate => 'Fecha de actualización';

  @override
  String get sortFieldNextActionPriority => 'Prioridad de próxima acción';

  @override
  String get sortOrderHelp => 'Elige cómo ordenar los elementos';

  @override
  String get saveButton => 'Guardar';

  @override
  String get discardButton => 'Descartar';

  @override
  String get unsavedChangesTitle => 'Cambios sin guardar';

  @override
  String get confirmButton => 'Confirmar';

  @override
  String get focusModeSectionTitle => '¿Cómo debería Enfoque priorizar las tareas?';

  @override
  String get recommendedLabel => 'Recomendado';

  @override
  String get urgencyThresholdsSection => 'Umbrales de Urgencia';

  @override
  String get taskUrgencyDays => 'Urgencia de tarea (días antes de la fecha límite)';

  @override
  String get projectUrgencyDays => 'Urgencia de proyecto (días antes de la fecha límite)';

  @override
  String get displayOptionsSection => 'Opciones de Visualización';

  @override
  String get showUnassignedTaskCount => 'Mostrar conteo de tareas sin asignar';

  @override
  String get showProjectNextTask => 'Mostrar siguiente tarea del proyecto';

  @override
  String get dailyTaskLimit => 'Límite diario de tareas';

  @override
  String get advancedSettingsSection => 'Configuración Avanzada';

  @override
  String get urgentTaskHandling => 'Manejo de tareas urgentes';

  @override
  String get urgentTaskIgnore => 'Ignorar';

  @override
  String get urgentTaskIgnoreDescription => 'La urgencia no tiene efecto, sin advertencias';

  @override
  String get urgentTaskWarnOnly => 'Solo advertir';

  @override
  String get urgentTaskWarnOnlyDescription => 'Tareas urgentes excluidas pero muestran advertencias';

  @override
  String get urgentTaskIncludeAll => 'Incluir todas';

  @override
  String get urgentTaskIncludeAllDescription => 'Todas las tareas urgentes se incluyen';

  @override
  String get valueAlignedUrgencyBoost => 'Impulso de urgencia alineada con valores';

  @override
  String get enableNeglectWeighting => 'Habilitar ponderación por descuido';

  @override
  String get reflectorLookbackDays => 'Días de retrospectiva del Reflector';

  @override
  String get neglectInfluence => 'Influencia de descuido (0-1)';

  @override
  String get switchedToCustomMode => 'Cambiado a modo Personalizado';

  @override
  String get allocationSettingsTitle => 'Configuración de Asignación';

  @override
  String get saveLabel => 'Guardar';

  @override
  String get valueRankingsTitle => 'Clasificación de Valores';

  @override
  String get valueRankingsDescription => 'Arrastra para reordenar. Los valores más altos obtienen más tareas de enfoque.';

  @override
  String get noValuesForRanking => 'No se encontraron valores. Crea valores en la pantalla de Valores.';

  @override
  String get weightLabel => 'Peso';

  @override
  String get notRankedDragToRank => 'Sin clasificar - arrastra para clasificar';

  @override
  String get recommendedNextActionLabel => 'Próxima Acción Recomendada';

  @override
  String get startLabel => 'Iniciar';

  @override
  String get projectNextTaskPrefix => '→ Siguiente:';

  @override
  String taskPinnedToFocus(String taskName) {
    return '\'$taskName\' fijada en Focus';
  }

  @override
  String deadlineFormatDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Vence en $days días',
      one: 'Vence mañana',
      zero: 'Vence hoy',
    );
    return '$_temp0';
  }

  @override
  String get deadlineOverdue => 'Vencida';

  @override
  String get reflectorBuildingHistory => 'Construyendo tu historial...';

  @override
  String reflectorHistoryExplanation(int count, int days) {
    return 'Reflector funciona mejor con más datos. Tienes $count completadas en los últimos $days días. Usando pesos de valores por ahora.';
  }

  @override
  String get targetLabel => 'Objetivo';

  @override
  String get actualLabel => 'Actual';

  @override
  String get gapLabel => 'Brecha';

  @override
  String valueActivityCounts(int taskCount, int projectCount) {
    return '$taskCount tareas · $projectCount proyectos';
  }

  @override
  String weekTrendTitle(int weeks) {
    return 'Tendencia de $weeks Semanas';
  }

  @override
  String get noTrendData => 'Sin datos de tendencia aún';

  @override
  String get activitySectionTitle => 'Actividad';

  @override
  String activeTasksCount(int count) {
    return '$count tareas activas';
  }

  @override
  String projectsCount(int count) {
    return '$count proyectos';
  }

  @override
  String get unassignedWorkTitle => 'Trabajo Sin Asignar';

  @override
  String get valuesGatewayTitle => 'Prioriza Lo Que Importa';

  @override
  String get valuesGatewayDescription => 'Focus utiliza tus valores personales para recomendar qué tareas merecen tu atención hoy.\n\nDefine lo que es importante para ti—como Salud, Familia, Carrera—y Focus te ayudará a dedicar tiempo a lo que realmente importa.';

  @override
  String get setUpMyValues => 'Configurar Mis Valores';

  @override
  String get myDayTitle => 'My Day';

  @override
  String get myDayAlertBannerSingular => '1 item outside Focus';

  @override
  String myDayAlertBannerPlural(int count) {
    return '$count items outside Focus';
  }

  @override
  String get myDayAlertBannerReview => 'Review';

  @override
  String get excludedSectionNeedsAlignment => 'Needs Alignment';

  @override
  String get excludedSectionWorthConsidering => 'Worth Considering';

  @override
  String get excludedSectionOverdueAttention => 'Overdue Attention';

  @override
  String get excludedSectionActiveFires => 'Active Fires';

  @override
  String get excludedSectionOutsideFocus => 'Outside Focus';

  @override
  String get alertTypeUrgent => 'Urgent tasks';

  @override
  String get alertTypeOverdue => 'Overdue tasks';

  @override
  String get alertTypeNoValue => 'Tasks without values';

  @override
  String get alertTypeLowPriority => 'Low priority tasks';

  @override
  String get alertTypeQuotaFull => 'Quota exceeded tasks';

  @override
  String get alertSeverityCritical => 'Critical';

  @override
  String get alertSeverityWarning => 'Warning';

  @override
  String get alertSeverityNotice => 'Notice';

  @override
  String get basicInfoSection => 'Información Básica';

  @override
  String get focusModeSectionSubtitle => 'Elige un modo de enfoque para controlar cómo se priorizan las tareas';

  @override
  String get taskLimitSection => 'Límite de Tareas';

  @override
  String get sourceFilterSection => 'Filtrar Fuente';

  @override
  String get sourceFilterSubtitle => 'Limitar qué tareas se consideran';

  @override
  String get saving => 'Guardando...';

  @override
  String get saveFocusScreen => 'Guardar Pantalla Focus';

  @override
  String get maxTasksLabel => 'Máximo de Tareas';

  @override
  String get showExcludedSection => 'Mostrar sección excluida';

  @override
  String get showExcludedSectionSubtitle => 'Mostrar tareas excluidas al final';

  @override
  String get urgentTaskBehaviorLabel => 'Manejo de tareas urgentes';

  @override
  String get urgentBehaviorIgnore => 'Ignorar tareas urgentes';

  @override
  String get urgentBehaviorWarnOnly => 'Advertir sobre tareas urgentes';

  @override
  String get urgentBehaviorIncludeAll => 'Incluir todas las tareas urgentes';

  @override
  String daysFormat(int count) {
    return '$count días';
  }

  @override
  String get dailyTaskLimitLabel => 'Daily Task Limit';

  @override
  String get dailyTaskLimitHelper => 'Maximum number of tasks to schedule per day';

  @override
  String get strategyTitle => 'Strategy';

  @override
  String get enableNeglectWeightingLabel => 'Enable Neglect Weighting';

  @override
  String get enableNeglectWeightingHelper => 'Prioritize tasks that have been neglected';

  @override
  String get displayTitle => 'Display';

  @override
  String get showOrphanTaskCountLabel => 'Show Orphan Task Count';

  @override
  String get showProjectNextTaskLabel => 'Show Project Next Task';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String settingsSaveError(Object error) {
    return 'Error saving settings: $error';
  }

  @override
  String settingsLoadError(Object error) {
    return 'Error loading settings: $error';
  }
}
