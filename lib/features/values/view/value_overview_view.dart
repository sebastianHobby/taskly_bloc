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

class ValueOverviewView extends StatelessWidget {
  const ValueOverviewView({required this.valueRepository, super.key});

  final ValueRepository valueRepository;

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
              valueRepository: valueRepository,
            ),
            floatingActionButton: AddValueFab(valueRepository: valueRepository),
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
