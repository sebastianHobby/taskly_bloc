# Test Timeout Quick Reference

## Can Tests Run Indefinitely?

**YES** - Tests can hang for 10+ minutes or run indefinitely under these conditions:

1. ❌ `pumpAndSettle()` with active BLoC streams
2. ❌ Relying only on `@Timeout` annotation (inactivity-only)
3. ❌ Unclosed `StreamController` or subscriptions
4. ❌ Using `pump(Duration)` with scheduled timers
5. ❌ Infinite loops in test logic

## The ONE Thing That Fixes Everything

```dart
// Use this wrapper for ALL widget tests
testWidgetsWithTimeout(
  'my test',
  timeout: const Duration(seconds: 30), // HARD LIMIT
  (tester) async {
    // Your test code here
  },
);
```

**Why it works:** Enforces **total duration timeout** regardless of test activity.

## Quick Fix Checklist

When a test hangs, check:

- [ ] Replace `testWidgets` → `testWidgetsWithTimeout`
- [ ] Replace `pumpAndSettle()` → `pumpForStream()` (for BLoC widgets)
- [ ] Add `addTearDown(() => subscription.cancel())` for streams
- [ ] Replace `pump(Duration)` → `pump()` (multiple calls)
- [ ] Verify all `StreamController`s are closed in tearDown

## Safe Patterns

```dart
// ✅ Widget tests with timeout
testWidgetsWithTimeout('test', (tester) async { ... });

// ✅ BLoC widgets - fixed frames
await tester.pumpForStream();

// ✅ Stream cleanup
final subscription = stream.listen(handler);
addTearDown(() async => await subscription.cancel());

// ✅ Pump without blocking
await tester.pump(); // No duration parameter
for (var i = 0; i < 10; i++) {
  await tester.pump();
}

// ✅ Pump with timeout protection
await tester.pumpAndSettleSafe(timeout: Duration(seconds: 2));
```

## Unsafe Patterns

```dart
// ❌ No timeout protection
testWidgets('test', (tester) async { ... });

// ❌ Will hang with streams
await tester.pumpAndSettle();

// ❌ Stream leak risk
final subscription = stream.listen(handler);
await Future.delayed(Duration(milliseconds: 50));
await subscription.cancel(); // May not be reached if test fails

// ❌ Can block indefinitely
await tester.pump(const Duration(seconds: 1));
```

## Timeout Types Comparison

| Type | Triggers On | Protects Against | Use Case |
|------|-------------|------------------|----------|
| `testWidgetsWithTimeout` | **Total duration** | Everything ✅ | **Primary protection** |
| `@Timeout` | Inactivity only | Deadlocks only | Supplementary |
| `pumpAndSettleSafe` | Total duration | Settle loops | Pump operations |
| `Future.timeout()` | Total duration | Async operations | Individual operations |

## Default Timeouts

```dart
// From pump_helpers.dart
const kDefaultPumpTimeout = Duration(seconds: 2);    // Pump operations
const kDefaultTestTimeout = Duration(seconds: 30);   // Widget tests
const kIntegrationTestTimeout = Duration(seconds: 45); // Integration tests
```

## Emergency Debug

If a test is hanging right now:

1. **Kill it:** Press Ctrl+C
2. **Identify:** Check test output for last operation before hang
3. **Quick fix:** Wrap in `testWidgetsWithTimeout` with 5-second timeout
4. **Run again:** Test should fail fast with timeout error
5. **Fix root cause:** Follow checklist above

## More Information

- **Detailed analysis:** [TEST_TIMEOUT_ANALYSIS.md](TEST_TIMEOUT_ANALYSIS.md)
- **Complete guide:** [TESTING_GUIDE.md](TESTING_GUIDE.md#test-timeouts--infinite-loops)
- **Working examples:** [timeout_protection_example_test.dart](examples/timeout_protection_example_test.dart)

## Configuration Files

Update these for comprehensive protection:

**dart_test.yaml:**
```yaml
timeout: 5m  # Process-level timeout
tags:
  integration:
    timeout: 60s  # Per-test inactivity timeout
```

**CI/CD (e.g., .github/workflows/test.yml):**
```yaml
jobs:
  test:
    timeout-minutes: 10  # Kill job after 10 minutes
```
