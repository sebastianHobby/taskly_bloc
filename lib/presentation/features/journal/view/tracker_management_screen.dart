import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/domain/journal/model/tracker.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_response_config.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/tracker_management/tracker_management_bloc.dart';
import 'package:taskly_bloc/presentation/widgets/content_constraint.dart';

class TrackerManagementScreen extends StatelessWidget {
  const TrackerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Trackers'),
      ),
      body: BlocConsumer<TrackerManagementBloc, TrackerManagementState>(
        listener: (context, state) {
          state.whenOrNull(
            saved: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tracker saved!')),
              );
              context.read<TrackerManagementBloc>().add(
                const TrackerManagementEvent.loadTrackers(),
              );
            },
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $message')),
              );
            },
          );
        },
        builder: (context, state) {
          return state.when(
            initial: () {
              // Trigger load on first build
              context.read<TrackerManagementBloc>().add(
                const TrackerManagementEvent.loadTrackers(),
              );
              return const Center(child: CircularProgressIndicator());
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (trackers) => _buildTrackerList(context, trackers),
            saved: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TrackerManagementBloc>().add(
                        const TrackerManagementEvent.loadTrackers(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTrackerDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Tracker'),
      ),
    );
  }

  Widget _buildTrackerList(BuildContext context, List<Tracker> trackers) {
    if (trackers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No trackers yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add trackers to monitor your daily habits',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ResponsiveBody(
      child: ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: trackers.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex--;
          final reorderedIds = List<String>.from(trackers.map((t) => t.id));
          final movedId = reorderedIds.removeAt(oldIndex);
          reorderedIds.insert(newIndex, movedId);
          context.read<TrackerManagementBloc>().add(
            TrackerManagementEvent.reorderTrackers(reorderedIds),
          );
        },
        itemBuilder: (context, index) {
          final tracker = trackers[index];
          return Card(
            key: ValueKey(tracker.id),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(_getTrackerIcon(tracker.responseType)),
              title: Text(tracker.name),
              subtitle: tracker.description != null
                  ? Text(
                      tracker.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(_getTrackerTypeLabel(tracker.responseType)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showTrackerDialog(context, tracker),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(context, tracker),
                  ),
                  const Icon(Icons.drag_handle),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getTrackerIcon(TrackerResponseType type) {
    return switch (type) {
      TrackerResponseType.yesNo => Icons.check_circle_outline,
      TrackerResponseType.scale => Icons.linear_scale,
      TrackerResponseType.choice => Icons.list,
    };
  }

  String _getTrackerTypeLabel(TrackerResponseType type) {
    return switch (type) {
      TrackerResponseType.yesNo => 'Yes/No',
      TrackerResponseType.scale => 'Scale',
      TrackerResponseType.choice => 'Multiple Choice',
    };
  }

  void _confirmDelete(BuildContext context, Tracker tracker) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Tracker'),
        content: Text('Are you sure you want to delete "${tracker.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<TrackerManagementBloc>().add(
                TrackerManagementEvent.deleteTracker(tracker.id),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTrackerDialog(BuildContext context, Tracker? tracker) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _TrackerFormDialog(
        tracker: tracker,
        onSave: (newTracker) {
          context.read<TrackerManagementBloc>().add(
            TrackerManagementEvent.saveTracker(newTracker),
          );
        },
      ),
    );
  }
}

class _TrackerFormDialog extends StatefulWidget {
  const _TrackerFormDialog({
    required this.onSave,
    this.tracker,
  });

  final Tracker? tracker;
  final ValueChanged<Tracker> onSave;

  @override
  State<_TrackerFormDialog> createState() => _TrackerFormDialogState();
}

class _TrackerFormDialogState extends State<_TrackerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TrackerResponseType _responseType;
  late TrackerEntryScope _entryScope;

  // Scale config
  int _scaleMin = 1;
  int _scaleMax = 5;
  String? _scaleMinLabel;
  String? _scaleMaxLabel;

  // Choice config
  final List<String> _choiceOptions = [];
  final TextEditingController _choiceController = TextEditingController();

  bool get isEditing => widget.tracker != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tracker?.name);
    _descriptionController = TextEditingController(
      text: widget.tracker?.description,
    );
    _responseType = widget.tracker?.responseType ?? TrackerResponseType.yesNo;
    _entryScope = widget.tracker?.entryScope ?? TrackerEntryScope.allDay;

    // Initialize config from existing tracker
    widget.tracker?.config.map(
      yesNo: (_) {},
      scale: (config) {
        _scaleMin = config.min;
        _scaleMax = config.max;
        _scaleMinLabel = config.minLabel;
        _scaleMaxLabel = config.maxLabel;
      },
      choice: (config) {
        _choiceOptions.addAll(config.options);
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _choiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Tracker' : 'New Tracker'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Exercise, Sleep Quality',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description of what to track',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TrackerResponseType>(
                initialValue: _responseType,
                decoration: const InputDecoration(
                  labelText: 'Response Type',
                ),
                items: TrackerResponseType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _responseType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TrackerEntryScope>(
                initialValue: _entryScope,
                decoration: const InputDecoration(
                  labelText: 'Entry Scope',
                ),
                items: const [
                  DropdownMenuItem(
                    value: TrackerEntryScope.allDay,
                    child: Text('Once per day'),
                  ),
                  DropdownMenuItem(
                    value: TrackerEntryScope.perEntry,
                    child: Text('Per journal entry'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _entryScope = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildConfigSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveTracker,
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Widget _buildConfigSection() {
    return switch (_responseType) {
      TrackerResponseType.yesNo => const SizedBox.shrink(),
      TrackerResponseType.scale => _buildScaleConfig(),
      TrackerResponseType.choice => _buildChoiceConfig(),
    };
  }

  Widget _buildScaleConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scale Configuration',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _scaleMin.toString(),
                decoration: const InputDecoration(
                  labelText: 'Min',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _scaleMin = int.tryParse(value) ?? 1;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _scaleMax.toString(),
                decoration: const InputDecoration(
                  labelText: 'Max',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _scaleMax = int.tryParse(value) ?? 5;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _scaleMinLabel,
          decoration: const InputDecoration(
            labelText: 'Min Label (optional)',
            hintText: 'e.g., Poor',
          ),
          onChanged: (value) {
            _scaleMinLabel = value.isEmpty ? null : value;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _scaleMaxLabel,
          decoration: const InputDecoration(
            labelText: 'Max Label (optional)',
            hintText: 'e.g., Excellent',
          ),
          onChanged: (value) {
            _scaleMaxLabel = value.isEmpty ? null : value;
          },
        ),
      ],
    );
  }

  Widget _buildChoiceConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choice Options',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _choiceController,
                decoration: const InputDecoration(
                  labelText: 'Add Option',
                  hintText: 'Enter option text',
                ),
                onFieldSubmitted: (_) => _addChoiceOption(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addChoiceOption,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_choiceOptions.isEmpty)
          Text(
            'Add at least one option',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _choiceOptions.map((option) {
              return Chip(
                label: Text(option),
                onDeleted: () {
                  setState(() {
                    _choiceOptions.remove(option);
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  void _addChoiceOption() {
    final option = _choiceController.text.trim();
    if (option.isNotEmpty && !_choiceOptions.contains(option)) {
      setState(() {
        _choiceOptions.add(option);
        _choiceController.clear();
      });
    }
  }

  String _getTypeLabel(TrackerResponseType type) {
    return switch (type) {
      TrackerResponseType.yesNo => 'Yes/No',
      TrackerResponseType.scale => 'Scale (1-10)',
      TrackerResponseType.choice => 'Multiple Choice',
    };
  }

  void _saveTracker() {
    if (!_formKey.currentState!.validate()) return;

    // Validate choice options
    if (_responseType == TrackerResponseType.choice && _choiceOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one option')),
      );
      return;
    }

    final config = switch (_responseType) {
      TrackerResponseType.yesNo => const TrackerResponseConfig.yesNo(),
      TrackerResponseType.scale => TrackerResponseConfig.scale(
        min: _scaleMin,
        max: _scaleMax,
        minLabel: _scaleMinLabel,
        maxLabel: _scaleMaxLabel,
      ),
      TrackerResponseType.choice => TrackerResponseConfig.choice(
        options: List.from(_choiceOptions),
      ),
    };

    final now = DateTime.now();
    final tracker = Tracker(
      id: widget.tracker?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      responseType: _responseType,
      config: config,
      entryScope: _entryScope,
      sortOrder: widget.tracker?.sortOrder ?? 0,
      createdAt: widget.tracker?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(tracker);
    Navigator.pop(context);
  }
}
