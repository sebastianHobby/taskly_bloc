import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/labels/bloc/label_list_bloc.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/add_label_fab.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/labels_list.dart';
import 'package:taskly_bloc/presentation/widgets/sort_bottom_sheet.dart';

class LabelOverviewPage extends StatelessWidget {
  const LabelOverviewPage({
    required this.labelRepository,
    required this.settingsRepository,
    required this.pageKey,
    super.key,
  });

  final LabelRepositoryContract labelRepository;
  final SettingsRepositoryContract settingsRepository;
  final PageKey pageKey;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LabelOverviewBloc(
        labelRepository: labelRepository,
        settingsRepository: settingsRepository,
        pageKey: pageKey,
        typeFilter: LabelType.label,
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
    return BlocBuilder<LabelOverviewBloc, LabelOverviewState>(
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
    );
  }
}
