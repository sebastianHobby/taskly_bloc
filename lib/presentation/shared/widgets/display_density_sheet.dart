import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/widgets/display_density_toggle.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

Future<void> showDisplayDensitySheet({
  required BuildContext context,
  required DisplayDensity density,
  required ValueChanged<DisplayDensity> onChanged,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final tokens = TasklyTokens.of(sheetContext);
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.9,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spaceLg,
                    tokens.spaceSm,
                    tokens.spaceLg,
                    tokens.spaceLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sheetContext.l10n.displayDensityTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: tokens.spaceSm),
                      DisplayDensityToggle(
                        density: density,
                        onChanged: (next) {
                          if (next == density) return;
                          onChanged(next);
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
