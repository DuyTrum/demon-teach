# 🎯 STEP 1: Ship Safety First (BẮT BUỘC)

## Rule: "Stabilize → Observe → Enrich"

**NOT**: Build everything → hope it works ❌
**YES**: Reduce unknowns one by one ✅

---

## Current Status ✅

```
✅ 117 tests passing
✅ Dio network layer complete
✅ Offline-first architecture working
✅ Integration tests enabled
```

**This is STABLE foundation.**

---

## STEP 1: Verify End-to-End (NO NEW CODE)

### 1.1 Manual Smoke Test Checklist

**Run app and verify**:

```
[ ] App launches without crash
[ ] Can navigate to lesson screen
[ ] Can view flashcards
[ ] Can complete quiz
[ ] Can download lesson (with mock data)
[ ] Can sync progress (with mock data)
[ ] Offline mode works (airplane mode test)
[ ] App restart preserves data
```

**If ANY fails** → Fix before moving forward

### 1.2 Build Release APK

```bash
cd demon_teach
flutter build apk --release
```

**Check**:
```
[ ] Build succeeds
[ ] APK size reasonable (<50MB)
[ ] No build warnings
```

### 1.3 Test Release Build

```bash
# Install on real device
flutter install --release

# Test on device
- Launch app
- Complete one lesson
- Close app
- Reopen app
- Verify data persisted
```

**If crashes or data loss** → Fix before moving forward

---

## STEP 1 Complete When:

✅ All 117 tests pass
✅ Manual smoke test passes
✅ Release build works
✅ No crashes on real device
✅ Data persists after restart

**THEN and ONLY THEN** → Move to Step 2

---

## What NOT to Do Right Now

❌ Add Firebase
❌ Add HSK data
❌ Add monitoring dashboard
❌ Add new features
❌ Refactor code
❌ Optimize performance

**Why?** Each adds unknowns. Stabilize first.

---

## If Issues Found

### Issue: App crashes on launch
**Fix**: Check main.dart initialization
**Test**: Run debug build, check logs
**Verify**: Release build works

### Issue: Data doesn't persist
**Fix**: Check DatabaseProvider
**Test**: Run integration tests
**Verify**: Manual test on device

### Issue: Network calls fail
**Fix**: Check API_BASE_URL
**Test**: Run datasource smoke tests
**Verify**: Mock responses work

---

## Next Steps (After Step 1 Complete)

**ONLY after Step 1 passes**:
→ Move to STEP 2: Minimal Observability

**NOT before.**

---

## Time Estimate

- Manual testing: 30 minutes
- Build release: 10 minutes
- Device testing: 20 minutes

**Total: 1 hour**

If takes longer → something is broken, fix it.

---

## Success Criteria

```
✅ App is stable
✅ No crashes
✅ Data persists
✅ Offline works
✅ Ready for Step 2
```

**This is the foundation. Don't skip it.**
