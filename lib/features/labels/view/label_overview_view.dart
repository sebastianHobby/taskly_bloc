import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/labels/bloc/label_list_bloc.dart';
import 'package:taskly_bloc/features/labels/widgets/add_label_fab.dart';
import 'package:taskly_bloc/features/labels/widgets/labels_list.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/shared/widgets/sort_bottom_sheet.dart';
import 'package:taskly_bloc/features/settings/settings.dart';

class LabelOverviewPage extends StatelessWidget {
  const LabelOverviewPage({required this.labelRepository, super.key});

  final LabelRepositoryContract labelRepository;

  @override
  Widget build(BuildContext context) {
    const defaultSort = SortPreferences(
      criteria: [SortCriterion(field: SortField.name)],
    );

    final settingsState = context.read<SettingsBloc>().state;
    final savedSort = settingsState.settings?.sortFor(SettingsPageKey.labels);
    final initialSort = savedSort ?? defaultSort;

    return BlocProvider(
      create: (_) => LabelOverviewBloc(
        labelRepository: labelRepository,
        typeFilter: LabelType.label,
        initialSortPreferences: initialSort,
      )..add(const LabelOverviewEvent.subscriptionRequested()),
      child: LabelOverviewView(labelRepository: labelRepository),
    );
  }
}

class LabelOverviewView extends StatefulWidget {
  const LabelOverviewView({required this.labelRepository, super.key});

  final LabelRepositoryContract labelRepository;

  @override
  State<LabelOverviewView> createState() => _LabelOverviewViewState();
}

class _LabelOverviewViewState extends State<LabelOverviewView> {
  late final ValueNotifier<bool> _isSheetOpen;
  @override
  void initState() {
    super.initState();
    _isSheetOpen = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isSheetOpen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) {
        final previousSort = previous.settings?.sortFor(SettingsPageKey.labels);
        final currentSort = current.settings?.sortFor(SettingsPageKey.labels);
        return previousSort != currentSort;
      },
      listener: (context, state) {
        final preferences = state.settings?.sortFor(SettingsPageKey.labels);
        if (preferences == null) return;

        final bloc = context.read<LabelOverviewBloc>();
        if (bloc.currentSortPreferences != preferences) {
          bloc.add(
            LabelOverviewEvent.sortChanged(preferences: preferences),
          );
        }
      },
      child: BlocBuilder<LabelOverviewBloc, LabelOverviewState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (labels) => Scaffold(
              appBar: AppBar(
                title: Text(context.l10n.labelsTitle),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.sort),
                    tooltip: context.l10n.sortMenuTitle,
                    onPressed: () async {
                      final bloc = context.read<LabelOverviewBloc>();
                      final current = bloc.currentSortPreferences;
                      await showSortBottomSheet(
                        context: context,
                        current: current,
                        availableSortFields: const [SortField.name],
                        onChanged: (updated) {
                          bloc.add(
                            LabelOverviewEvent.sortChanged(
                              preferences: updated,
                            ),
                          );
                          context.read<SettingsBloc>().add(
                            SettingsUpdatePageSort(
                              pageKey: SettingsPageKey.labels,
                              preferences: updated,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              body: labels.isEmpty
                  ? Center(child: Text(context.l10n.noLabelsFound))
                  : LabelsListView(
                      labels: labels,
                      isSheetOpen: _isSheetOpen,
                    ),
              floatingActionButton: AddLabelFab(
                labelRepository: widget.labelRepository,
                initialType: LabelType.label,
                lockType: true,
                tooltip: context.l10n.createLabelTooltip,
                heroTag: 'create_label_fab',
              ),
            ),
            error: (error) => Center(
              child: Text(
                friendlyErrorMessageForUi(error, context.l10n),
              ),
            ),
          );
        },
      ),
    );
  }
}
