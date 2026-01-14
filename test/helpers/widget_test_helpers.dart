/// Helpers for widget tests with BLoCs.
///
/// Widget tests verify that UI components render and behave correctly.
/// These helpers handle common patterns for testing widgets that depend
/// on BLoCs and streams.
///
/// ## Key Patterns
///
/// 1. **Never use pumpAndSettle() with BLoC widgets** - use pumpForStream()
/// 2. **Always use testWidgetsSafe()** - prevents infinite hangs
/// 3. **Mock BLoC states, not repositories** - test UI behavior, not business logic
///
/// ## Usage
///
/// ```dart
/// testWidgetsSafe('shows loading state', (tester) async {
///   final mockBloc = MockMyBloc();
///   when(() => mockBloc.state).thenReturn(MyState.loading());
///   when(() => mockBloc.stream).thenAnswer((_) => Stream.empty());
///
///   await tester.pumpWidgetWithBloc<MyBloc>(
///     bloc: mockBloc,
///     child: const MyWidget(),
///   );
///
///   expect(find.byType(CircularProgressIndicator), findsOneWidget);
/// });
/// ```
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'pump_app.dart';
import 'test_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Widget Test Timeout Constants
// ═══════════════════════════════════════════════════════════════════════════

/// Default timeout for widget tests (30 seconds).
const Duration kWidgetTestTimeout = kDefaultTestTimeout;

/// Default number of frames to pump for stream-based widgets.
const int kDefaultPumpFrames = 10;

// ═══════════════════════════════════════════════════════════════════════════
// Widget Pump Extensions
// ═══════════════════════════════════════════════════════════════════════════

/// Extensions for pumping widgets with common configurations.
extension WidgetPumpExtensions on WidgetTester {
  /// Pumps a widget wrapped in MaterialApp with theme and localizations.
  ///
  /// Use this for testing widgets that need Material Design context.
  ///
  /// ```dart
  /// await tester.pumpApp(const MyWidget());
  /// ```
  Future<void> pumpApp(
    Widget widget, {
    ThemeData? theme,
    Locale? locale,
  }) async {
    await pumpTasklyApp(
      this,
      home: widget,
      theme: theme,
      locale: locale,
    );
  }

  /// Pumps a widget with a BLoC provider.
  ///
  /// Automatically wraps in MaterialApp with theme and localizations.
  ///
  /// ```dart
  /// final mockBloc = MockMyBloc();
  /// when(() => mockBloc.state).thenReturn(MyState.initial());
  ///
  /// await tester.pumpWidgetWithBloc<MyBloc>(
  ///   bloc: mockBloc,
  ///   child: const MyWidget(),
  /// );
  /// ```
  Future<void> pumpWidgetWithBloc<T extends StateStreamableSource<Object?>>({
    required T bloc,
    required Widget child,
    ThemeData? theme,
  }) async {
    await pumpTasklyApp(
      this,
      theme: theme,
      home: BlocProvider<T>.value(
        value: bloc,
        child: child,
      ),
    );
  }

  /// Pumps a widget with multiple BLoC providers.
  ///
  /// ```dart
  /// await tester.pumpWidgetWithBlocs(
  ///   providers: [
  ///     BlocProvider<BlocA>.value(value: mockBlocA),
  ///     BlocProvider<BlocB>.value(value: mockBlocB),
  ///   ],
  ///   child: const MyWidget(),
  /// );
  /// ```
  Future<void> pumpWidgetWithBlocs({
    required List<BlocProvider<dynamic>> providers,
    required Widget child,
    ThemeData? theme,
  }) async {
    await pumpTasklyApp(
      this,
      theme: theme,
      home: MultiBlocProvider(
        providers: providers,
        child: child,
      ),
    );
  }

  /// Pumps a widget with a GoRouter configuration.
  ///
  /// Use for testing navigation-related widgets.
  ///
  /// ```dart
  /// await tester.pumpWidgetWithRouter(
  ///   router: GoRouter(
  ///     initialLocation: '/test',
  ///     routes: [
  ///       GoRoute(path: '/test', builder: (_, __) => const MyWidget()),
  ///     ],
  ///   ),
  /// );
  /// ```
  Future<void> pumpWidgetWithRouter({
    required GoRouter router,
    ThemeData? theme,
  }) async {
    await pumpTasklyApp(this, router: router, theme: theme);
  }

  /// Pumps frames and waits for a widget to appear, with timeout.
  ///
  /// Returns true if found, false if timeout reached.
  /// Throws if exceeding the hard timeout limit.
  ///
  /// ```dart
  /// final found = await tester.pumpAndFindWithTimeout(
  ///   find.text('Loaded'),
  ///   timeout: Duration(seconds: 3),
  /// );
  /// expect(found, isTrue);
  /// ```
  Future<bool> pumpAndFindWithTimeout(
    Finder finder, {
    Duration timeout = kDefaultPumpTimeout,
    Duration interval = const Duration(milliseconds: 50),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      await pump(interval);
      if (finder.evaluate().isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Pumps until condition is true or timeout, then verifies condition.
  ///
  /// Fails the test if condition is not met within timeout.
  ///
  /// ```dart
  /// await tester.pumpUntilCondition(
  ///   () => find.text('Done').evaluate().isNotEmpty,
  ///   reason: 'Expected "Done" text to appear',
  /// );
  /// ```
  Future<void> pumpUntilCondition(
    bool Function() condition, {
    Duration timeout = kDefaultPumpTimeout,
    Duration interval = const Duration(milliseconds: 50),
    String? reason,
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      await pump(interval);
      if (condition()) {
        return;
      }
    }

    fail(reason ?? 'Condition not met within ${timeout.inSeconds}s');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BLoC State Simulation
// ═══════════════════════════════════════════════════════════════════════════

/// Helper to simulate BLoC state changes in widget tests.
///
/// ```dart
/// final stateController = BlocStateSimulator<MyState>(MyState.loading());
///
/// when(() => mockBloc.state).thenAnswer((_) => stateController.current);
/// when(() => mockBloc.stream).thenAnswer((_) => stateController.stream);
///
/// await tester.pumpWidgetWithBloc(bloc: mockBloc, child: MyWidget());
///
/// // Simulate state change
/// stateController.emit(MyState.loaded(data));
/// await tester.pumpForStream();
///
/// expect(find.text('Loaded'), findsOneWidget);
/// ```
class BlocStateSimulator<T> {
  BlocStateSimulator(this._current);

  T _current;
  final _controller = StreamController<T>.broadcast();

  /// Current state value.
  T get current => _current;

  /// Stream of state changes.
  Stream<T> get stream => _controller.stream;

  /// Emits a new state.
  void emit(T state) {
    _current = state;
    _controller.add(state);
  }

  /// Closes the stream controller.
  Future<void> dispose() => _controller.close();
}

// ═══════════════════════════════════════════════════════════════════════════
// Finder Utilities
// ═══════════════════════════════════════════════════════════════════════════

/// Finds a widget by its Key.
Finder findByKey(Key key) => find.byKey(key);

/// Finds a widget by exact text.
Finder findText(String text) => find.text(text);

/// Finds a widget containing text (substring match).
Finder findTextContaining(String substring) => find.textContaining(substring);

/// Finds a widget by type.
Finder findByType<T extends Widget>() => find.byType(T);

/// Finds the first widget of type with specific predicate.
Finder findByWidgetPredicate<T extends Widget>(bool Function(T) predicate) {
  return find.byWidgetPredicate(
    (widget) => widget is T && predicate(widget),
  );
}
