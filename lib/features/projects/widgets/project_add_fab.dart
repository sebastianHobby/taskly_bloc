import 'package:flutter/material.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/view/project_detail_view.dart';

class AddProjectFab extends StatelessWidget {
  const AddProjectFab({
    required this.projectRepository,
    super.key,
  });

  final ProjectRepository projectRepository;

  @override
  Widget build(BuildContext fabContext) {
    return FloatingActionButton(
      tooltip: 'Create project',
      onPressed: () async {
        late PersistentBottomSheetController controller;
        controller = Scaffold.of(fabContext).showBottomSheet(
          (ctx) => Material(
            color: Theme.of(ctx).colorScheme.surface,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: ProjectDetailSheetPage(
                projectRepository: projectRepository,
                onSuccess: (message) {
                  controller.close();
                  ScaffoldMessenger.of(fabContext).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                },
                onError: (errorMessage) {
                  ScaffoldMessenger.of(fabContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: $errorMessage'),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      heroTag: 'create_project_fab',
      child: const Icon(Icons.add),
    );
  }

  // return Builder(
  //   builder: (fabContext) {
  //     return FloatingActionButton(
  //       tooltip: 'Create project',
  //       onPressed: () async {
  //         late PersistentBottomSheetController controller;
  //         controller = Scaffold.of(fabContext).showBottomSheet(
  //           (ctx) => Material(
  //             color: Theme.of(ctx).colorScheme.surface,
  //             elevation: 8,
  //             child: SafeArea(
  //               top: false,
  //               child: ProjectDetailSheetPage(
  //                 onSuccess: (message) {
  //                   controller.close();
  //                   ScaffoldMessenger.of(fabContext).showSnackBar(
  //                     SnackBar(content: Text(message)),
  //                   );
  //                 },
  //                 onError: (errorMessage) {
  //                   ScaffoldMessenger.of(fabContext).showSnackBar(
  //                     SnackBar(
  //                       content: Text('Error: $errorMessage'),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //       heroTag: 'create_project_fab',
  //       child: const Icon(Icons.add),
  //     );
  //   },
  // );
}
