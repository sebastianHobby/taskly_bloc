import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class FormBuilderColorPicker extends StatelessWidget {
  const FormBuilderColorPicker({
    required this.name,
    this.title,
    this.showLabel = true,
    this.compact = false,
    this.validator,
    super.key,
  });

  final String name;
  final String? title;
  final bool showLabel;
  final bool compact;
  final FormFieldValidator<Color>? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final palette = ColorUtils.valuePaletteColorsFor(theme.brightness);
    final effectiveTitle = title ?? context.l10n.colorLabel;

    return FormBuilderField<Color>(
      name: name,
      validator: validator,
      builder: (field) {
        final value = field.value ?? cs.primary;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLabel)
              Padding(
                padding: EdgeInsets.only(
                  bottom: compact ? tokens.spaceXs2 : tokens.spaceSm,
                ),
                child: Text(
                  effectiveTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            TasklyFormColorPalettePicker(
              colors: palette,
              selectedColor: value,
              onSelected: (color) => field.didChange(color),
            ),
            if (field.errorText != null) ...[
              SizedBox(height: tokens.spaceSm),
              Text(
                field.errorText!,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
              ),
            ],
          ],
        );
      },
    );
  }
}
