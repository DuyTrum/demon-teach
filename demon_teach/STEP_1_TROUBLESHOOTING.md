# 🔧 Step 1 Troubleshooting Guide

## Current Situation

**App launch status**: Chrome is taking longer than expected to connect (24+ seconds)

---

## Option 1: Wait for Chrome (Recommended)

**What's happening**: Flutter is building the web app and starting Chrome. First launch can take 30-60 seconds.

**Action**: Wait a bit longer. Chrome window should open automatically.

**Expected**: Chrome window opens with your app running.

---

## Option 2: Enable Windows Developer Mode

If you prefer testing on Windows desktop instead of Chrome:

### Steps:
1. Press `Windows + I` to open Settings
2. Go to "Privacy & Security" → "For developers"
3. Enable "Developer Mode"
4. Restart the Flutter app with: `flutter run -d windows`

### Benefits:
- Native Windows app (faster)
- Better performance
- More realistic testing

---

## Option 3: Use Edge Browser

If Chrome is having issues:

```bash
cd demon_teach
flutter run -d edge
```

Edge is similar to Chrome but might work better on your system.

---

## Option 4: Check for Blockers

### Check if Chrome is blocked:
1. Look for Chrome window in taskbar
2. Check if antivirus is blocking Chrome
3. Check if firewall is blocking Flutter

### Check Flutter doctor:
```bash
flutter doctor -v
```

This shows if there are any Flutter configuration issues.

---

## Current Process Status

**Terminal ID**: 4
**Command**: `flutter run -d chrome`
**Status**: Waiting for debug service connection
**Time elapsed**: 24+ seconds

---

## What to Do Right Now

### If Chrome window opened:
✅ Great! Proceed with manual testing checklist in `STEP_1_MANUAL_TEST_PROGRESS.md`

### If Chrome hasn't opened after 60 seconds:
1. Stop the process (Ctrl+C in terminal)
2. Try Option 2 (Enable Developer Mode) OR Option 3 (Use Edge)
3. If still failing, run `flutter doctor -v` to diagnose

### If you see errors in terminal:
1. Copy the error message
2. Check common issues below
3. Fix and retry

---

## Common Issues & Fixes

### Issue: "Chrome not found"
**Fix**: Install Google Chrome or use Edge instead

### Issue: "Port already in use"
**Fix**: 
```bash
flutter run -d chrome --web-port=8081
```

### Issue: "Build failed"
**Fix**: 
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Issue: "Timeout waiting for connection"
**Fix**: 
- Close all Chrome windows
- Disable Chrome extensions
- Try Edge instead

---

## Success Indicators

### App launched successfully when you see:
```
✓ Built build\web
✓ Launching lib\main.dart on Chrome in debug mode...
✓ Debug service listening on ws://...
```

### In Chrome window:
- App UI appears
- No error messages
- Can interact with UI

---

## Next Steps After Successful Launch

1. **Complete manual testing** (8 tests in progress file)
2. **Document any issues** found during testing
3. **Fix issues** before proceeding
4. **Build release APK** when all tests pass
5. **Move to Step 2** only after Step 1 complete

---

## Important Reminders

**Rule**: Stabilize → Observe → Enrich

**Do NOT**:
- Skip tests if app is slow
- Ignore crashes or errors
- Proceed to Step 2 if issues found
- Add new features or code

**Do ONLY**:
- Follow the checklist
- Document everything
- Fix issues properly
- Verify stability

---

## Need Help?

If stuck for more than 5 minutes:
1. Stop current process
2. Run `flutter doctor -v`
3. Try alternative device (Edge or Windows with Dev Mode)
4. Check Flutter logs for specific errors

