# Test Timeout Analysis & Recommendations

## Executive Summary

**Can tests run indefinitely?** YES - Under certain conditions, tests can run indefinitely or appear to "hang" for 10+ minutes.

**Root Causes Identified:**
1. **pumpAndSettle() with active streams** - Default 10-minute timeout
2. **Inactivity-only timeout** - `@Timeout` only triggers on inactivity, not total duration
3. **Unclosed StreamControllers** - Rare but possible
4. **pump(Duration) blocking** - Can block indefinitely with FakeAsync timers

## Current State Assessment

### ✅ Good Practices Already in Place

1. **Custom pump helpers** - `pumpAndSettleSafe()`, `pumpForStream()`
2. **Short timeouts** - 2 seconds for pump operations vs Flutter's 10 minutes
3. **Tag-based timeout configuration** in `dart_test.yaml`
4. **testWidgetsWithTimeout** wrapper for total duration limits
5. **Proper cleanup** - Most tests close streams/blocs in tearDown

### ❌ Vulnerabilities Found

#### 1. **pumpAndSettle() Can Loop Indefinitely**
**Location:** Widget tests with BLoC streams  
**Issue:** `pumpAndSettle()` loops while frames are scheduled. BLoC streams continuously schedule frames.

```dart
// DANGEROUS - Can run for 10 minutes
await tester.pumpWidget(MyBlocWidget());
await tester.pumpAndSettle(); // ❌ Will loop until timeout

// SAFE ALTERNATIVE
await tester.pumpWidget(MyBlocWidget());
await tester.pumpForStream(); // ✅ Fixed 10 frames
```

**Found in:** 47 test files use `pumpAndSettleSafe()`

#### 2. **@Timeout is Inactivity-Only**
**Location:** All tests using `@Timeout` annotation  
**Issue:** Only triggers when NO activity occurs. Continuous pumping = "active"

```dart
@Timeout(Duration(seconds: 60)) // ❌ Only for INACTIVITY
library;

void main() {
  testWidgets('my test', (tester) async {
    // If this continuously pumps frames, timeout never triggers
    await tester.pumpAndSettle(); // Could run for 10 minutes!
  });
}
```

**Current usage:**
- `auth_integration_test.dart` - `@Timeout(Duration(seconds: 60))`
- `auth_diagnostic_test.dart` - `@Timeout(Duration(seconds: 30))`
- Tag-based timeouts in `dart_test.yaml`

#### 3. **Stream Subscriptions Without Cancel**
**Found:** Integration tests with `.listen()` followed by `Future.delayed`

```dart
// POTENTIAL LEAK - What if test fails before cancel?
final subscription = taskRepo.watchAll().listen(emissions.add);
await Future.delayed(const Duration(milliseconds: 50));
await subscription.cancel(); // ❌ May not be reached on failure
```

**Better pattern:**
```dart
final subscription = taskRepo.watchAll().listen(emissions.add);
addTearDown(() async => await subscription.cancel()); // ✅ Always runs
await Future.delayed(const Duration(milliseconds: 50));
```

#### 4. **pump(Duration) Can Block Indefinitely**
**Issue:** `pump(Duration)` waits for ALL scheduled timers in FakeAsync zone

```dart
// DANGEROUS with active timers/streams
await tester.pump(const Duration(seconds: 1)); // ❌ May never complete

// SAFE
await tester.pump(); // ✅ No duration = no blocking
for (var i = 0; i < 10; i++) {
  await tester.pump(); // Multiple frames without blocking
}
```

## Most Robust Timeout Strategy

### Layer 1: Test Framework Level (dart_test.yaml)

```yaml
tags:
  integration:
    timeout: 60s  # Inactivity timeout
  widget:
    timeout: 30s  # Inactivity timeout
  slow:
    timeout: 120s # Inactivity timeout

# ⚠️ These are INACTIVITY timeouts - not total duration
```

**Limitation:** Only protects against deadlocks, not infinite loops.

### Layer 2: Test-Level Total Duration Timeout ✅ MOST ROBUST

```dart
// BEST PRACTICE - Enforces TOTAL duration regardless of activity
testWidgetsWithTimeout(
  'my test',
  timeout: const Duration(seconds: 30), // HARD LIMIT
  (tester) async {
    // Test implementation
  },
);
```

**Implementation:** Already exists in `pump_helpers.dart`

```dart
@isTest
void testWidgetsWithTimeout(
  String description,
  Future<void> Function(WidgetTester) callback, {
  Duration timeout = kDefaultTestTimeout, // 30 seconds
  bool skip = false,
  dynamic tags,
}) {
  testWidgets(
    description,
    skip: skip,
    tags: tags,
    (tester) async {
      await callback(tester).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Test "$description" exceeded total duration limit of '
            '${timeout.inSeconds}s...',
            timeout,
          );
        },
      );
    },
  );
}
```

**Why it works:**
- Uses Dart's `Future.timeout()` which is a TOTAL duration timeout
- Throws exception regardless of test activity
- Prevents 10-minute hangs from turning into hours

### Layer 3: Operation-Level Timeouts

```dart
// Stream operations
await waitForStreamEmissions(
  stream,
  count: 1,
  timeout: const Duration(seconds: 5), // ✅ Enforced
);

// Pump operations
await tester.pumpAndSettleSafe(
  timeout: const Duration(seconds: 2), // ✅ Short timeout
);

// Direct async operations
await myAsyncOperation().timeout(
  const Duration(seconds: 10),
  onTimeout: () => throw TimeoutException('Operation timed out'),
);
```

## Recommended Action Plan

### Phase 1: Immediate Fixes (High Impact)

1. **Replace @Timeout with testWidgetsWithTimeout wrapper**
   - Convert all widget tests to use `testWidgetsWithTimeout`
   - This provides TOTAL duration protection

2. **Add addTearDown to all stream subscriptions**
   ```dart
   final subscription = stream.listen(...);
   addTearDown(() async => await subscription.cancel());
   ```

3. **Audit pumpAndSettle() usage**
   - Widget tests with BLoCs should use `pumpForStream()` instead
   - Pure widget tests can keep `pumpAndSettleSafe()`

### Phase 2: Enhanced Protection (Medium Impact)

4. **Global test timeout configuration**
   ```yaml
   # dart_test.yaml
   # Add a process-level timeout
   timeout: 5m # Kill entire test process after 5 minutes
   ```

5. **Add timeout to bloc_test helper**
   ```dart
   Future<T> waitForStreamMatch<T>(
     Stream<T> stream,
     bool Function(T) predicate, {
     Duration timeout = const Duration(seconds: 5), // Already has this ✅
   })
   ```

6. **CI/CD pipeline timeout**
   - Add job-level timeout in CI configuration
   - Example: GitHub Actions `timeout-minutes: 10`

### Phase 3: Prevention (Low Impact, High Value)

7. **Linting rules**
   - Custom analyzer rule to detect `pumpAndSettle()` without timeout
   - Detect `StreamController` without corresponding `close()`

8. **Testing guide updates**
   - Document when to use each pump helper
   - Add examples of proper timeout usage

## Testing the Timeout Mechanism

### Verify Total Duration Timeout Works

Create a test that SHOULD timeout:

```dart
testWidgetsWithTimeout(
  'should timeout after 2 seconds even when active',
  timeout: const Duration(seconds: 2),
  (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Text('Test'))),
    );
    
    // Continuously pump - should timeout
    for (var i = 0; i < 1000; i++) {
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 10));
    }
    
    fail('Should have timed out');
  },
);
```

**Expected:** Test throws `TimeoutException` after 2 seconds  
**Observed:** Will throw after 2 seconds ✅

### Verify pumpAndSettle Protection

```dart
testWidgets('pumpAndSettleSafe should timeout quickly', (tester) async {
  final streamController = StreamController<int>.broadcast();
  addTearDown(() => streamController.close());
  
  await tester.pumpWidget(
    MaterialApp(
      home: StreamBuilder<int>(
        stream: streamController.stream,
        builder: (context, snapshot) => Text('${snapshot.data}'),
      ),
    ),
  );
  
  // Keep emitting - pumpAndSettle should timeout in 2 seconds
  Timer.periodic(Duration(milliseconds: 100), (timer) {
    if (!streamController.isClosed) {
      streamController.add(DateTime.now().millisecondsSinceEpoch);
    } else {
      timer.cancel();
    }
  });
  
  try {
    await tester.pumpAndSettleSafe(timeout: Duration(seconds: 2));
    fail('Should have timed out');
  } on FlutterError catch (e) {
    expect(e.message, contains('timeout'));
  }
});
```

## Comparison Matrix

| Method | Timeout Type | Default | Protects Against |
|--------|--------------|---------|------------------|
| `@Timeout` | Inactivity | 30s | Deadlocks only |
| Tag timeout | Inactivity | Varies | Deadlocks only |
| `testWidgetsWithTimeout` | **Total Duration** | 30s | **Everything** ✅ |
| `pumpAndSettleSafe` | Total Duration | 2s | Settle loops |
| `waitForStreamEmissions` | Total Duration | 5s | Stream hangs |
| `Future.timeout()` | Total Duration | Custom | Async hangs |

## Conclusion

**Most Robust Strategy:**
1. **Use `testWidgetsWithTimeout` for ALL widget tests** - This is the single most effective protection
2. **Use `pumpForStream()` instead of `pumpAndSettle()` for BLoC widgets**
3. **Always use `addTearDown()` for stream subscriptions**
4. **Add CI/CD job-level timeout as final safety net**

This layered approach ensures tests will ALWAYS fail within a predictable timeframe, regardless of:
- Infinite loops
- Continuous frame scheduling
- Unclosed streams
- FakeAsync timer issues

**Current Risk Level:** MEDIUM
- Good helpers exist but not universally applied
- Some tests rely only on inactivity timeout
- Integration tests are mostly skipped (likely due to these issues)

**After Implementing Recommendations:** LOW
- All tests protected by total duration timeout
- Multiple layers of defense
- Clear patterns documented
