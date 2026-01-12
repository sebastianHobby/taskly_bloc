import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';

void showEditorErrorSnackBar(BuildContext context, Object error) {
  final message = friendlyErrorMessageForUi(error, context.l10n);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void showEditorSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> closeEditor(BuildContext context) {
  return Navigator.of(context).maybePop();
}
