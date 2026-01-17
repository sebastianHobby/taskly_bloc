import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_inbox_section_params_v1.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_inbox_section_renderer_v1.dart';

class AttentionInboxPage extends StatelessWidget {
  const AttentionInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attention'),
        actions: [
          IconButton(
            tooltip: 'Attention rules',
            onPressed: () => Routing.pushScreenKey(context, 'attention_rules'),
            icon: const Icon(Icons.tune_outlined),
          ),
        ],
      ),
      body: const AttentionInboxSectionRendererV1(
        params: AttentionInboxSectionParamsV1(),
      ),
    );
  }
}
