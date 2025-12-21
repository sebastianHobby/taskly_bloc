import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/values/bloc/value_list_bloc.dart';
import 'package:taskly_bloc/features/values/widgets/add_value_fab.dart';
import 'package:taskly_bloc/features/values/widgets/values_list.dart';

class ValueOverviewPage extends StatelessWidget {
  const ValueOverviewPage({required this.valueRepository, super.key});

  final ValueRepositoryContract valueRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ValueOverviewBloc(valueRepository: valueRepository)
            ..add(const ValueOverviewEvent.valuesSubscriptionRequested()),
      child: ValueOverviewView(valueRepository: valueRepository),
    );
  }
}

class ValueOverviewView extends StatefulWidget {
  const ValueOverviewView({required this.valueRepository, super.key});

  final ValueRepositoryContract valueRepository;

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ValueOverviewBloc, ValueOverviewState>(
      builder: (context, state) {
        return state.when(
          initial: () => const Center(child: CircularProgressIndicator()),
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (values) => Scaffold(
            appBar: AppBar(title: Text(context.l10n.valuesTitle)),
            body: ValuesListView(
              values: values,
              valueRepository: widget.valueRepository,
              isSheetOpen: _isSheetOpen,
            ),
            floatingActionButton: AddValueFab(
              valueRepository: widget.valueRepository,
              isSheetOpen: _isSheetOpen,
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
