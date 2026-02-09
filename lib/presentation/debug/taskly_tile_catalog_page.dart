import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_ui/taskly_ui_catalog.dart';

class TasklyTileCatalogPage extends StatelessWidget {
  const TasklyTileCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tileCatalogTitle),
      ),
      body: SafeArea(
        child: TasklyTileCatalog(),
      ),
    );
  }
}
