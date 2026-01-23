import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_catalog.dart';

class TasklyTileCatalogPage extends StatelessWidget {
  const TasklyTileCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tile Catalog'),
      ),
      body: SafeArea(
        child: TasklyTileCatalog(),
      ),
    );
  }
}
