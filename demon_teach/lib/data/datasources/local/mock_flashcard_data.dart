import 'package:demon_teach/domain/entities/flashcard.dart';

/// Mock flashcard data for testing and development
class MockFlashcardData {
  /// Get mock flashcards for English lessons
  static List<Flashcard> getEnglishFlashcards(String lessonId) {
    return [
      Flashcard(
        id: 'fc_en_${lessonId}_1',
        lessonId: lessonId,
        frontText: 'Hello',
        backText: 'Xin chào',
        exampleUsage: 'Hello, how are you today?',
        audioUrl: 'https://example.com/audio/hello.mp3',
      ),
      Flashcard(
        id: 'fc_en_${lessonId}_2',
        lessonId: lessonId,
        frontText: 'Goodbye',
        backText: 'Tạm biệt',
        exampleUsage: 'Goodbye, see you tomorrow!',
        audioUrl: 'https://example.com/audio/goodbye.mp3',
      ),
      Flashcard(
        id: 'fc_en_${lessonId}_3',
        lessonId: lessonId,
        frontText: 'Thank you',
        backText: 'Cảm ơn',
        exampleUsage: 'Thank you very much for your help.',
        audioUrl: 'https://example.com/audio/thankyou.mp3',
      ),
      Flashcard(
        id: 'fc_en_${lessonId}_4',
        lessonId: lessonId,
        frontText: 'Please',
        backText: 'Làm ơn',
        exampleUsage: 'Please pass me the salt.',
        audioUrl: 'https://example.com/audio/please.mp3',
      ),
      Flashcard(
        id: 'fc_en_${lessonId}_5',
        lessonId: lessonId,
        frontText: 'Excuse me',
        backText: 'Xin lỗi',
        exampleUsage: 'Excuse me, where is the bathroom?',
        audioUrl: 'https://example.com/audio/excuseme.mp3',
      ),
    ];
  }

  /// Get mock flashcards for Chinese lessons
  static List<Flashcard> getChineseFlashcards(String lessonId) {
    return [
      Flashcard(
        id: 'fc_zh_${lessonId}_1',
        lessonId: lessonId,
        frontText: '你好 (Nǐ hǎo)',
        backText: 'Xin chào',
        exampleUsage: '你好，你好吗？(Hello, how are you?)',
        audioUrl: 'https://example.com/audio/nihao.mp3',
      ),
      Flashcard(
        id: 'fc_zh_${lessonId}_2',
        lessonId: lessonId,
        frontText: '再见 (Zàijiàn)',
        backText: 'Tạm biệt',
        exampleUsage: '再见，明天见！(Goodbye, see you tomorrow!)',
        audioUrl: 'https://example.com/audio/zaijian.mp3',
      ),
      Flashcard(
        id: 'fc_zh_${lessonId}_3',
        lessonId: lessonId,
        frontText: '谢谢 (Xièxiè)',
        backText: 'Cảm ơn',
        exampleUsage: '非常感谢你的帮助。(Thank you very much for your help.)',
        audioUrl: 'https://example.com/audio/xiexie.mp3',
      ),
      Flashcard(
        id: 'fc_zh_${lessonId}_4',
        lessonId: lessonId,
        frontText: '请 (Qǐng)',
        backText: 'Làm ơn',
        exampleUsage: '请给我盐。(Please pass me the salt.)',
        audioUrl: 'https://example.com/audio/qing.mp3',
      ),
      Flashcard(
        id: 'fc_zh_${lessonId}_5',
        lessonId: lessonId,
        frontText: '对不起 (Duìbùqǐ)',
        backText: 'Xin lỗi',
        exampleUsage: '对不起，洗手间在哪里？(Excuse me, where is the bathroom?)',
        audioUrl: 'https://example.com/audio/duibuqi.mp3',
      ),
    ];
  }

  /// Get mock flashcards for Korean lessons
  static List<Flashcard> getKoreanFlashcards(String lessonId) {
    return [
      Flashcard(
        id: 'fc_ko_${lessonId}_1',
        lessonId: lessonId,
        frontText: '안녕하세요 (Annyeonghaseyo)',
        backText: 'Xin chào',
        exampleUsage: '안녕하세요, 어떻게 지내세요? (Hello, how are you?)',
        audioUrl: 'https://example.com/audio/annyeong.mp3',
      ),
      Flashcard(
        id: 'fc_ko_${lessonId}_2',
        lessonId: lessonId,
        frontText: '안녕히 가세요 (Annyeonghi gaseyo)',
        backText: 'Tạm biệt',
        exampleUsage: '안녕히 가세요, 내일 봐요! (Goodbye, see you tomorrow!)',
        audioUrl: 'https://example.com/audio/annyeonghigaseyo.mp3',
      ),
      Flashcard(
        id: 'fc_ko_${lessonId}_3',
        lessonId: lessonId,
        frontText: '감사합니다 (Gamsahamnida)',
        backText: 'Cảm ơn',
        exampleUsage: '도와주셔서 감사합니다. (Thank you for your help.)',
        audioUrl: 'https://example.com/audio/gamsahamnida.mp3',
      ),
      Flashcard(
        id: 'fc_ko_${lessonId}_4',
        lessonId: lessonId,
        frontText: '주세요 (Juseyo)',
        backText: 'Làm ơn (cho tôi)',
        exampleUsage: '소금 주세요. (Please give me the salt.)',
        audioUrl: 'https://example.com/audio/juseyo.mp3',
      ),
      Flashcard(
        id: 'fc_ko_${lessonId}_5',
        lessonId: lessonId,
        frontText: '실례합니다 (Sillyehamnida)',
        backText: 'Xin lỗi',
        exampleUsage: '실례합니다, 화장실이 어디예요? (Excuse me, where is the bathroom?)',
        audioUrl: 'https://example.com/audio/sillyehamnida.mp3',
      ),
    ];
  }

  /// Get flashcards based on target language
  static List<Flashcard> getFlashcardsForLanguage(
    String lessonId,
    String targetLanguage,
  ) {
    switch (targetLanguage.toLowerCase()) {
      case 'en':
      case 'english':
        return getEnglishFlashcards(lessonId);
      case 'zh':
      case 'chinese':
        return getChineseFlashcards(lessonId);
      case 'ko':
      case 'korean':
        return getKoreanFlashcards(lessonId);
      default:
        return getEnglishFlashcards(lessonId);
    }
  }
}
