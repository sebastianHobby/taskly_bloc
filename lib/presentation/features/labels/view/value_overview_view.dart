import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/labels/bloc/label_list_bloc.dart';
import 'package:taskly_bloc/presentation/features/labels/view/label_detail_view.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/add_label_fab.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/label_list_tile.dart';
import 'package:taskly_bloc/presentation/widgets/sort_bottom_sheet.dart';

class ValueOverviewPage extends StatelessWidget {
  const ValueOverviewPage({
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
        typeFilter: LabelType.value,
        settingsRepository: settingsRepository,
        pageKey: pageKey,
      )..add(const LabelOverviewEvent.subscriptionRequested()),
      child: ValueOverviewView(labelRepository: labelRepository),
    );
  }
}

class ValueOverviewView extends StatefulWidget {
  const ValueOverviewView({required this.labelRepository, super.key});

  final LabelRepositoryContract labelRepository;

  @override
  State<ValueOverviewView> createState() => _ValueOverviewViewState();
}

class _ValueOverviewViewState extends State<ValueOverviewView> {
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

  Future<void> _showValueDetailSheet(
    BuildContext context, {
    String? valueId,
  }) async {
    _isSheetOpen.value = true;

    await showDetailModal<void>(
      context: context,
      childBuilder: (modalSheetContext) => SafeArea(
        top: false,
        child: LabelDetailSheetPage(
          labelId: valueId,
          labelRepository: widget.labelRepository,
          initialType: LabelType.value,
          lockType: true,
        ),
      ),
      showDragHandle: true,
    );

    _isSheetOpen.value = false;
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
              title: Text(context.l10n.labelTypeValueHeading),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sort),
                  tooltip: context.l10n.sortMenuTitle,
                  onPressed: () async {
                    final bloc = context.read<LabelOverviewBloc>();
                    await showSortBottomSheet(
                      context: context,
                      current: bloc.currentSortPreferences,
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
                ? Center(child: Text(context.l10n.noValuesFound))
                : ListView(
                    children: [
                      for (final label in labels)
                        LabelListTile(
                          label: label,
                          onTap: (label) => unawaited(
                            _showValueDetailSheet(
                              context,
                              valueId: label.id,
                            ),
                          ),
                        ),
                    ],
                  ),
            floatingActionButton: AddLabelFab(
              labelRepository: widget.labelRepository,
              initialType: LabelType.value,
              lockType: true,
              tooltip: context.l10n.createValueOption,
              heroTag: 'create_value_fab',
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
