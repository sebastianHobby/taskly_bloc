import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_tracker_wizard_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/journal_unit_catalog.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_icons.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

enum JournalTrackerWizardMode { tracker, dailyCheckin }

class JournalTrackerWizardPage extends StatelessWidget {
  const JournalTrackerWizardPage({
    this.mode = JournalTrackerWizardMode.tracker,
    this.trackerKind,
    super.key,
  });

  final JournalTrackerWizardMode mode;
  final JournalTrackerKind? trackerKind;

  @override
  Widget build(BuildContext context) {
    final forcedScope = mode == JournalTrackerWizardMode.dailyCheckin
        ? JournalTrackerScopeOption.day
        : JournalTrackerScopeOption.entry;
    return BlocProvider<JournalTrackerWizardBloc>(
      create: (context) => JournalTrackerWizardBloc(
        repository: context.read<JournalRepositoryContract>(),
        errorReporter: context.read<AppErrorReporter>(),
        nowUtc: context.read<NowService>().nowUtc,
        forcedScope: forcedScope,
        trackerKind: trackerKind,
      )..add(const JournalTrackerWizardStarted()),
      child: _JournalTrackerWizardView(mode: mode, trackerKind: trackerKind),
    );
  }
}

class _JournalTrackerWizardView extends StatefulWidget {
  const _JournalTrackerWizardView({
    required this.mode,
    required this.trackerKind,
  });

  final JournalTrackerWizardMode mode;
  final JournalTrackerKind? trackerKind;

  @override
  State<_JournalTrackerWizardView> createState() =>
      _JournalTrackerWizardViewState();
}

class _JournalTrackerWizardViewState extends State<_JournalTrackerWizardView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _choiceController = TextEditingController();
  bool _showActivityAdvanced = false;

  @override
  void dispose() {
    _nameController.dispose();
    _choiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JournalTrackerWizardBloc, JournalTrackerWizardState>(
      listenWhen: (prev, next) =>
          prev.status.runtimeType != next.status.runtimeType,
      listener: (context, state) {
        if (state.status is JournalTrackerWizardSaved) {
          Navigator.of(context).pop(true);
          return;
        }
        if (state.status case final JournalTrackerWizardError status) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(status.message)));
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final tokens = TasklyTokens.of(context);
        final isSaving = state.status is JournalTrackerWizardSaving;
        final isLoading = state.status is JournalTrackerWizardLoading;
        final isAggregateKind =
            widget.trackerKind == JournalTrackerKind.aggregate;
        final isActivityKind =
            widget.trackerKind == JournalTrackerKind.activity &&
            widget.mode == JournalTrackerWizardMode.tracker;

        if (_nameController.text != state.name) {
          _nameController.text = state.name;
          _nameController.selection = TextSelection.fromPosition(
            TextPosition(offset: _nameController.text.length),
          );
        }

        bool canSave() {
          if (state.name.trim().isEmpty) return false;
          final effectiveMeasurement =
              state.measurement ??
              (isAggregateKind
                  ? JournalTrackerMeasurementType.quantity
                  : JournalTrackerMeasurementType.toggle);
          if (effectiveMeasurement == JournalTrackerMeasurementType.choice) {
            return state.choiceLabels.any((label) => label.trim().isNotEmpty);
          }
          if (effectiveMeasurement == JournalTrackerMeasurementType.quantity) {
            final unitKey = state.quantityUnit.trim().toLowerCase();
            return isCanonicalUnitKey(unitKey);
          }
          return true;
        }

        final body = isLoading
            ? const Center(child: CircularProgressIndicator())
            : isActivityKind
            ? _buildActivityFormBody(
                context: context,
                state: state,
                isSaving: isSaving,
              )
            : _buildFormBody(
                context: context,
                state: state,
                isAggregateKind: isAggregateKind,
                isSaving: isSaving,
              );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isActivityKind
                  ? context.l10n.journalNewTrackerTitle
                  : context.l10n.journalConfigureTrackerTitle,
            ),
          ),
          body: body,
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceLg,
                tokens.spaceSm,
                tokens.spaceLg,
                tokens.spaceLg,
              ),
              child: FilledButton.icon(
                onPressed: isSaving || !canSave()
                    ? null
                    : () => context.read<JournalTrackerWizardBloc>().add(
                        const JournalTrackerWizardSaveRequested(),
                      ),
                icon: isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Icon(isActivityKind ? Icons.check : Icons.arrow_forward),
                label: Text(context.l10n.createLabel),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityFormBody({
    required BuildContext context,
    required JournalTrackerWizardState state,
    required bool isSaving,
  }) {
    final tokens = TasklyTokens.of(context);
    final measurement =
        state.measurement ?? JournalTrackerMeasurementType.toggle;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceMd,
        tokens.spaceLg,
        tokens.spaceLg,
      ),
      children: [
        _sectionLabel(context.l10n.journalTrackerNameHint),
        SizedBox(height: tokens.spaceSm),
        TextField(
          controller: _nameController,
          enabled: !isSaving,
          decoration: InputDecoration(
            hintText: context.l10n.journalTrackerNameHint,
          ),
          textInputAction: TextInputAction.next,
          onChanged: (value) => context.read<JournalTrackerWizardBloc>().add(
            JournalTrackerWizardNameChanged(value),
          ),
        ),
        SizedBox(height: tokens.spaceLg),
        _sectionLabel(context.l10n.valueFormIconLabel),
        SizedBox(height: tokens.spaceSm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final iconName in _buildActivityIconOptions(state)) ...[
                _ActivityIconTile(
                  iconName: iconName,
                  selected: (state.iconName ?? '').trim() == iconName,
                  onTap: isSaving
                      ? null
                      : () => context.read<JournalTrackerWizardBloc>().add(
                          JournalTrackerWizardIconChanged(iconName),
                        ),
                ),
                SizedBox(width: tokens.spaceSm),
              ],
              _ActivityIconTile(
                iconName: 'trackers',
                selected: false,
                onTap: isSaving ? null : () => _pickIcon(context, state),
                customChild: const Icon(Icons.more_horiz),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceLg),
        _sectionLabel(context.l10n.groupLabel),
        SizedBox(height: tokens.spaceSm),
        _ActivityGroupGrid(
          groups: state.groups,
          selectedGroupId: state.groupId,
          onSelected: isSaving
              ? null
              : (groupId) => context.read<JournalTrackerWizardBloc>().add(
                  JournalTrackerWizardGroupChanged(groupId),
                ),
          onCreateGroup: isSaving ? null : () => _createGroup(context),
        ),
        SizedBox(height: tokens.spaceLg),
        _TrackerConfigurePreview(
          trackerName: state.name,
          iconName: state.iconName,
          measurement: measurement,
          groupName: _groupNameFor(state),
          unit: state.quantityUnit,
          aggregationKind: state.aggregationKind,
          quantityGoal: state.quantityGoal,
          isAggregate: false,
        ),
        SizedBox(height: tokens.spaceLg),
        _AdvancedDisclosure(
          title: context.l10n.journalAdvancedSettingsLabel,
          expanded: _showActivityAdvanced,
          onTap: () {
            setState(() {
              _showActivityAdvanced = !_showActivityAdvanced;
            });
          },
        ),
        if (_showActivityAdvanced) ...[
          SizedBox(height: tokens.spaceMd),
          _fieldLabel(context.l10n.journalMeasurementTitle),
          SizedBox(height: tokens.spaceXs),
          _MeasurementOption(
            title: context.l10n.journalMeasurementToggleTitle,
            subtitle: context.l10n.journalMeasurementToggleSubtitle,
            selected: measurement == JournalTrackerMeasurementType.toggle,
            onTap: isSaving
                ? null
                : () => context.read<JournalTrackerWizardBloc>().add(
                    const JournalTrackerWizardMeasurementChanged(
                      JournalTrackerMeasurementType.toggle,
                    ),
                  ),
          ),
          _MeasurementOption(
            title: context.l10n.journalMeasurementRatingTitle,
            subtitle: context.l10n.journalMeasurementRatingSubtitle,
            selected: measurement == JournalTrackerMeasurementType.rating,
            onTap: isSaving
                ? null
                : () => context.read<JournalTrackerWizardBloc>().add(
                    const JournalTrackerWizardMeasurementChanged(
                      JournalTrackerMeasurementType.rating,
                    ),
                  ),
          ),
          _MeasurementOption(
            title: context.l10n.journalMeasurementQuantityTitle,
            subtitle: context.l10n.journalMeasurementQuantityEntrySubtitle,
            selected: measurement == JournalTrackerMeasurementType.quantity,
            onTap: isSaving
                ? null
                : () => context.read<JournalTrackerWizardBloc>().add(
                    const JournalTrackerWizardMeasurementChanged(
                      JournalTrackerMeasurementType.quantity,
                    ),
                  ),
          ),
          _MeasurementOption(
            title: context.l10n.journalMeasurementChoiceTitle,
            subtitle: context.l10n.journalMeasurementChoiceSubtitle,
            selected: measurement == JournalTrackerMeasurementType.choice,
            onTap: isSaving
                ? null
                : () => context.read<JournalTrackerWizardBloc>().add(
                    const JournalTrackerWizardMeasurementChanged(
                      JournalTrackerMeasurementType.choice,
                    ),
                  ),
          ),
          if (measurement == JournalTrackerMeasurementType.rating) ...[
            SizedBox(height: tokens.spaceMd),
            _RatingConfigForm(
              min: state.ratingMin,
              max: state.ratingMax,
              step: state.ratingStep,
              enabled: !isSaving,
              onChanged: (min, max, step) =>
                  context.read<JournalTrackerWizardBloc>().add(
                    JournalTrackerWizardRatingConfigChanged(
                      min: min,
                      max: max,
                      step: step,
                    ),
                  ),
            ),
          ],
          if (measurement == JournalTrackerMeasurementType.quantity) ...[
            SizedBox(height: tokens.spaceMd),
            _fieldLabel(context.l10n.journalUnitLabel),
            SizedBox(height: tokens.spaceXs),
            _QuantityUnitField(
              unit: state.quantityUnit,
              enabled: !isSaving,
              onChanged: (unit) => context.read<JournalTrackerWizardBloc>().add(
                JournalTrackerWizardQuantityConfigChanged(
                  unit: unit,
                  min: state.quantityMin,
                  max: state.quantityMax,
                  step: state.quantityStep,
                ),
              ),
            ),
          ],
          if (measurement == JournalTrackerMeasurementType.choice) ...[
            SizedBox(height: tokens.spaceMd),
            _ChoiceConfigForm(
              controller: _choiceController,
              choices: state.choiceLabels,
              enabled: !isSaving,
              onAdd: (label) => context.read<JournalTrackerWizardBloc>().add(
                JournalTrackerWizardChoiceAdded(label),
              ),
              onRemove: (index) => context.read<JournalTrackerWizardBloc>().add(
                JournalTrackerWizardChoiceRemoved(index),
              ),
              onUpdate: (index, label) =>
                  context.read<JournalTrackerWizardBloc>().add(
                    JournalTrackerWizardChoiceUpdated(
                      index: index,
                      label: label,
                    ),
                  ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _pickIcon(
    BuildContext context,
    JournalTrackerWizardState state,
  ) async {
    final tokens = TasklyTokens.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLg,
          tokens.spaceSm,
          tokens.spaceLg,
          tokens.spaceLg,
        ),
        child: TasklyFormIconSearchPicker(
          icons: tasklySymbolIcons,
          selectedIconName: state.iconName,
          searchHintText: context.l10n.valueFormIconSearchHint,
          noIconsFoundLabel: context.l10n.valueFormIconNoResults,
          tooltipBuilder: formatIconLabel,
          onSelected: (iconName) => Navigator.of(context).pop(iconName),
        ),
      ),
    );
    if (!context.mounted || selected == null) return;
    context.read<JournalTrackerWizardBloc>().add(
      JournalTrackerWizardIconChanged(selected),
    );
  }

  Future<void> _createGroup(BuildContext context) async {
    final controller = TextEditingController();
    final tokens = TasklyTokens.of(context);
    final created = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLg,
          tokens.spaceSm,
          tokens.spaceLg,
          MediaQuery.viewInsetsOf(sheetContext).bottom + tokens.spaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sheetContext.l10n.journalNewGroupTitle,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            SizedBox(height: tokens.spaceSm),
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) => Navigator.of(sheetContext).pop(value),
            ),
            SizedBox(height: tokens.spaceMd),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(sheetContext).pop(controller.text),
                child: Text(sheetContext.l10n.createLabel),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (!context.mounted || created == null) return;
    context.read<JournalTrackerWizardBloc>().add(
      JournalTrackerWizardCreateGroupRequested(created),
    );
  }

  List<String> _buildActivityIconOptions(JournalTrackerWizardState state) {
    return {
      defaultTrackerIconName(
        trackerName: state.name,
        valueType:
            (state.measurement ?? JournalTrackerMeasurementType.toggle).name,
      ),
      'directions_run',
      'self_improvement',
      'fitness_center',
      'menu_book',
      'code',
      'palette',
    }.toList(growable: false);
  }

  String? _groupNameFor(JournalTrackerWizardState state) {
    for (final group in state.groups) {
      if (group.id == state.groupId) return group.name;
    }
    return null;
  }

  Widget _buildFormBody({
    required BuildContext context,
    required JournalTrackerWizardState state,
    required bool isAggregateKind,
    required bool isSaving,
  }) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);

    Future<void> pickIcon() async {
      await _pickIcon(context, state);
    }

    final showMeasurementSelector =
        widget.mode == JournalTrackerWizardMode.tracker && !isAggregateKind;
    final measurement =
        state.measurement ??
        (isAggregateKind
            ? JournalTrackerMeasurementType.quantity
            : JournalTrackerMeasurementType.toggle);
    final showAggregationSection =
        measurement == JournalTrackerMeasurementType.quantity &&
        isAggregateKind;
    final showQuantitySection =
        measurement == JournalTrackerMeasurementType.quantity;

    if (!showMeasurementSelector && state.measurement == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<JournalTrackerWizardBloc>().add(
          JournalTrackerWizardMeasurementChanged(measurement),
        );
      });
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: _progressBar(active: true),
              ),
              SizedBox(width: tokens.spaceXs),
              Expanded(
                child: _progressBar(active: true),
              ),
              SizedBox(width: tokens.spaceXs),
              Expanded(
                child: _progressBar(active: false),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(tokens.spaceLg),
            children: [
              _fieldLabel(context.l10n.nameLabel),
              SizedBox(height: tokens.spaceXs),
              TextField(
                controller: _nameController,
                enabled: !isSaving,
                decoration: InputDecoration(
                  hintText: context.l10n.journalTrackerNameHint,
                ),
                textInputAction: TextInputAction.next,
                onChanged: (value) =>
                    context.read<JournalTrackerWizardBloc>().add(
                      JournalTrackerWizardNameChanged(value),
                    ),
              ),
              SizedBox(height: tokens.spaceMd),
              InkWell(
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                onTap: isSaving ? null : pickIcon,
                child: Ink(
                  padding: EdgeInsets.all(tokens.spaceMd),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.valueFormIconLabel,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: tokens.spaceXxs),
                            Text(
                              context.l10n.journalTrackerIconSubtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(tokens.radiusSm),
                          border: Border.all(color: theme.colorScheme.primary),
                        ),
                        child: Icon(
                          getIconDataFromName(state.iconName) ??
                              getIconDataFromName(
                                defaultTrackerIconName(
                                  trackerName: state.name,
                                  valueType: measurement.name,
                                ),
                              ) ??
                              Icons.track_changes_outlined,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.mode == JournalTrackerWizardMode.tracker &&
                  state.groups.isNotEmpty &&
                  !isAggregateKind) ...[
                SizedBox(height: tokens.spaceMd),
                DropdownButtonFormField<String>(
                  value: state.groupId,
                  decoration: InputDecoration(
                    labelText: context.l10n.groupLabel,
                  ),
                  items: [
                    for (final group in state.groups)
                      DropdownMenuItem<String>(
                        value: group.id,
                        child: Text(group.name),
                      ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) => context.read<JournalTrackerWizardBloc>().add(
                          JournalTrackerWizardGroupChanged(value),
                        ),
                ),
              ],
              if (showMeasurementSelector) ...[
                SizedBox(height: tokens.spaceLg),
                _fieldLabel(context.l10n.journalMeasurementTitle),
                SizedBox(height: tokens.spaceXs),
                _MeasurementOption(
                  title: context.l10n.journalMeasurementToggleTitle,
                  subtitle: context.l10n.journalMeasurementToggleSubtitle,
                  selected: measurement == JournalTrackerMeasurementType.toggle,
                  onTap: isSaving
                      ? null
                      : () => context.read<JournalTrackerWizardBloc>().add(
                          const JournalTrackerWizardMeasurementChanged(
                            JournalTrackerMeasurementType.toggle,
                          ),
                        ),
                ),
                _MeasurementOption(
                  title: context.l10n.journalMeasurementRatingTitle,
                  subtitle: context.l10n.journalMeasurementRatingSubtitle,
                  selected: measurement == JournalTrackerMeasurementType.rating,
                  onTap: isSaving
                      ? null
                      : () => context.read<JournalTrackerWizardBloc>().add(
                          const JournalTrackerWizardMeasurementChanged(
                            JournalTrackerMeasurementType.rating,
                          ),
                        ),
                ),
                _MeasurementOption(
                  title: context.l10n.journalMeasurementQuantityTitle,
                  subtitle:
                      context.l10n.journalMeasurementQuantityEntrySubtitle,
                  selected:
                      measurement == JournalTrackerMeasurementType.quantity,
                  onTap: isSaving
                      ? null
                      : () => context.read<JournalTrackerWizardBloc>().add(
                          const JournalTrackerWizardMeasurementChanged(
                            JournalTrackerMeasurementType.quantity,
                          ),
                        ),
                ),
                _MeasurementOption(
                  title: context.l10n.journalMeasurementChoiceTitle,
                  subtitle: context.l10n.journalMeasurementChoiceSubtitle,
                  selected: measurement == JournalTrackerMeasurementType.choice,
                  onTap: isSaving
                      ? null
                      : () => context.read<JournalTrackerWizardBloc>().add(
                          const JournalTrackerWizardMeasurementChanged(
                            JournalTrackerMeasurementType.choice,
                          ),
                        ),
                ),
              ],
              if (showAggregationSection) ...[
                SizedBox(height: tokens.spaceLg),
                _fieldLabel(context.l10n.journalTrackerAggregationTypeLabel),
                SizedBox(height: tokens.spaceXs),
                _AggregationSelector(
                  value: state.aggregationKind,
                  enabled: !isSaving,
                  onChanged: (value) =>
                      context.read<JournalTrackerWizardBloc>().add(
                        JournalTrackerWizardAggregationKindChanged(value),
                      ),
                ),
                SizedBox(height: tokens.spaceXs),
                Text(
                  state.aggregationKind == 'avg'
                      ? context.l10n.journalAggregationAverageHelper
                      : context.l10n.journalAggregationSumHelper,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (measurement == JournalTrackerMeasurementType.rating) ...[
                SizedBox(height: tokens.spaceLg),
                _RatingConfigForm(
                  min: state.ratingMin,
                  max: state.ratingMax,
                  step: state.ratingStep,
                  enabled: !isSaving,
                  onChanged: (min, max, step) =>
                      context.read<JournalTrackerWizardBloc>().add(
                        JournalTrackerWizardRatingConfigChanged(
                          min: min,
                          max: max,
                          step: step,
                        ),
                      ),
                ),
              ],
              if (showQuantitySection) ...[
                SizedBox(height: tokens.spaceLg),
                _fieldLabel(context.l10n.journalUnitLabel),
                SizedBox(height: tokens.spaceXs),
                _QuantityUnitField(
                  unit: state.quantityUnit,
                  enabled: !isSaving,
                  onChanged: (unit) =>
                      context.read<JournalTrackerWizardBloc>().add(
                        JournalTrackerWizardQuantityConfigChanged(
                          unit: unit,
                          min: state.quantityMin,
                          max: state.quantityMax,
                          step: state.quantityStep,
                        ),
                      ),
                ),
                SizedBox(height: tokens.spaceMd),
                _DailyGoalStepper(
                  goal: state.quantityGoal ?? 3,
                  unit: state.quantityUnit,
                  enabled: !isSaving,
                  onChanged: (nextGoal) =>
                      context.read<JournalTrackerWizardBloc>().add(
                        JournalTrackerWizardQuantityGoalChanged(nextGoal),
                      ),
                ),
                SizedBox(height: tokens.spaceLg),
                _TrackerConfigurePreview(
                  trackerName: state.name,
                  iconName: state.iconName,
                  measurement: measurement,
                  groupName: _groupNameFor(state),
                  unit: state.quantityUnit,
                  aggregationKind: state.aggregationKind,
                  quantityGoal: state.quantityGoal,
                  isAggregate: isAggregateKind,
                ),
              ],
              if (measurement == JournalTrackerMeasurementType.choice) ...[
                SizedBox(height: tokens.spaceLg),
                _ChoiceConfigForm(
                  controller: _choiceController,
                  choices: state.choiceLabels,
                  enabled: !isSaving,
                  onAdd: (label) =>
                      context.read<JournalTrackerWizardBloc>().add(
                        JournalTrackerWizardChoiceAdded(label),
                      ),
                  onRemove: (index) =>
                      context.read<JournalTrackerWizardBloc>().add(
                        JournalTrackerWizardChoiceRemoved(index),
                      ),
                  onUpdate: (index, label) =>
                      context.read<JournalTrackerWizardBloc>().add(
                        JournalTrackerWizardChoiceUpdated(
                          index: index,
                          label: label,
                        ),
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _progressBar({required bool active}) {
    final theme = Theme.of(context);
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ActivityIconTile extends StatelessWidget {
  const _ActivityIconTile({
    required this.iconName,
    required this.selected,
    required this.onTap,
    this.customChild,
  });

  final String iconName;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? customChild;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: Ink(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child:
            customChild ??
            Icon(
              getIconDataFromName(iconName) ?? Icons.track_changes_outlined,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _ActivityGroupGrid extends StatelessWidget {
  const _ActivityGroupGrid({
    required this.groups,
    required this.selectedGroupId,
    required this.onSelected,
    required this.onCreateGroup,
  });

  final List<TrackerGroup> groups;
  final String? selectedGroupId;
  final ValueChanged<String>? onSelected;
  final VoidCallback? onCreateGroup;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: tokens.spaceSm,
      mainAxisSpacing: tokens.spaceSm,
      childAspectRatio: 1.55,
      children: [
        for (final group in groups)
          _ActivityGroupCard(
            group: group,
            selected: selectedGroupId == group.id,
            onTap: onSelected == null ? null : () => onSelected!(group.id),
          ),
        OutlinedButton(
          onPressed: onCreateGroup,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(height: tokens.spaceXxs),
              Text(
                context.l10n.journalNewGroupTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityGroupCard extends StatelessWidget {
  const _ActivityGroupCard({
    required this.group,
    required this.selected,
    required this.onTap,
  });

  final TrackerGroup group;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final palette = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.error,
    ];
    final accent = palette[group.name.hashCode.abs() % palette.length];
    final icon = _groupIconForName(group.name);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: Ink(
        padding: EdgeInsets.all(tokens.spaceMd),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(tokens.radiusSm),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: Text(
                group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackerConfigurePreview extends StatelessWidget {
  const _TrackerConfigurePreview({
    required this.trackerName,
    required this.iconName,
    required this.measurement,
    required this.groupName,
    required this.unit,
    required this.aggregationKind,
    required this.quantityGoal,
    required this.isAggregate,
  });

  final String trackerName;
  final String? iconName;
  final JournalTrackerMeasurementType measurement;
  final String? groupName;
  final String unit;
  final String aggregationKind;
  final int? quantityGoal;
  final bool isAggregate;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final name = trackerName.trim().isEmpty
        ? context.l10n.journalTrackerFallbackName
        : trackerName.trim();
    final icon =
        getIconDataFromName(iconName) ??
        getIconDataFromName(
          defaultTrackerIconName(
            trackerName: name,
            valueType: measurement.name,
          ),
        ) ??
        Icons.track_changes_outlined;
    final meta = _measurementMeta(context);

    return Container(
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.previewLabel.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spaceSm),
          Row(
            children: [
              Expanded(
                child: _PreviewSurface(
                  title: context.l10n.journalQuickCaptureLabel,
                  child: Wrap(
                    spacing: tokens.spaceXs,
                    runSpacing: tokens.spaceXs,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceSm,
                          vertical: tokens.spaceXs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(
                            tokens.radiusPill,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: tokens.spaceXxs),
                            Text(
                              name,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((groupName ?? '').trim().isNotEmpty)
                        Text(
                          groupName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: _PreviewSurface(
                  title: isAggregate
                      ? context.l10n.journalDailySummaryTitle
                      : context.l10n.journalMomentsTitle,
                  child: Container(
                    padding: EdgeInsets.all(tokens.spaceSm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              icon,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: tokens.spaceXxs),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: tokens.spaceXs),
                        Text(
                          meta,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (quantityGoal != null) ...[
                          SizedBox(height: tokens.spaceXs),
                          Text(
                            '${context.l10n.journalDailyGoalOptionalLabel}: ${quantityGoal!}${unit.trim().isEmpty ? '' : ' ${unit.trim()}'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _measurementMeta(BuildContext context) {
    return switch (measurement) {
      JournalTrackerMeasurementType.toggle =>
        context.l10n.journalMeasurementToggleTitle,
      JournalTrackerMeasurementType.rating =>
        context.l10n.journalMeasurementRatingTitle,
      JournalTrackerMeasurementType.choice =>
        context.l10n.journalMeasurementChoiceTitle,
      JournalTrackerMeasurementType.quantity =>
        '${aggregationKind == 'avg' ? context.l10n.journalTrackerAggregationAverageLabel : context.l10n.journalTrackerAggregationSumLabel}${unit.trim().isEmpty ? '' : ' - ${unit.trim()}'}',
    };
  }
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceXs),
        child,
      ],
    );
  }
}

class _AdvancedDisclosure extends StatelessWidget {
  const _AdvancedDisclosure({
    required this.title,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusSm),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
        child: Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Icon(
              expanded ? Icons.expand_less : Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

IconData _groupIconForName(String name) {
  final normalized = name.trim().toLowerCase();
  if (normalized.contains('sport')) return Icons.sports_soccer;
  if (normalized.contains('health')) return Icons.favorite;
  if (normalized.contains('social')) return Icons.groups;
  if (normalized.contains('work')) return Icons.work;
  if (normalized.contains('hobby')) return Icons.palette;
  return Icons.folder;
}

class _MeasurementOption extends StatelessWidget {
  const _MeasurementOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceXs),
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.all(tokens.spaceMd),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: tokens.spaceXxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AggregationSelector extends StatelessWidget {
  const _AggregationSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment<String>(
          value: 'sum',
          icon: const Icon(Icons.functions, size: 18),
          label: Text(context.l10n.journalTrackerAggregationSumLabel),
        ),
        ButtonSegment<String>(
          value: 'avg',
          icon: const Icon(Icons.bar_chart, size: 18),
          label: Text(context.l10n.journalTrackerAggregationAverageLabel),
        ),
      ],
      selected: <String>{value},
      onSelectionChanged: enabled
          ? (selected) {
              if (selected.isEmpty) return;
              onChanged(selected.first);
            }
          : null,
    );
  }
}

class _QuantityUnitField extends StatelessWidget {
  const _QuantityUnitField({
    required this.unit,
    required this.enabled,
    required this.onChanged,
  });

  final String unit;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<JournalUnitOption>>{};
    for (final option in journalUnitCatalog) {
      (grouped[option.category] ??= <JournalUnitOption>[]).add(option);
    }
    return DropdownButtonFormField<String>(
      value: unit.trim().isEmpty ? null : unit.trim().toLowerCase(),
      decoration: InputDecoration(
        hintText: context.l10n.journalUnitOptionalLabel,
      ),
      items: [
        for (final entry in grouped.entries) ...[
          DropdownMenuItem<String>(
            enabled: false,
            value: '__${entry.key}',
            child: Text(entry.key),
          ),
          for (final option in entry.value)
            DropdownMenuItem<String>(
              value: option.key,
              child: Text(option.label),
            ),
        ],
      ],
      onChanged: enabled
          ? (value) {
              if (value == null || value.startsWith('__')) return;
              onChanged(value);
            }
          : null,
    );
  }
}

class _DailyGoalStepper extends StatelessWidget {
  const _DailyGoalStepper({
    required this.goal,
    required this.unit,
    required this.enabled,
    required this.onChanged,
  });

  final int goal;
  final String unit;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final unitLabel = unit.trim().isEmpty ? '' : '${unit.trim()}/day';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.journalDailyGoalOptionalLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (unitLabel.isNotEmpty)
              Text(
                unitLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        SizedBox(height: tokens.spaceXs),
        Container(
          padding: EdgeInsets.all(tokens.spaceXs),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: enabled
                    ? () => onChanged((goal - 1).clamp(0, 99999))
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text(
                  '$goal',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: enabled
                    ? () => onChanged((goal + 1).clamp(0, 99999))
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RatingConfigForm extends StatelessWidget {
  const _RatingConfigForm({
    required this.min,
    required this.max,
    required this.step,
    required this.enabled,
    required this.onChanged,
  });

  final int min;
  final int max;
  final int step;
  final bool enabled;
  final void Function(int min, int max, int step) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NumberField(
          label: context.l10n.minLabel,
          value: min,
          enabled: enabled,
          onChanged: (value) => onChanged(value ?? min, max, step),
        ),
        _NumberField(
          label: context.l10n.maxLabel,
          value: max,
          enabled: enabled,
          onChanged: (value) => onChanged(min, value ?? max, step),
        ),
        _NumberField(
          label: context.l10n.stepLabel,
          value: step,
          enabled: enabled,
          onChanged: (value) => onChanged(min, max, value ?? step),
        ),
      ],
    );
  }
}

class _ChoiceConfigForm extends StatelessWidget {
  const _ChoiceConfigForm({
    required this.controller,
    required this.choices,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
  });

  final TextEditingController controller;
  final List<String> choices;
  final bool enabled;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int index, String label) onUpdate;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                decoration: InputDecoration(
                  labelText: context.l10n.journalOptionLabel,
                  hintText: context.l10n.journalOptionHint,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  onAdd(value);
                  controller.clear();
                },
              ),
            ),
            SizedBox(width: tokens.spaceSm),
            FilledButton(
              onPressed: enabled
                  ? () {
                      onAdd(controller.text);
                      controller.clear();
                    }
                  : null,
              child: Text(context.l10n.addLabel),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        if (choices.isEmpty)
          Text(
            context.l10n.journalAddOptionHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (var i = 0; i < choices.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceXs),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: choices[i],
                      enabled: enabled,
                      decoration: InputDecoration(
                        labelText: context.l10n.labelLabel,
                      ),
                      onChanged: (value) => onUpdate(i, value),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.removeLabel,
                    onPressed: enabled ? () => onRemove(i) : null,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SyncedTextField(
      value: value == null ? '' : value.toString(),
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (value) => onChanged(int.tryParse(value)),
    );
  }
}

class _SyncedTextField extends StatefulWidget {
  const _SyncedTextField({
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.decoration,
    this.keyboardType,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;

  @override
  State<_SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<_SyncedTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant _SyncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _controller.text) return;
    _controller.value = _controller.value.copyWith(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
      composing: TextRange.empty,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      decoration: widget.decoration,
      onChanged: widget.onChanged,
    );
  }
}
