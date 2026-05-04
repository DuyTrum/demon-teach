# 📚 STEP 3: Real HSK Data (ONLY WHEN STABLE)

## Rule: Import data, map to entities, test offline

**NOT**: Build complex data pipeline ❌
**YES**: Simple import → store → read ✅

---

## Prerequisites

✅ Step 1 complete (app stable)
✅ Step 2 complete (crashes logged)

---

## What to Do (SIMPLE)

### 3.1 Download HSK JSON (1 command)

```bash
# Create assets directory
mkdir -p demon_teach/assets/data

# Download HSK vocabulary
curl -o demon_teach/assets/data/hsk_complete.json \
  https://raw.githubusercontent.com/drkameleon/complete-hsk-vocabulary/main/complete.min.json
```

### 3.2 Add to pubspec.yaml

```yaml
flutter:
  assets:
    - assets/data/hsk_complete.json
```

### 3.3 Create Simple Data Model

```dart
// lib/domain/entities/hsk_word.dart
class HskWord {
  final String simplified;
  final String pinyin;
  final String meaning;
  final String level;
  
  HskWord({
    required this.simplified,
    required this.pinyin,
    required this.meaning,
    required this.level,
  });
  
  // Simple parser - just get what we need
  factory HskWord.fromJson(Map<String, dynamic> json) {
    final form = json['f'][0];
    final transcription = form['i'];
    final meanings = form['m'] as List;
    final levels = json['l'] as List;
    
    return HskWord(
      simplified: json['s'],
      pinyin: transcription['y'],
      meaning: meanings.first, // Just first meaning
      level: levels.first,     // Just first level
    );
  }
}
```

### 3.4 Load and Store (SIMPLE)

```dart
// lib/data/datasources/local/hsk_loader.dart
class HskLoader {
  static Future<List<HskWord>> loadWords() async {
    // Load JSON
    final jsonString = await rootBundle.loadString(
      'assets/data/hsk_complete.json',
    );
    
    // Parse
    final List<dynamic> jsonList = json.decode(jsonString);
    
    // Convert (take first 100 for testing)
    return jsonList
        .take(100)
        .map((json) => HskWord.fromJson(json))
        .toList();
  }
}
```

### 3.5 Create Lessons from HSK Words

```dart
// Simple lesson generator
class SimpleHskLessonGenerator {
  Future<Lesson> generateLesson(int lessonNumber) async {
    // Load words
    final words = await HskLoader.loadWords();
    
    // Take 10 words for this lesson
    final startIndex = (lessonNumber - 1) * 10;
    final lessonWords = words.skip(startIndex).take(10).toList();
    
    // Create flashcards
    final flashcards = lessonWords.map((word) => Flashcard(
      id: 'fc_${word.simplified}',
      front: word.simplified,
      back: word.meaning,
      hint: word.pinyin,
    )).toList();
    
    return Lesson(
      id: 'hsk_lesson_$lessonNumber',
      title: 'HSK Lesson $lessonNumber',
      flashcards: flashcards,
      quiz: Quiz(id: 'quiz_$lessonNumber', questions: []),
    );
  }
}
```

### 3.6 Test Offline (CRITICAL)

```dart
// Test that HSK data works offline
test('HSK data loads from assets', () async {
  final words = await HskLoader.loadWords();
  
  expect(words.isNotEmpty, true);
  expect(words.first.simplified, isNotEmpty);
  expect(words.first.pinyin, isNotEmpty);
  expect(words.first.meaning, isNotEmpty);
});

test('Can generate lesson from HSK data', () async {
  final generator = SimpleHskLessonGenerator();
  final lesson = await generator.generateLesson(1);
  
  expect(lesson.flashcards.length, 10);
  expect(lesson.flashcards.first.front, isNotEmpty);
});
```

---

## What NOT to Do

❌ Complex data pipeline
❌ Multiple data sources
❌ Data transformation layers
❌ Caching strategies
❌ Background sync
❌ Data validation
❌ Schema migration

**Why?** Keep it simple. Just load → store → read.

---

## Manual Test

```
1. Run app
2. Navigate to lessons
3. See Chinese characters
4. See pinyin
5. See English meanings
6. Complete a lesson
7. Turn on airplane mode
8. Restart app
9. Verify data still there
```

**If ANY fails** → Fix before moving forward

---

## STEP 3 Complete When:

✅ HSK JSON downloaded
✅ Data loads from assets
✅ Lessons show Chinese words
✅ Works offline
✅ Tests pass

**THEN** → You have MVP with real data

---

## Time Estimate

- Download data: 5 minutes
- Create models: 30 minutes
- Create loader: 20 minutes
- Test: 15 minutes

**Total: 70 minutes**

---

## Success Criteria

```
✅ Real Chinese words in app
✅ Pinyin displays correctly
✅ Works offline
✅ No crashes
✅ Ready to ship
```

**This is real data. Keep it simple.**

---

## After Step 3: You're Done

**You now have**:
- ✅ Stable app (Step 1)
- ✅ Crash logging (Step 2)
- ✅ Real HSK data (Step 3)

**You can ship this.**

**Future improvements** (LATER, not now):
- More HSK levels
- Better quiz generation
- Spaced repetition
- Progress tracking
- Analytics

**But not now. Ship first.**
