# Demon Teach - Complete Flow Test Guide

## App URL
**Chrome:** http://127.0.0.1:58360/ELtd_Zk_xpc=

## Complete User Flow Test

### Phase 1: Language Selection (Requirement 1)
**Screen:** Language Selection Screen

**Steps:**
1. ✅ App should open to Language Selection screen (first time user)
2. ✅ Select **Target Language**: English, Chinese, or Korean
3. ✅ Select **Native Language**: Vietnamese, English, Chinese, or Korean
4. ✅ Click **Continue** button

**Expected Result:**
- Both languages must be selected before Continue button is enabled
- Navigate to Assessment Screen

---

### Phase 2: Proficiency Assessment (Requirement 2)
**Screen:** Assessment Screen

**Steps:**
1. ✅ See assessment introduction with 10 questions
2. ✅ Answer each question by selecting one of 4 options
3. ✅ Progress bar updates after each question
4. ✅ Complete all 10 questions
5. ✅ Click **Submit Assessment** button

**Expected Result:**
- Questions are displayed one by one
- Progress bar shows X/10 questions
- After submission, see Assessment Result Screen with proficiency level:
  - **Basic** (< 45% score)
  - **Intermediate** (45-74% score)
  - **Advanced** (≥ 75% score)
- Navigate to Goal Configuration Screen

**Test Scenarios:**
- Answer 0-4 questions correctly → Basic
- Answer 5-7 questions correctly → Intermediate
- Answer 8-10 questions correctly → Advanced

---

### Phase 3: Learning Goal Configuration (Requirement 3)
**Screen:** Goal Configuration Screen

**Steps:**
1. ✅ See 5 goal types with icons and descriptions:
   - 💬 Conversation
   - 📝 Exam Preparation
   - 💼 Work/Business
   - ✈️ Travel
   - 🎨 Hobby/Interest
2. ✅ Select one goal type (card highlights in blue)
3. ✅ Adjust daily study time slider (5-30 minutes)
4. ✅ See time recommendation based on selected minutes
5. ✅ Click **Continue** button

**Expected Result:**
- Goal must be selected before Continue button is enabled
- Slider shows current value (default: 15 minutes)
- Recommendation text changes based on slider value:
  - < 10 min: "Perfect for busy schedules!"
  - 10-19 min: "Great balance!"
  - ≥ 20 min: "Ambitious!"
- Navigate to Learning Path Screen

---

### Phase 4: Learning Path Generation (Requirements 4, 13)
**Screen:** Learning Path Screen

**Steps:**
1. ✅ See learning path overview card with:
   - Target language (e.g., "Learning ENGLISH")
   - Proficiency level (Basic/Intermediate/Advanced)
   - Goal type (e.g., "Conversation")
2. ✅ See statistics:
   - Total Lessons: 10
   - Completed: 0
   - Remaining: 10
3. ✅ See overall progress bar (0%)
4. ✅ See lesson list with:
   - Lesson numbers and names
   - Current lesson highlighted in blue
   - Completed lessons with green checkmark
5. ✅ Click **Start Learning** button

**Expected Result:**
- Learning path is generated based on:
  - Proficiency level (basic/intermediate/advanced)
  - Goal type (prioritizes relevant lessons)
- First lesson is marked as "Current"
- Navigate to Daily Lesson Screen

**Lesson ID Format:**
- `{language}_{level}_{category}_{number}`
- Example: `en_basic_vocab_001` = English, Basic, Vocabulary, Lesson 1

---

### Phase 5: Daily Lesson (Requirement 5)
**Screen:** Daily Lesson Screen

**Steps:**
1. ✅ See lesson header with:
   - Category icon (📚 Vocabulary, 📝 Grammar, etc.)
   - Lesson title (e.g., "Basic Greetings")
   - Category and difficulty level
2. ✅ See progress bar showing "Section X of Y"
3. ✅ See timer in app bar (MM:SS format)
4. ✅ Complete each section:

   **Vocabulary Section:**
   - See vocabulary cards with:
     - Word in target language
     - Pronunciation (IPA)
     - Translation
     - Audio button (🔊)
   - Click audio button to hear pronunciation (placeholder)

   **Practice Section:**
   - See practice questions
   - Click answer options
   - Get immediate feedback (Correct ✓ or Try again)

   **Explanation Section:**
   - Read grammar/concept explanations

   **Examples Section:**
   - See numbered example sentences

5. ✅ Click **Next** to move to next section
6. ✅ Click **Previous** to go back (if not first section)
7. ✅ On last section, click **Complete Lesson**

**Expected Result:**
- Progress bar updates with each section
- Timer counts up continuously
- Navigation buttons work correctly
- Content displays properly for each section type
- Navigate to Lesson Completion Screen

---

### Phase 6: Lesson Completion (Requirement 5)
**Screen:** Lesson Completion Screen

**Steps:**
1. ✅ See success animation (green checkmark with scale effect)
2. ✅ See "Lesson Complete!" message
3. ✅ See stats card with:
   - **Score:** 100 (for completing all sections)
   - **Time:** Elapsed time (e.g., "2 min 30s")
   - **XP:** Calculated XP (50 + score/2 = 100 XP)
4. ✅ See lesson info summary with completion checkmark
5. ✅ Click **Continue Learning** button

**Expected Result:**
- Lesson is marked as completed in background
- Learning path progress is updated (currentLessonIndex++)
- Navigate back to Learning Path Screen
- Next lesson is now marked as "Current"

**Alternative:**
- Click **Review Lesson** to go back to lesson screen

---

### Phase 7: Verify Progress
**Screen:** Learning Path Screen (after completing lesson)

**Steps:**
1. ✅ See updated statistics:
   - Completed: 1
   - Remaining: 9
2. ✅ See updated progress bar (10%)
3. ✅ See lesson list with:
   - First lesson has green checkmark (completed)
   - Second lesson is now "Current" (blue highlight)
4. ✅ Click **Start Learning** again to continue with next lesson

**Expected Result:**
- Progress is persisted (survives page refresh)
- Can continue learning from where left off
- Each completed lesson advances to next lesson

---

## Test Scenarios

### Scenario 1: Complete Beginner Flow
1. Select English as target language
2. Answer 0-4 questions correctly → Basic level
3. Select "Conversation" goal, 10 minutes/day
4. Complete first lesson: "Basic Greetings"
5. Verify progress updated

### Scenario 2: Intermediate Learner Flow
1. Select Chinese as target language
2. Answer 5-7 questions correctly → Intermediate level
3. Select "Work/Business" goal, 20 minutes/day
4. Complete first lesson
5. Verify different lesson content for intermediate level

### Scenario 3: Advanced Learner Flow
1. Select Korean as target language
2. Answer 8-10 questions correctly → Advanced level
3. Select "Exam Preparation" goal, 30 minutes/day
4. Complete first lesson
5. Verify advanced lesson content

---

## Known Features & Limitations

### ✅ Implemented Features:
- Language selection with validation
- 10-question proficiency assessment with scoring
- Goal configuration with 5 goal types
- Learning path generation (10 lessons per path)
- Lesson delivery with 4 section types
- Progress tracking and persistence
- Timer and duration tracking
- Lesson completion with XP calculation
- Auto-advance to next lesson

### 🚧 Coming Soon (Placeholders):
- Audio pronunciation playback (shows toast message)
- Path modification interface
- Multiple lesson types (currently vocabulary/grammar focus)
- Spaced repetition system
- Achievement system
- User authentication (currently uses hardcoded user_001)

---

## Troubleshooting

### Issue: App shows "Welcome back!" instead of Language Selection
**Solution:** Clear browser local storage:
1. Open Chrome DevTools (F12)
2. Go to Application tab
3. Clear Storage → Clear site data
4. Refresh page

### Issue: Progress not saving
**Solution:** Check browser console for errors. SharedPreferences should work in Chrome.

### Issue: Lesson content not loading
**Solution:** Check that mock data is properly loaded. Restart app if needed.

---

## Success Criteria

✅ **Complete Flow Test Passed If:**
1. Can select language and proceed
2. Can complete assessment and see correct proficiency level
3. Can configure goals and proceed
4. Can see generated learning path with 10 lessons
5. Can start and complete a lesson
6. Can see completion screen with stats
7. Progress is updated correctly
8. Can continue to next lesson
9. All data persists across screens
10. No errors in console

---

## Next Steps After Testing

If all tests pass:
1. ✅ Phase 2 Core Learning Features - COMPLETE
2. 🚧 Phase 3: Advanced Features (Flashcards, Quizzes, Spaced Repetition)
3. 🚧 Phase 4: Content Management
4. 🚧 Phase 5: Offline & Sync
5. 🚧 Phase 6: Polish & Testing
6. 🚧 Phase 7: Deployment

---

**Happy Testing! 🎉**

Report any issues or unexpected behavior for fixes.
