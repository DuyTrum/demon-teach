# 🔥 Firebase Crashlytics Test Guide

**Date**: April 28, 2026
**Purpose**: Test Firebase Crashlytics integration

---

## Test Buttons Added

In **Test Menu Screen**, you'll see a new red section: **"Firebase Crashlytics Test"**

### Button 1: Log Error (Orange)

**What it does**: Logs a non-fatal error to Firebase

**Expected behavior**:
- Shows orange snackbar: "Non-fatal error logged!"
- App continues running normally
- Error appears in Firebase Console in 5 minutes

**Use case**: Test error logging without crashing app

### Button 2: Force Crash (Red)

**What it does**: Crashes the app intentionally

**Expected behavior**:
- Shows confirmation dialog
- If confirmed, app crashes immediately
- Crash report appears in Firebase Console in 5-10 minutes

**Use case**: Test fatal crash reporting

---

## How to Test

### Step 1: Run the App

App is launching on Chrome right now. Wait for Chrome window to open.

### Step 2: Navigate to Test Menu

- App should open to Test Menu automatically
- Scroll down to see **"Firebase Crashlytics Test"** section (red card)

### Step 3: Test Non-Fatal Error

1. Click **"Log Error"** button (orange)
2. See snackbar confirmation
3. App continues running normally
4. ✅ Non-fatal error logged

### Step 4: Test Fatal Crash (Optional)

1. Click **"Force Crash"** button (red)
2. Confirm in dialog
3. App crashes
4. Reopen app
5. ✅ Crash report logged

### Step 5: Verify in Firebase Console

1. Wait 5-10 minutes (Firebase processes crashes in batches)
2. Go to: https://console.firebase.google.com/project/demon-teach/crashlytics
3. Refresh page
4. See crash reports appear

---

## What to Look For

### In Firebase Console:

**Non-Fatal Errors**:
- Error type: `Exception`
- Message: "Test non-fatal error from Demon Teach"
- Reason: "Testing Crashlytics non-fatal error"
- Stack trace included

**Fatal Crashes**:
- Error type: `Exception`
- Message: "Test fatal crash from Demon Teach"
- Stack trace included
- Device info (browser, OS)

---

## Expected Results

### ✅ Success Criteria:

1. **App launches** without Firebase initialization errors
2. **Test buttons appear** in Test Menu (debug mode only)
3. **Log Error works** - shows snackbar, app continues
4. **Force Crash works** - app crashes as expected
5. **Errors appear in Firebase Console** within 10 minutes

### ❌ Failure Indicators:

- App crashes on launch → Firebase initialization issue
- Buttons don't appear → kDebugMode check issue
- Errors don't appear in Console → Firebase project misconfigured

---

## Troubleshooting

### Issue: App crashes on launch

**Possible causes**:
- Firebase not initialized properly
- Missing firebase_options.dart

**Fix**:
```bash
cd demon_teach
flutter clean
flutter pub get
flutter run -d chrome
```

### Issue: Errors don't appear in Console

**Possible causes**:
- Need to wait longer (up to 10 minutes)
- Firebase project not selected correctly
- Network issues

**Fix**:
- Wait 10 minutes and refresh
- Check Firebase project ID matches
- Check internet connection

### Issue: Buttons don't show

**Possible causes**:
- Running in release mode
- kDebugMode is false

**Fix**:
- Ensure running in debug mode: `flutter run -d chrome` (not `--release`)

---

## Debug Mode Only

**Important**: Crashlytics test buttons only appear in **debug mode**.

**Why?**
- Production users shouldn't see crash test buttons
- `if (kDebugMode)` ensures buttons only show during development

**To verify debug mode**:
- Look for "Debug" banner in top-right corner of app
- Test buttons should be visible

---

## Firebase Console Links

**Main Crashlytics Dashboard**:
```
https://console.firebase.google.com/project/demon-teach/crashlytics
```

**Project Overview**:
```
https://console.firebase.google.com/project/demon-teach/overview
```

---

## After Testing

### If tests pass:

✅ **Step 2 VERIFIED** - Crashlytics working correctly

**Next steps**:
1. Remove test buttons (or keep for future debugging)
2. Move to **Step 3: Real HSK Data**

### If tests fail:

❌ **Debug issues** before proceeding

**Actions**:
1. Check Firebase initialization in main.dart
2. Verify firebase_options.dart exists
3. Check Firebase Console for project status
4. Re-run flutterfire configure if needed

---

## Production Considerations

### Before shipping to production:

**Option 1: Remove test buttons**
- Delete `_buildCrashlyticsTestSection` method
- Remove from ListView

**Option 2: Keep test buttons (Recommended)**
- Already hidden in release mode
- Useful for debugging production issues
- No impact on end users

**Recommendation**: Keep the buttons - they're already protected by `kDebugMode`

---

## Time Estimate

- Launch app: 1 minute
- Test non-fatal error: 30 seconds
- Test fatal crash: 30 seconds
- Wait for Firebase: 5-10 minutes
- Verify in Console: 1 minute

**Total: ~12 minutes**

---

## Success Confirmation

When you see crashes in Firebase Console:

✅ **Step 2 COMPLETE**
✅ **Crashlytics working**
✅ **Ready for Step 3**

---

## Notes

- Crashes are batched and processed every few minutes
- First crash may take longer to appear (up to 10 minutes)
- Subsequent crashes appear faster (2-5 minutes)
- Non-fatal errors appear in "Non-fatals" tab
- Fatal crashes appear in "Crashes" tab

