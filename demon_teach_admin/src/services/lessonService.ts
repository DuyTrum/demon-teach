import { api } from './api';
import {
  Lesson,
  LessonContent,
  LessonListResponse,
  LessonVersion,
  ApiResponse,
  ValidationResult,
} from '../types';

export const lessonService = {
  async getLessons(params: {
    page?: number;
    limit?: number;
    targetLanguage?: string;
    difficulty?: string;
    topic?: string;
    isPublished?: boolean;
  }): Promise<LessonListResponse> {
    const response = await api.get<ApiResponse<LessonListResponse>>(
      '/cms/lessons',
      { params }
    );
    return response.data.data!;
  },

  async getLessonById(id: string): Promise<Lesson> {
    const response = await api.get<ApiResponse<Lesson>>(`/cms/lessons/${id}`);
    return response.data.data!;
  },

  async createLesson(lesson: {
    title: string;
    difficulty: string;
    category: string;
    topic: string;
    targetLanguage: string;
    durationEstimate: number;
    content: LessonContent;
  }): Promise<Lesson> {
    const response = await api.post<ApiResponse<Lesson>>(
      '/cms/lessons',
      lesson
    );
    return response.data.data!;
  },

  async updateLesson(
    id: string,
    updates: {
      title?: string;
      difficulty?: string;
      category?: string;
      topic?: string;
      targetLanguage?: string;
      durationEstimate?: number;
      content?: LessonContent;
      changeDescription?: string;
    }
  ): Promise<Lesson> {
    const response = await api.put<ApiResponse<Lesson>>(
      `/cms/lessons/${id}`,
      updates
    );
    return response.data.data!;
  },

  async deleteLesson(id: string): Promise<void> {
    await api.delete(`/cms/lessons/${id}`);
  },

  async publishLesson(id: string): Promise<Lesson> {
    const response = await api.post<ApiResponse<Lesson>>(
      `/cms/lessons/${id}/publish`
    );
    return response.data.data!;
  },

  async getLessonVersions(id: string): Promise<LessonVersion[]> {
    const response = await api.get<ApiResponse<LessonVersion[]>>(
      `/cms/lessons/${id}/versions`
    );
    return response.data.data!;
  },

  async validateContent(content: LessonContent): Promise<ValidationResult> {
    const response = await api.post<ApiResponse<ValidationResult>>(
      '/cms/lessons/validate',
      { content }
    );
    return response.data.data!;
  },
};
