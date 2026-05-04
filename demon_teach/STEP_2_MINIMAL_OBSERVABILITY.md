# 🔍 STEP 2: Minimal Observability (VERY LIGHT)

## Rule: Add ONLY crash logging, nothing more

**NOT**: Full monitoring stack ❌
**YES**: Just enough to see crashes ✅

---

## Prerequisites

✅ Step 1 complete (app is stable)

---

## What to Add (MINIMAL)

### Option A: Firebase Crashlytics (Recommended)

**Why**: Free, easy, works well

**Add to pubspec.yaml**:
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_crashlytics: ^3.4.0
```

**Setup (5 minutes)**:
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (follow prompts)
flutterfire configure
```

**Add to main.dart**:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Catch Flutter errors
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  
  // Catch async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(const MyApp());
}
```

**That's it. Nothing more.**

### Option B: Sentry (Alternative)

**Why**: More features, but heavier

**Add to pubspec.yaml**:
```yaml
dependencies:
  sentry_flutter: ^7.14.0
```

**Add to main.dart**:
```dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN';
    },
    appRunner: () => runApp(const MyApp()),
  );
}
```

---

## What NOT to Add

❌ Analytics events
❌ Performance monitoring
❌ Custom dashboards
❌ User tracking
❌ Network logging
❌ Database logging

**Why?** Each adds complexity. Just crashes for now.

---

## Test Crash Logging

### Add Test Button (Debug Only)

```dart
// In your debug screen or settings
if (kDebugMode) {
  ElevatedButton(
    onPressed: () {
      throw Exception('Test crash');
    },
    child: Text('Test Crash'),
  );
}
```

### Verify

1. Press test button
2. App crashes
3. Reopen app
4. Check Firebase Console (or Sentry)
5. See crash report

**If crash doesn't appear** → Fix setup

---

## Optional: Log Network Errors (VERY LIGHT)

**Only if you want basic network error visibility**:

```dart
// In your datasources, add ONE line:
try {
  final response = await _dio.get('/api/lessons/$lessonId');
  return Result.success(response.data);
} on DioException catch (e) {
  // Add this ONE line:
  FirebaseCrashlytics.instance.recordError(
    e,
    StackTrace.current,
    reason: 'download_lesson_failed',
  );
  
  final failure = e.error as Failure? ?? NetworkFailure(...);
  return Result.failure(failure);
}
```

**That's it. No more logging.**

---

## STEP 2 Complete When:

✅ Crashlytics added (or Sentry)
✅ Test crash appears in console
✅ App still works normally
✅ No new bugs introduced

**THEN and ONLY THEN** → Move to Step 3

---

## Time Estimate

- Setup Firebase: 15 minutes
- Add crash logging: 10 minutes
- Test: 5 minutes

**Total: 30 minutes**

---

## Success Criteria

```
✅ Crashes are logged
✅ Can see crashes in console
✅ App still stable
✅ Ready for Step 3
```

**This is observability. Keep it minimal.**
