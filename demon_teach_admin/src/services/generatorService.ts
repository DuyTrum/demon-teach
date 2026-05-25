import { api } from './api';

export interface GenerateLessonParams {
  topic: string;
  language: 'en' | 'zh' | 'ko';
  difficulty: 'beginner' | 'elementary' | 'intermediate' | 'upperIntermediate' | 'advanced';
  category: 'vocabulary' | 'grammar' | 'listening' | 'speaking' | 'reading' | 'writing';
}

const generatorService = {
  generateLesson: async (params: GenerateLessonParams) => {
    const response = await api.post('/generator/lesson', params);
    return response.data;
  },
};

export default generatorService;
