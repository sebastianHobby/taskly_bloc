import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/navigation/bloc/screen_order_bloc.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';

const _iconResolver = NavigationIconResolver();

class NavigationSettingsPage extends StatelessWidget {
  const NavigationSettingsPage({required this.screensRepository, super.key});

  final ScreenDefinitionsRepositoryContract screensRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ScreenOrderBloc(screensRepository: screensRepository)
            ..add(const ScreenOrderStarted()),
      child: const _NavigationSettingsView(),
    );
  }
}

class _NavigationSettingsView extends StatelessWidget {
  const _NavigationSettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation order'),
      ),
      body: BlocBuilder<ScreenOrderBloc, ScreenOrderState>(
        builder: (context, state) {
          return switch (state.status) {
            ScreenOrderStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            ScreenOrderStatus.failure => _ErrorState(message: state.error),
            ScreenOrderStatus.ready => _ReadyState(
              screens: state.screens,
              onReorder: (oldIndex, newIndex) =>
                  context.read<ScreenOrderBloc>().add(
                    ScreenOrderReordered(
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                    ),
                  ),
            ),
          };
        },
      ),
    );
  }
}

class _ReadyState extends StatelessWidget {
  const _ReadyState({required this.screens, required this.onReorder});

  final List<ScreenDefinition> screens;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _NavigationHint(),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: screens.length,
            onReorder: onReorder,
            itemBuilder: (context, index) {
              final screen = screens[index];
              final iconSet = _iconResolver.resolve(
                screenId: screen.screenId,
                iconName: screen.iconName,
              );
              return ListTile(
                key: ValueKey(screen.id),
                leading: Icon(iconSet.icon),
                title: Text(screen.name),
                subtitle: screen.isSystem
                    ? const Text('System screen (cannot be deleted)')
                    : null,
                trailing: const Icon(Icons.drag_handle),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NavigationHint extends StatelessWidget {
  const _NavigationHint();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reorder screens',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'This order is used for both mobile (first 4 in the bottom bar, '
            'rest in More) and large screens (all in the side rail).',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message ?? 'Failed to load navigation settings'),
    );
  }
}
