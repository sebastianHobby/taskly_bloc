import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/labels/bloc/label_list_bloc.dart';
import 'package:taskly_bloc/features/labels/view/label_detail_view.dart';
import 'package:taskly_bloc/features/labels/widgets/add_label_fab.dart';
import 'package:taskly_bloc/features/labels/widgets/label_list_tile.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/shared/widgets/sort_bottom_sheet.dart';
import 'package:taskly_bloc/features/settings/settings.dart';

class ValueOverviewPage extends StatelessWidget {
  const ValueOverviewPage({required this.labelRepository, super.key});

  final LabelRepositoryContract labelRepository;

  @override
  Widget build(BuildContext context) {
    const defaultSort = SortPreferences(
      criteria: [SortCriterion(field: SortField.name)],
    );

    final settingsState = context.read<SettingsBloc>().state;
    final savedSort = settingsState.settings?.sortFor(SettingsPageKey.values);
    final initialSort = savedSort ?? defaultSort;

    return BlocProvider(
      create: (_) => LabelOverviewBloc(
        labelRepository: labelRepository,
        typeFilter: LabelType.value,
        initialSortPreferences: initialSort,
      )..add(const LabelOverviewEvent.labelsSubscriptionRequested()),
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
          onSuccess: (message) {
            Navigator.of(modalSheetContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          onError: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
        ),
      ),
      showDragHandle: true,
    );

    _isSheetOpen.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) {
        final previousSort = previous.settings?.sortFor(SettingsPageKey.values);
        final currentSort = current.settings?.sortFor(SettingsPageKey.values);
        return previousSort != currentSort;
      },
      listener: (context, state) {
        final preferences = state.settings?.sortFor(SettingsPageKey.values);
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
                          context.read<SettingsBloc>().add(
                            SettingsUpdatePageSort(
                              pageKey: SettingsPageKey.values,
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
                isSheetOpen: _isSheetOpen,
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
      ),
    );
  }
}
