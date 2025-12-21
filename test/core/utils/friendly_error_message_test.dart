import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('friendlyErrorMessage', () {
    test('returns RepositoryException message', () {
      expect(
        friendlyErrorMessage(RepositoryException('nope')),
        'nope',
      );
    });

    test('returns conservative fallback for unknown errors', () {
      expect(
        friendlyErrorMessage(Exception('boom')),
        'Something went wrong. Please try again.',
      );
    });
  });

  group('friendlyErrorMessageForUi', () {
    testWidgets('returns string errors as-is', (tester) async {
      late AppLocalizations l10n;

      await pumpLocalizedApp(
        tester,
        home: Builder(
          builder: (context) {
            l10n = context.l10n;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(
        friendlyErrorMessageForUi('already friendly', l10n),
        'already friendly',
      );
    });

    testWidgets('localizes NotFoundEntity variants', (tester) async {
      late AppLocalizations l10n;

      await pumpLocalizedApp(
        tester,
        home: Builder(
          builder: (context) {
            l10n = context.l10n;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(
        friendlyErrorMessageForUi(NotFoundEntity.task, l10n),
        l10n.taskNotFound,
      );
      expect(
        friendlyErrorMessageForUi(NotFoundEntity.project, l10n),
        l10n.projectNotFound,
      );
      expect(
        friendlyErrorMessageForUi(NotFoundEntity.label, l10n),
        l10n.labelNotFound,
      );
    });

    testWidgets('returns RepositoryException message', (tester) async {
      late AppLocalizations l10n;

      await pumpLocalizedApp(
        tester,
        home: Builder(
          builder: (context) {
            l10n = context.l10n;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(
        friendlyErrorMessageForUi(RepositoryException('nope'), l10n),
        'nope',
      );
    });

    testWidgets('returns localized generic fallback for unknown errors', (
      tester,
    ) async {
      late AppLocalizations l10n;

      await pumpLocalizedApp(
        tester,
        home: Builder(
          builder: (context) {
            l10n = context.l10n;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(
        friendlyErrorMessageForUi(Exception('boom'), l10n),
        l10n.genericErrorFallback,
      );
    });
  });
}
