import 'package:flutter/material.dart';

class SafetyNetRulesPage extends StatelessWidget {
  const SafetyNetRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Safety Net Rules'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Safety net rules ensure that important tasks don't fall through the cracks when they aren't allocated to your day.",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(context, 'Active Rules'),
                _buildRuleTile(
                  context,
                  'Urgent Tasks',
                  'Warn me when tasks are due within 3 days',
                  true,
                ),
                _buildRuleTile(
                  context,
                  'Neglected Values',
                  'Warn me when "Health" hasn\'t been prioritized for 7 days',
                  true,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(context, 'Suggestions'),
                _buildRuleTile(
                  context,
                  'Stale Projects',
                  'Warn me when a project has no activity for 14 days',
                  false,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  // Save and Navigate to My Day
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Save & Continue to My Day'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRuleTile(
    BuildContext context,
    String title,
    String subtitle,
    bool isActive,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: isActive
            ? IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {},
              )
            : IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {},
              ),
      ),
    );
  }
}
