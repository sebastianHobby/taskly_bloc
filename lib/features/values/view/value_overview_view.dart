import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/features/values/bloc/value_list_bloc.dart';
import 'package:taskly_bloc/features/values/widgets/add_value_fab.dart';
import 'package:taskly_bloc/features/values/widgets/values_list.dart';

class ValueOverviewPage extends StatelessWidget {
  const ValueOverviewPage({required this.valueRepository, super.key});

  final ValueRepository valueRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ValueOverviewBloc(valueRepository: valueRepository),
      child: ValueOverviewView(valueRepository: valueRepository),
    );
  }
}

class ValueOverviewView extends StatefulWidget {
  const ValueOverviewView({required this.valueRepository, super.key});

  final ValueRepository valueRepository;

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
        if (state is ValueOverviewInitial) {
          context.read<ValueOverviewBloc>().add(ValuesSubscriptionRequested());
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ValueOverviewLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ValueOverviewLoaded) {
          return Scaffold(
            appBar: AppBar(title: const Text('Values')),
            body: ValuesListView(
              values: state.values,
              valueRepository: widget.valueRepository,
              isSheetOpen: _isSheetOpen,
            ),
            floatingActionButton: AddValueFab(
              valueRepository: widget.valueRepository,
              isSheetOpen: _isSheetOpen,
            ),
          );
        }

        if (state is ValueOverviewError) {
          return Center(child: Text(state.message));
        }

        return const SizedBox.shrink();
      },
    );
  }
}
