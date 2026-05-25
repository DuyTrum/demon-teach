// Type definitions for Demon Teach Admin Portal

export interface User {
  id: string;
  email: string;
  role: 'user' | 'admin';
}

export interface AuthResponse {
  success: boolean;
  message: string;
  data: {
    user: User;
    accessToken: string;
    refreshToken: string;
  };
}

export interface Lesson {
  id: string;
  title: string;
  difficulty: 'beginner' | 'elementary' | 'intermediate' | 'upperIntermediate' | 'advanced';
  category: 'vocabulary' | 'grammar' | 'listening' | 'speaking' | 'reading' | 'writing';
  topic: string;
  targetLanguage: 'en' | 'zh' | 'ko';
  durationEstimate: number;
  version: number;
  content: LessonContent;
  isPublished: boolean;
  publishedAt?: string;
  createdBy?: string;
  updatedBy?: string;
  createdAt: string;
  updatedAt: string;
}

export interface LessonContent {
  flashcards: Flashcard[];
  quiz: Quiz;
  listeningExercise?: ListeningExercise;
  speakingExercise?: SpeakingExercise;
}

export interface Flashcard {
  id: string;
  lessonId: string;
  frontText: string;
  backText: string;
  exampleUsage: string;
  audioUrl?: string;
}

export interface Quiz {
  id: string;
  lessonId: string;
  title: string;
  questions: QuizQuestion[];
}

export interface QuizQuestion {
  id: string;
  type: 'multipleChoice' | 'fillInBlank' | 'matching' | 'trueFalse';
  questionText: string;
  options?: string[];
  correctAnswer: string;
  explanation?: string;
}

export interface ListeningExercise {
  id: string;
  lessonId: string;
  audioUrl: string;
  durationSeconds: number;
  questions: ComprehensionQuestion[];
}

export interface ComprehensionQuestion {
  questionText: string;
  options: string[];
  correctAnswer: string;
  explanation?: string;
}

export interface SpeakingExercise {
  id: string;
  lessonId: string;
  phrase: string;
  modelAudioUrl: string;
}

export interface LessonVersion {
  id: string;
  lessonId: string;
  version: number;
  title: string;
  difficulty: string;
  category: string;
  topic: string;
  targetLanguage: string;
  durationEstimate: number;
  changeDescription?: string;
  createdBy?: string;
  createdAt: string;
}

export interface PaginationData {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data?: T;
  errors?: string[];
}

export interface LessonListResponse {
  lessons: Lesson[];
  pagination: PaginationData;
}

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}
