# 🎯 Step 1: Manual Smoke Test Progress

**Date**: April 28, 2026
**Status**: IN PROGRESS

---

## Automated Tests ✅

```
✅ 117 tests passing
✅ flutter clean completed
✅ flutter pub get completed
✅ All unit tests pass
✅ All integration tests pass
```

---

## Manual Smoke Test Checklist

**App launched**: `flutter run -d windows`

### Core Functionality Tests

```
[ ] 1. App launches without crash
    - Launch app on Windows desktop
    - Verify splash screen appears
    - Verify no error dialogs
    - Verify app reaches main screen

[ ] 2. Can navigate to lesson screen
    - From test menu, select "Daily Lesson"
    - Verify lesson screen loads
    - Verify no navigation errors

[ ] 3. Can view flashcards
    - Navigate to flashcard screen
    - Verify flashcards display
    - Verify can swipe/navigate cards
    - Verify front/back flip works

[ ] 4. Can complete quiz
    - Navigate to quiz screen
    - Answer quiz questions
    - Verify score calculation
    - Verify completion screen

[ ] 5. Can download lesson (with mock data)
    - Trigger download flow
    - Verify progress indicator
    - Verify completion message
    - Verify data stored locally

[ ] 6. Can sync progress (with mock data)
    - Complete some activities
    - Trigger sync
    - Verify sync progress
    - Verify sync completion

[ ] 7. Offline mode works (airplane mode test)
    - Disconnect network
    - Launch app
    - Verify app works offline
    - Verify cached data accessible
    - Reconnect network

[ ] 8. App restart preserves data
    - Complete some activities
    - Close app completely
    - Reopen app
    - Verify data persisted
    - Verify progress saved
```

---

## Issues Found

### Issue 1: Windows Developer Mode Required
- **Error**: "Building with plugins requires symlink support"
- **Solution**: Enable Developer Mode OR use Chrome/Edge for testing
- **Status**: Using Chrome as alternative
- **Impact**: Low - Chrome testing is sufficient for Step 1

---

## Next Steps After Manual Test

1. **If all tests pass**:
   - Build release APK: `flutter build apk --release`
   - Test release build on device
   - Mark Step 1 complete
   - Move to Step 2

2. **If any test fails**:
   - Document the failure
   - Fix the issue
   - Re-run all tests
   - Do NOT proceed to Step 2

---

## Commands Reference

### Launch App (Windows)
```bash
cd demon_teach
flutter run -d windows
```

### Launch App (Chrome - for web testing)
```bash
cd demon_teach
flutter run -d chrome
```

### Build Release APK
```bash
cd demon_teach
flutter build apk --release
```

### Install Release Build
```bash
flutter install --release
```

---

## Testing Notes

- **Current device**: Windows desktop
- **Flutter version**: Check with `flutter --version`
- **Test environment**: Development machine
- **Network**: Connected (will test offline mode separately)

---

## Step 1 Success Criteria

```
✅ All 117 automated tests pass
[ ] All 8 manual smoke tests pass
[ ] Release build succeeds
[ ] Release build works on device
[ ] No crashes
[ ] Data persists after restart
```

**When all criteria met** → Step 1 COMPLETE → Move to Step 2

---

## Important Reminders

❌ **Do NOT**:
- Add new features
- Add Firebase
- Add HSK data
- Refactor code
- Skip any test

✅ **Do ONLY**:
- Follow checklist
- Document issues
- Fix issues if found
- Verify stability

**Rule**: Stabilize → Observe → Enrich

