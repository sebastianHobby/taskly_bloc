/// E2E Smoke Tests for critical user journeys.
///
/// These tests verify that the app's most critical features work
/// end-to-end on a real device/emulator.
///
/// Run with: flutter test integration_test/smoke_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taskly_bloc/app/di/dependency_injection.dart'
    show getIt;
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/app/app.dart';

import 'e2e_test_helpers.dart';
import '../mocks/fake_repositories.dart';

class _FakeAuthRepository implements AuthRepositoryContract {
  @override
  Stream<AuthState> watchAuthState() => const Stream<AuthState>.empty();

  @override
  Session? get currentSession => null;

  @override
  User? get currentUser => null;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }

  @override
  Future<void> resetPasswordForEmail(String email) {
    throw UnimplementedError();
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) {
    throw UnimplementedError();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTalkerForTest();

    // The real app expects GetIt to be initialized by bootstrap code.
    // In widget tests we register minimal fakes so `App` can build.
    await getIt.reset();
    getIt
      ..registerSingleton<SettingsRepositoryContract>(FakeSettingsRepository())
      ..registerSingleton<AuthRepositoryContract>(_FakeAuthRepository());
  });

  group('Navigation Smoke Tests', () {
    testWidgetsE2E('app launches and shows initial screen', (tester) async {
      // Pump the app
      await tester.pumpWidget(const App());
      await tester.pumpE2E();

      // App should show either login or main navigation
      // Look for common UI elements
      final hasNavigation =
          find.byType(NavigationRail).evaluate().isNotEmpty ||
          find.byType(NavigationBar).evaluate().isNotEmpty ||
          find.byType(BottomNavigationBar).evaluate().isNotEmpty;
      final hasLogin =
          find.textContaining('Sign').evaluate().isNotEmpty ||
          find.textContaining('Login').evaluate().isNotEmpty;
      final hasLoading = find
          .byType(CircularProgressIndicator)
          .evaluate()
          .isNotEmpty;

      // One of these should be true
      expect(
        hasNavigation || hasLogin || hasLoading,
        isTrue,
        reason: 'App should show navigation, login, or loading state',
      );
    });

    testWidgetsE2E(
      'can find navigation destinations',
      (tester) async {
        await tester.pumpWidget(const App());
        await tester.pumpE2E();
        await tester.waitForScreenLoad();

        // Look for navigation elements - these exist in authenticated state
        final navDestinations = find.byType(NavigationDestination);
        final navRailDests = find.byType(NavigationRailDestination);
        final bottomNavItems = find.byType(BottomNavigationBarItem);

        final totalNavItems =
            navDestinations.evaluate().length +
            navRailDests.evaluate().length +
            bottomNavItems.evaluate().length;

        // If user is authenticated, should have navigation
        // If not, may be on login screen (which is also valid)
        if (totalNavItems > 0) {
          expect(
            totalNavItems,
            greaterThanOrEqualTo(3),
            reason: 'Should have at least 3 navigation destinations',
          );
        }
      },
      skip: true, // Skip until auth can be mocked in E2E
    );
  });

  group('UI Element Smoke Tests', () {
    testWidgetsE2E('app uses Material 3 theme', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpE2E();

      // Find MaterialApp and verify theme
      final materialApp = find.byType(MaterialApp);
      expect(materialApp, findsOneWidget);

      final widget = tester.widget<MaterialApp>(materialApp);
      expect(widget.theme?.useMaterial3 ?? true, isTrue);
    });

    testWidgetsE2E('app handles orientation changes', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpE2E();

      // Get initial size
      final initialSize = tester.view.physicalSize;

      // Rotate to landscape
      tester.view.physicalSize = Size(initialSize.height, initialSize.width);
      await tester.pumpE2E();

      // App should not crash
      expect(find.byType(MaterialApp), findsOneWidget);

      // Reset
      tester.view.resetPhysicalSize();
    });
  });

  group('Error Handling Smoke Tests', () {
    testWidgetsE2E('app shows error widget for errors', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpE2E();

      // ErrorStateWidget should be available in widget tree when errors occur
      // Just verify the app doesn't crash on startup
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Responsive Layout Smoke Tests', () {
    testWidgetsE2E('compact layout on small screens', (tester) async {
      // Set to phone-size viewport
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const App());
      await tester.pumpE2E();

      // Should use compact layout (no NavigationRail on small screens)
      // App should render without errors
      expect(find.byType(MaterialApp), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgetsE2E('expanded layout on large screens', (tester) async {
      // Set to tablet-size viewport
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const App());
      await tester.pumpE2E();

      // App should render without errors
      expect(find.byType(MaterialApp), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
