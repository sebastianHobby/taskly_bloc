import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/mood_rating.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/presentation/blocs/journal_entry/journal_entry_bloc.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
      ),
      body: BlocBuilder<JournalEntryBloc, JournalEntryState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text('Select a date')),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (entry) => _buildEntryForm(context, entry),
            saved: () => const Center(child: Text('Saved!')),
            error: (message) => Center(child: Text('Error: $message')),
          );
        },
      ),
    );
  }

  Widget _buildEntryForm(BuildContext context, dynamic entry) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you feeling?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildMoodSelector(context),
          const SizedBox(height: 24),
          const Text(
            'Journal Entry',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Write your thoughts...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: MoodRating.values.map((rating) {
        return GestureDetector(
          onTap: () {
            // TODO: Update entry with selected mood
          },
          child: Column(
            children: [
              Text(rating.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 4),
              Text(rating.label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
