import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

/// A modern text field with consistent styling and Material 3 design.
///
/// Features:
/// - Consistent visual design across the app
/// - Proper Material 3 styling
/// - Built-in spacing and padding
/// - Support for different field types (title, description, etc.)
class FormBuilderTextFieldModern extends StatelessWidget {
  const FormBuilderTextFieldModern({
    required this.name,
    this.label,
    this.hint,
    this.initialValue,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.isRequired = false,
    this.fieldType = ModernFieldType.standard,
    super.key,
  });

  final String name;
  final String? label;
  final String? hint;
  final String? initialValue;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isRequired;
  final ModernFieldType fieldType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getHorizontalPadding(tokens),
        vertical: _getVerticalPadding(tokens),
      ),
      child: FormBuilderTextField(
        name: name,
        initialValue: initialValue,
        validator: validator,
        enabled: enabled,
        readOnly: readOnly,
        obscureText: obscureText,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        keyboardType: keyboardType,
        style: _getTextStyle(theme),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: _getFillColor(colorScheme),
          border: _getBorder(colorScheme, tokens),
          enabledBorder: _getBorder(colorScheme, tokens),
          focusedBorder: _getFocusedBorder(colorScheme, tokens),
          errorBorder: _getErrorBorder(colorScheme, tokens),
          focusedErrorBorder: _getErrorBorder(colorScheme, tokens),
          contentPadding: _getContentPadding(tokens),
          counterText: maxLength != null ? '' : null,
          floatingLabelBehavior: fieldType == ModernFieldType.title
              ? FloatingLabelBehavior.never
              : FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  double _getHorizontalPadding(TasklyTokens tokens) {
    return switch (fieldType) {
      ModernFieldType.title => tokens.spaceXl,
      ModernFieldType.description => tokens.spaceXl,
      ModernFieldType.standard => tokens.spaceLg,
    };
  }

  double _getVerticalPadding(TasklyTokens tokens) {
    return switch (fieldType) {
      ModernFieldType.title => tokens.spaceSm,
      ModernFieldType.description => tokens.spaceMd,
      ModernFieldType.standard => tokens.spaceSm,
    };
  }

  TextStyle? _getTextStyle(ThemeData theme) {
    return switch (fieldType) {
      ModernFieldType.title => theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      ModernFieldType.description => theme.textTheme.bodyLarge,
      ModernFieldType.standard => theme.textTheme.bodyMedium,
    };
  }

  Color _getFillColor(ColorScheme colorScheme) {
    return switch (fieldType) {
      ModernFieldType.title => colorScheme.surface.withValues(alpha: 0),
      ModernFieldType.description => colorScheme.surfaceContainerLow,
      ModernFieldType.standard => colorScheme.surfaceContainerLow,
    };
  }

  OutlineInputBorder _getBorder(ColorScheme colorScheme, TasklyTokens tokens) {
    return switch (fieldType) {
      ModernFieldType.title => OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide.none,
      ),
      ModernFieldType.description => OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      ModernFieldType.standard => OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
    };
  }

  OutlineInputBorder _getFocusedBorder(
    ColorScheme colorScheme,
    TasklyTokens tokens,
  ) {
    return switch (fieldType) {
      ModernFieldType.title => OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      ModernFieldType.description => OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
      ModernFieldType.standard => OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
    };
  }

  OutlineInputBorder _getErrorBorder(
    ColorScheme colorScheme,
    TasklyTokens tokens,
  ) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        fieldType == ModernFieldType.description
            ? tokens.radiusLg
            : tokens.radiusMd,
      ),
      borderSide: BorderSide(
        color: colorScheme.error,
        width: 2,
      ),
    );
  }

  EdgeInsetsGeometry _getContentPadding(TasklyTokens tokens) {
    return switch (fieldType) {
      ModernFieldType.title => EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceLg3,
      ),
      ModernFieldType.description => EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceLg,
      ),
      ModernFieldType.standard => EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceLg,
      ),
    };
  }
}

/// Different visual styles for modern text fields.
enum ModernFieldType {
  /// Large title field with prominent styling
  title,

  /// Multi-line description field
  description,

  /// Standard single-line field
  standard,
}
