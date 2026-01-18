# Performance Diagnostics - Scheduled Screen

## 📊 Viewing Performance Logs

Performance logs are now instrumented throughout the scheduled screen. Logs are written to **Dart DevTools** by default. File-based Talker perf logs are **opt-in** to prevent log growth.

### Option 1: Talker Logs (Recommended for Persistent Analysis)
> Note: Talker perf file logs are disabled by default. Enable them with:
> `--dart-define=ENABLE_PERF_FILE_LOGS=true`
1. Navigate to your app's data directory
2. Open the Talker log file (usually in app documents/logs)
3. Search for `[Perf]` entries
4. Performance warnings (>500ms) are logged automatically

**Advantages:**
- Persistent logs survive app restarts
- Easy to share logs for debugging
- Can analyze historical performance
- Includes warnings for slow operations

### Option 2: Dart DevTools (Recommended for Real-time)
1. Run your app in debug mode
2. Open Dart DevTools (VS Code: `Dart: Open DevTools`)
3. Go to the **Logging** tab
4. Filter by names:
   - `perf.scheduled` - Overall timing and data volume
   - `perf.scheduled.query` - Individual repository queries
   - `perf.scheduled.processing` - Data processing steps
   - `perf.scheduled.expansion` - Occurrence expansion warnings
   - `perf.scheduled.fetch` - Initial fetch operations
   - `perf.scheduled.ui` - UI rendering performance
   - `perf.screen` - Screen-level loading

**Advantages:**
- Real-time monitoring
- Color-coded log levels
- Integrated with Flutter DevTools

### Option 3: Console Output
Run the app and watch the debug console for log entries like:
```
🚀 Scheduled: Starting watchAgendaData (range: 30 days)
📊 Scheduled: Overdue tasks fetched: 5
📊 Scheduled: Scheduled tasks fetched: 42 (repeating: 8)
⚙️ Scheduled: Processing data - OD Tasks: 5, OD Projects: 2, Scheduled Tasks: 42, Scheduled Projects: 6
✅ Scheduled: Complete - Total: 234ms (processing: 89ms, expansion: 67ms, grouping: 22ms) | Groups: 37, Total Items: 156, Overdue: 7
```

### Automatic Warnings

The system automatically logs warnings to Talker when:
- **Total load time >500ms**: `[Perf] Scheduled screen slow: 567ms`
- **UI build time >100ms**: `[Perf] ⚠️ Scheduled UI: Slow build - 234ms`
- **Screen load time >1000ms**: `[Perf] Screen "Scheduled" slow load: 1234ms`
- **First data arrival >3000ms**: `[Perf] Screen "Scheduled": VERY SLOW first data: 4567ms`
- **Task expansion >10 dates**: `[Perf] ⚠️ Scheduled: Task "Daily workout" expanding to 30 dates`

These warnings are automatically written to the Talker log file for later analysis.

### Understanding Load Time Breakdown

The logging now tracks the complete user experience from navigation to data display:

1. **Loading State Emitted** - When the spinner appears (should be <10ms)
2. **Interpreter Started** - When the data interpreter begins processing
3. **Section Watch Started** - When individual sections start fetching data
4. **Repository Queries** - Database query execution time
5. **First Data Arrival** - When the UI receives first data (**critical metric**)
6. **Data Processing** - Time spent transforming data
7. **UI Build** - Time spent rendering the widgets

**Example Timeline:**
```
📱 Screen: Loading screen "Scheduled"                    [0ms]
🔄 Interpreter: Starting watchScreen for "Scheduled"     [2ms]
📦 Section: Starting watch for agenda                    [3ms]
🚀 Scheduled: Starting watchAgendaData (range: 47 days)  [5ms]
🔍 Scheduled: Subscribing to repository streams...       [6ms]
📊 Scheduled: Scheduled tasks fetched: 20                [350ms] ⚠️
✅ Scheduled: Complete - Total: 99ms                     [449ms]
⏱️ Screen "Scheduled": First data after 450ms            [450ms]
```

If you see a 4+ second loading spinner but fast query times, the delay is likely in steps 1-6, not step 7-8.

## 🔍 What to Look For

### 1. **Database Query Delays** (Most Common for 4+ Second Loads)
```
🔍 Scheduled: Subscribing to repository streams...       [6ms]
📊 Scheduled: Scheduled tasks fetched: 20                [4200ms] ⚠️ ISSUE HERE
```
**Issue:** Repository queries taking >3 seconds  
**Causes:**
- PowerSync initial sync not complete
- Database not indexed properly
- Cold start query compilation
- Large dataset without pagination

**Fix:**
- Check PowerSync sync status before loading screen
- Add database indexes on frequently queried fields
- Implement loading states that show "Syncing..." instead of blank spinner
- Use connection state monitoring

### 2. **Stream Subscription Delays**
```
📦 Section: Starting watch for agenda                    [3ms]
(4 second gap - no logs)
🚀 Scheduled: Starting watchAgendaData...                [4003ms] ⚠️ ISSUE HERE
```
**Issue:** Delay between section start and data service call  
**Causes:**
- Dependency injection slowness (getIt lazy initialization)
- Cold start service initialization
- Synchronous work blocking event loop

**Fix:**
- Pre-warm critical services on app start
- Profile dependency injection container
- Move heavy initialization to isolates

### 3. **Slow Query Times** (>200ms)
```
📊 Scheduled: Scheduled tasks fetched: 342 (repeating: 45)
```
**Issue:** Too many tasks or complex queries  
**Fix:** Add indexes, optimize queries, or implement pagination

### 3. **High Occurrence Expansion** (>10 dates per task)
```
⚠️ Scheduled: Task "Daily workout" expanding to 30 dates
```
**Issue:** Repeating tasks with long date ranges creating many occurrences  
**Fix:** Implement virtual scrolling or lazy loading of occurrences

### 4. **Long Processing Time** (expansion + grouping >100ms)
```
✅ Scheduled: Complete - Total: 567ms (processing: 345ms, expansion: 289ms, grouping: 56ms)
```
**Issue:** Too many items being processed at once  
**Fix:** Optimize date group generation algorithm

### 5. **Slow UI Build** (>100ms)
```
⚠️ Scheduled UI: Slow build - 234ms
```
**Issue:** Widget tree too complex or too many items  
**Fix:** Implement better lazy loading, optimize widget builds

### 6. **High Total Item Count** (>500)
```
✅ Scheduled: Complete - Groups: 45, Total Items: 823, Overdue: 12
```
**Issue:** Too many agenda items being rendered  
**Fix:** Reduce date range or implement virtual scrolling

## 📈 Performance Targets

| Metric | Good | Acceptable | Poor |
|--------|------|------------|------|
| Total Load Time | <300ms | 300-800ms | >800ms |
| Query Time | <100ms | 100-300ms | >300ms |
| Processing Time | <50ms | 50-150ms | >150ms |
| UI Build Time | <50ms | 50-150ms | >150ms |
| Total Items | <200 | 200-500 | >500 |
| Occurrence Expansion | <5 dates | 5-15 dates | >15 dates |

## 🛠️ Common Performance Issues & Solutions

### Issue 1: Many Repeating Tasks with Long Date Ranges
**Symptom:** High occurrence expansion warnings, slow processing  
**Solution:** 
- Reduce default date range from 30 to 14 days
- Implement on-demand loading for distant dates
- Consider virtual occurrences (calculate on-demand instead of pre-generating)

### Issue 2: Database Query Slowness
**Symptom:** Slow query times (>300ms)  
**Solution:**
- Check PowerSync sync status
- Add database indexes
- Profile individual queries
- Reduce query complexity

### Issue 3: Too Many "In Progress" Entries
**Symptom:** Tasks expanding to many dates  
**Solution:**
- Remove "In Progress" tag for tasks with >7 day ranges
- Show "In Progress" only on explicit user action
- Group "In Progress" items differently

### Issue 4: Stream Rebuild Overhead
**Symptom:** Frequent rebuilds, stuttering UI  
**Solution:**
- Increase debounce time from 50ms to 100ms
- Implement better change detection
- Use selective stream subscriptions

## 🔬 Next Steps for Deep Diagnosis

1. **Profile with real data:** Load production data volume
2. **Measure database queries:** Use PowerSync profiling tools
3. **Check memory usage:** Look for memory leaks in stream subscriptions
4. **UI frame rendering:** Use Flutter Performance overlay (`flutter run --profile`)
5. **Network impact:** Check if sync is affecting performance

## 📝 Recording Performance Data

To create a performance report:

```dart
// Add this temporarily to AgendaSectionDataService.watchAgendaData():
final perfData = {
  'timestamp': DateTime.now().toIso8601String(),
  'overdueTasks': overdueTasks.length,
  'overdueProjects': overdueProjects.length,
  'scheduledTasks': tasksWithDates.length,
  'scheduledProjects': projectsWithDates.length,
  'repeatingTasks': tasksWithDates.where((t) => t.isRepeating).length,
  'repeatingProjects': projectsWithDates.where((p) => p.isRepeating).length,
  'totalGroups': groups.length,
  'totalItems': totalAgendaItems,
  'rangeDays': rangeDays,
  'totalMs': totalMs,
  'expansionMs': expansionMs,
  'groupingMs': groupingMs,
};
// Log this to a file or send to analytics
```

