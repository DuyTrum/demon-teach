import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import generatorService, { GenerateLessonParams } from '../../services/generatorService';
import { toast } from 'react-toastify';
import './AiGenerator.css';

const AiGenerator: React.FC = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [params, setParams] = useState<GenerateLessonParams>({
    topic: '',
    language: 'zh',
    difficulty: 'basic',
  });

  const [generatedLesson, setGeneratedLesson] = useState<any>(null);

  const handleGenerate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!params.topic) {
      toast.error('Please enter a topic');
      return;
    }

    setLoading(true);
    setGeneratedLesson(null);
    try {
      const response = await generatorService.generateLesson(params);
      if (response.success) {
        setGeneratedLesson(response.data);
        toast.success('Lesson generated successfully!');
      }
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to generate lesson');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="ai-generator-container">
      <div className="generator-card">
        <h2>✨ AI Lesson Generator</h2>
        <p className="subtitle">Enter a topic and let AI create a complete lesson for you.</p>

        <form onSubmit={handleGenerate} className="generator-form">
          <div className="form-group">
            <label>Target Language</label>
            <div className="language-selector">
              <button
                type="button"
                className={params.language === 'en' ? 'active' : ''}
                onClick={() => setParams({ ...params, language: 'en' })}
              >
                🇺🇸 English
              </button>
              <button
                type="button"
                className={params.language === 'zh' ? 'active' : ''}
                onClick={() => setParams({ ...params, language: 'zh' })}
              >
                🇨🇳 Chinese
              </button>
              <button
                type="button"
                className={params.language === 'ko' ? 'active' : ''}
                onClick={() => setParams({ ...params, language: 'ko' })}
              >
                🇰🇷 Korean
              </button>
            </div>
          </div>

          <div className="form-group">
            <label>Difficulty Level</label>
            <select
              value={params.difficulty}
              onChange={(e) => setParams({ ...params, difficulty: e.target.value as any })}
            >
              <option value="basic">Basic (Beginner)</option>
              <option value="intermediate">Intermediate</option>
              <option value="advanced">Advanced</option>
            </select>
          </div>

          <div className="form-group">
            <label>Lesson Topic</label>
            <input
              type="text"
              placeholder="e.g., Ordering Coffee, Space Exploration, HSK 1 Greetings..."
              value={params.topic}
              onChange={(e) => setParams({ ...params, topic: e.target.value })}
              required
            />
          </div>

          <button type="submit" className="btn-generate" disabled={loading}>
            {loading ? (
              <>
                <span className="spinner"></span> Generating Magic...
              </>
            ) : (
              '🚀 Generate Lesson'
            )}
          </button>
        </form>
      </div>

      {generatedLesson && (
        <div className="result-card">
          <div className="result-header">
            <h3>✅ Generated: {generatedLesson.title}</h3>
            <button 
              className="btn-view"
              onClick={() => navigate(`/lessons/${generatedLesson.id}`)}
            >
              View Full Lesson
            </button>
          </div>
          
          <div className="preview-grid">
            <div className="preview-section">
              <h4>Flashcards ({generatedLesson.content.flashcards.length})</h4>
              <ul>
                {generatedLesson.content.flashcards.slice(0, 3).map((fc: any, i: number) => (
                  <li key={i}>
                    <strong>{fc.frontText}</strong>: {fc.backText}
                  </li>
                ))}
                {generatedLesson.content.flashcards.length > 3 && <li>... and more</li>}
              </ul>
            </div>
            
            <div className="preview-section">
              <h4>Quiz ({generatedLesson.content.quiz.questions.length} questions)</h4>
              <p>First question: {generatedLesson.content.quiz.questions[0].content.questionText}</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AiGenerator;
