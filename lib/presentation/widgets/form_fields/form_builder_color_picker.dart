import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class FormBuilderColorPicker extends StatelessWidget {
  const FormBuilderColorPicker({
    required this.name,
    this.title = 'Color',
    this.showLabel = true,
    this.compact = false,
    this.validator,
    super.key,
  });

  final String name;
  final String title;
  final bool showLabel;
  final bool compact;
  final FormFieldValidator<Color>? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FormBuilderField<Color>(
      name: name,
      validator: validator,
      builder: (field) {
        final value = field.value ?? cs.primary;

        Future<void> pick() async {
          Color tmp = value;

          final picked = await showDialog<Color>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(title),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    color: value,
                    onColorChanged: (c) => tmp = c,
                    borderRadius: 12,
                    pickersEnabled: const {
                      ColorPickerType.primary: true,
                      ColorPickerType.accent: true,
                      ColorPickerType.both: false,
                      ColorPickerType.bw: false,
                      ColorPickerType.custom: false,
                      ColorPickerType.wheel: true,
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(tmp),
                    child: const Text('Select'),
                  ),
                ],
              );
            },
          );

          if (picked != null) {
            field.didChange(picked);
          }
        }

        final height = compact ? 44.0 : 52.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLabel)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            InkWell(
              onTap: pick,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: value,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.outlineVariant),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '#${value.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.palette_outlined, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            if (field.errorText != null) ...[
              const SizedBox(height: 6),
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
