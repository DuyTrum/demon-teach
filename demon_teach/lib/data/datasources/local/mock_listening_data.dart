import 'package:demon_teach/domain/entities/listening_exercise.dart';

/// Mock listening exercise data for testing
class MockListeningData {
  /// Get listening exercise for a specific language
  static ListeningExercise getListeningExerciseForLanguage(
    String lessonId,
    String targetLanguage,
  ) {
    switch (targetLanguage) {
      case 'en':
        return _getEnglishListeningExercise(lessonId);
      case 'zh':
        return _getChineseListeningExercise(lessonId);
      case 'ko':
        return _getKoreanListeningExercise(lessonId);
      default:
        return _getEnglishListeningExercise(lessonId);
    }
  }

  static ListeningExercise _getEnglishListeningExercise(String lessonId) {
    return ListeningExercise(
      id: 'listening_en_$lessonId',
      lessonId: lessonId,
      audioUrl: 'https://example.com/audio/en_conversation_1.mp3',
      durationSeconds: 45,
      questions: [
        const ComprehensionQuestion(
          id: 'q1',
          questionText: 'What is the main topic of the conversation?',
          options: [
            'Ordering food at a restaurant',
            'Asking for directions',
            'Making a hotel reservation',
            'Shopping for clothes',
          ],
          correctAnswer: 'Ordering food at a restaurant',
          explanation:
              'The conversation is about ordering food at a restaurant. The speakers discuss menu items and place an order.',
        ),
        const ComprehensionQuestion(
          id: 'q2',
          questionText: 'What does the customer order?',
          options: [
            'Pizza and salad',
            'Burger and fries',
            'Pasta and soup',
            'Sandwich and coffee',
          ],
          correctAnswer: 'Pasta and soup',
          explanation:
              'The customer orders pasta as the main dish and soup as a starter.',
        ),
        const ComprehensionQuestion(
          id: 'q3',
          questionText: 'How does the customer want the pasta cooked?',
          options: [
            'Well done',
            'Medium',
            'Al dente',
            'Extra soft',
          ],
          correctAnswer: 'Al dente',
          explanation:
              'The customer specifically requests the pasta to be cooked al dente, which means firm to the bite.',
        ),
        const ComprehensionQuestion(
          id: 'q4',
          questionText: 'What drink does the customer order?',
          options: [
            'Water',
            'Wine',
            'Juice',
            'Soda',
          ],
          correctAnswer: 'Wine',
          explanation:
              'The customer orders a glass of red wine to accompany the meal.',
        ),
        const ComprehensionQuestion(
          id: 'q5',
          questionText: 'How long will the food take to prepare?',
          options: [
            '10 minutes',
            '15 minutes',
            '20 minutes',
            '30 minutes',
          ],
          correctAnswer: '20 minutes',
          explanation:
              'The waiter mentions that the food will be ready in approximately 20 minutes.',
        ),
      ],
    );
  }

  static ListeningExercise _getChineseListeningExercise(String lessonId) {
    return ListeningExercise(
      id: 'listening_zh_$lessonId',
      lessonId: lessonId,
      audioUrl: 'https://example.com/audio/zh_conversation_1.mp3',
      durationSeconds: 40,
      questions: [
        const ComprehensionQuestion(
          id: 'q1',
          questionText: '对话的主要内容是什么？',
          options: [
            '问路',
            '购物',
            '点餐',
            '预订酒店',
          ],
          correctAnswer: '点餐',
          explanation: '对话主要是关于在餐厅点餐的内容。',
        ),
        const ComprehensionQuestion(
          id: 'q2',
          questionText: '顾客点了什么菜？',
          options: [
            '宫保鸡丁',
            '麻婆豆腐',
            '糖醋里脊',
            '鱼香肉丝',
          ],
          correctAnswer: '宫保鸡丁',
          explanation: '顾客点了宫保鸡丁作为主菜。',
        ),
        const ComprehensionQuestion(
          id: 'q3',
          questionText: '顾客要求菜品的辣度是？',
          options: [
            '不辣',
            '微辣',
            '中辣',
            '特辣',
          ],
          correctAnswer: '微辣',
          explanation: '顾客要求菜品做成微辣的。',
        ),
        const ComprehensionQuestion(
          id: 'q4',
          questionText: '顾客点了什么饮料？',
          options: [
            '茶',
            '啤酒',
            '果汁',
            '可乐',
          ],
          correctAnswer: '茶',
          explanation: '顾客点了一壶茶。',
        ),
      ],
    );
  }

  static ListeningExercise _getKoreanListeningExercise(String lessonId) {
    return ListeningExercise(
      id: 'listening_ko_$lessonId',
      lessonId: lessonId,
      audioUrl: 'https://example.com/audio/ko_conversation_1.mp3',
      durationSeconds: 35,
      questions: [
        const ComprehensionQuestion(
          id: 'q1',
          questionText: '대화의 주요 내용은 무엇입니까?',
          options: [
            '길 찾기',
            '쇼핑',
            '음식 주문',
            '호텔 예약',
          ],
          correctAnswer: '음식 주문',
          explanation: '대화는 식당에서 음식을 주문하는 내용입니다.',
        ),
        const ComprehensionQuestion(
          id: 'q2',
          questionText: '손님이 주문한 음식은?',
          options: [
            '비빔밥',
            '불고기',
            '김치찌개',
            '냉면',
          ],
          correctAnswer: '비빔밥',
          explanation: '손님은 비빔밥을 주문했습니다.',
        ),
        const ComprehensionQuestion(
          id: 'q3',
          questionText: '손님이 요청한 매운 정도는?',
          options: [
            '안 맵게',
            '조금 맵게',
            '보통',
            '아주 맵게',
          ],
          correctAnswer: '조금 맵게',
          explanation: '손님은 조금 맵게 해달라고 요청했습니다.',
        ),
        const ComprehensionQuestion(
          id: 'q4',
          questionText: '손님이 주문한 음료는?',
          options: [
            '물',
            '소주',
            '맥주',
            '콜라',
          ],
          correctAnswer: '맥주',
          explanation: '손님은 맥주를 주문했습니다.',
        ),
      ],
    );
  }
}
