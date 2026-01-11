# Phase 1: Remove Screen Create UI

**Risk Level:** Low  
**Estimated Time:** 15 minutes  
**Dependencies:** None

---

## Objective

Remove the screen creation and management UI pages. These are user-facing pages that allow creating custom screens. This is the lowest risk removal as it's purely presentation layer.

---

## Files to Delete (3 files)

### 1. Screen Creator Page
```
lib/presentation/screens/view/screen_creator_page.dart
```
**Lines:** ~535  
**Description:** UI for creating new custom screens

### 2. Screen Management Page
```
lib/presentation/screens/view/screen_management_page.dart
```
**Lines:** ~507  
**Description:** UI for managing existing custom screens

### 3. Associated Test (if exists)
```
test/presentation/screens/view/screen_creator_page_test.dart (check if exists)
test/presentation/screens/view/screen_management_page_test.dart (check if exists)
```

---

## Files to Modify (2 files)

### 1. Remove System Screen Definition

**File:** `lib/domain/screens/catalog/system_screens/system_screen_definitions.dart`

**Action:** Remove `screenManagement` screen definition (around line 304-320)

**Find:**
```dart
  /// Screen Management screen for managing custom screens
  static const screenManagement = ScreenDefinition(
    id: 'screen_management',
    screenKey: 'screen_management',
    // ... rest of definition
  );
```

**Also remove from:**
- `getByKey()` switch statement (around line 520)
- `defaultSortOrders` map (around line 570)

### 2. Remove Navigation Icon Mapping

**File:** `lib/presentation/features/navigation/services/navigation_icon_resolver.dart`

**Action:** Remove icon mapping for screen_management (if exists)

**Search for:** `screen_management` or `screen-management`

---

## Repository Methods Impact

These methods in screen repositories will become unused after UI removal:
- `watchCustomScreens()`
- `createCustomScreen()`
- `updateCustomScreen()`
- `deleteCustomScreen()`

**Note:** These will be removed in Phase 4 (Data Layer cleanup)

---

## Validation Steps

### 1. Delete files
```bash
rm lib/presentation/screens/view/screen_creator_page.dart
rm lib/presentation/screens/view/screen_management_page.dart
# Check and remove test files if they exist
rm test/presentation/screens/view/screen_creator_page_test.dart 2>/dev/null || true
rm test/presentation/screens/view/screen_management_page_test.dart 2>/dev/null || true
```

### 2. Make modifications to remaining files
- Edit `system_screen_definitions.dart`
- Edit `navigation_icon_resolver.dart`

### 3. Run analysis
```bash
flutter analyze
```

### 4. Fix any import errors
Common issues:
- Routes still referencing deleted pages
- Navigation code still referencing screen_management

### 5. Verify no references remain
```bash
# Should return no results after cleanup
grep -r "screen_creator_page" lib/
grep -r "screen_management_page" lib/
grep -r "screen_management" lib/ | grep -v "system_screen"
```

---

## Expected Analyze Output

```
Analyzing taskly_bloc...
No issues found!
```

---
---

## Next Phase

→ **Phase 2:** Remove workflow domain models
