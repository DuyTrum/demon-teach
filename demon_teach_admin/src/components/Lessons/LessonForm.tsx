import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { lessonService } from '../../services/lessonService';
import { Lesson, LessonContent, Flashcard, Quiz, QuizQuestion } from '../../types';
import { toast } from 'react-toastify';
import './LessonForm.css';

const LessonForm: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const isEditMode = !!id;

  const [loading, setLoading] = useState(false);
  const [validating, setValidating] = useState(false);
  const [lesson, setLesson] = useState<Partial<Lesson>>({
    title: '',
    difficulty: 'beginner',
    category: 'vocabulary',
    topic: '',
    targetLanguage: 'en',
    durationEstimate: 10,
  });

  const [flashcards, setFlashcards] = useState<Flashcard[]>([
    {
      id: 'fc1',
      lessonId: '',
      frontText: '',
      backText: '',
      exampleUsage: '',
      audioUrl: '',
    },
  ]);

  const [quizQuestions, setQuizQuestions] = useState<QuizQuestion[]>([
    {
      id: 'q1',
      type: 'multipleChoice',
      questionText: '',
      options: ['', '', '', ''],
      correctAnswer: '',
      explanation: '',
    },
  ]);

  const [changeDescription, setChangeDescription] = useState('');

  useEffect(() => {
    if (isEditMode && id) {
      fetchLesson(id);
    }
  }, [id, isEditMode]);

  const fetchLesson = async (lessonId: string) => {
    setLoading(true);
    try {
      const data = await lessonService.getLessonById(lessonId);
      setLesson(data);
      
      if (data.content.flashcards) {
        setFlashcards(data.content.flashcards);
      }
      
      if (data.content.quiz?.questions) {
        setQuizQuestions(data.content.quiz.questions);
      }
    } catch (error) {
      toast.error('Failed to fetch lesson');
      navigate('/lessons');
    } finally {
      setLoading(false);
    }
  };

  const handleValidate = async () => {
    setValidating(true);
    try {
      const content = buildContent();
      const result = await lessonService.validateContent(content);
      
      if (result.isValid) {
        toast.success('Content is valid!');
      } else {
        toast.error('Validation failed');
        console.error('Validation errors:', result.errors);
        alert('Validation errors:\n' + result.errors.join('\n'));
      }
    } catch (error: any) {
      toast.error('Validation failed');
      if (error.response?.data?.errors) {
        alert('Validation errors:\n' + error.response.data.errors.join('\n'));
      }
    } finally {
      setValidating(false);
    }
  };

  const buildContent = (): LessonContent => {
    return {
      flashcards: flashcards.map((fc, idx) => ({
        ...fc,
        id: fc.id || `fc${idx + 1}`,
        lessonId: id || 'new',
      })),
      quiz: {
        id: 'quiz1',
        lessonId: id || 'new',
        title: `${lesson.title} Quiz`,
        questions: quizQuestions.map((q, idx) => ({
          ...q,
          id: q.id || `q${idx + 1}`,
        })),
      },
    };
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const content = buildContent();
      
      if (isEditMode && id) {
        await lessonService.updateLesson(id, {
          ...lesson,
          content,
          changeDescription,
        });
        toast.success('Lesson updated successfully');
      } else {
        await lessonService.createLesson({
          title: lesson.title!,
          difficulty: lesson.difficulty!,
          category: lesson.category!,
          topic: lesson.topic!,
          targetLanguage: lesson.targetLanguage!,
          durationEstimate: lesson.durationEstimate!,
          content,
        });
        toast.success('Lesson created successfully');
      }
      
      navigate('/lessons');
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to save lesson');
      if (error.response?.data?.errors) {
        alert('Errors:\n' + error.response.data.errors.join('\n'));
      }
    } finally {
      setLoading(false);
    }
  };

  const addFlashcard = () => {
    setFlashcards([
      ...flashcards,
      {
        id: `fc${flashcards.length + 1}`,
        lessonId: '',
        frontText: '',
        backText: '',
        exampleUsage: '',
        audioUrl: '',
      },
    ]);
  };

  const removeFlashcard = (index: number) => {
    setFlashcards(flashcards.filter((_, i) => i !== index));
  };

  const updateFlashcard = (index: number, field: keyof Flashcard, value: string) => {
    const updated = [...flashcards];
    updated[index] = { ...updated[index], [field]: value };
    setFlashcards(updated);
  };

  const addQuestion = () => {
    setQuizQuestions([
      ...quizQuestions,
      {
        id: `q${quizQuestions.length + 1}`,
        type: 'multipleChoice',
        questionText: '',
        options: ['', '', '', ''],
        correctAnswer: '',
        explanation: '',
      },
    ]);
  };

  const removeQuestion = (index: number) => {
    setQuizQuestions(quizQuestions.filter((_, i) => i !== index));
  };

  const updateQuestion = (index: number, field: keyof QuizQuestion, value: any) => {
    const updated = [...quizQuestions];
    updated[index] = { ...updated[index], [field]: value };
    setQuizQuestions(updated);
  };

  const updateQuestionOption = (qIndex: number, optIndex: number, value: string) => {
    const updated = [...quizQuestions];
    const options = [...(updated[qIndex].options || [])];
    options[optIndex] = value;
    updated[qIndex] = { ...updated[qIndex], options };
    setQuizQuestions(updated);
  };

  if (loading && isEditMode) {
    return <div className="loading">Loading lesson...</div>;
  }

  return (
    <div className="lesson-form-container">
      <div className="form-header">
        <h2>{isEditMode ? 'Edit Lesson' : 'Create New Lesson'}</h2>
        <div className="header-actions">
          <button
            type="button"
            onClick={handleValidate}
            className="btn-secondary"
            disabled={validating}
          >
            {validating ? 'Validating...' : 'Validate Content'}
          </button>
          <button
            type="button"
            onClick={() => navigate('/lessons')}
            className="btn-secondary"
          >
            Cancel
          </button>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="lesson-form">
        {/* Metadata Section */}
        <div className="form-section">
          <h3>Lesson Metadata</h3>
          
          <div className="form-row">
            <div className="form-group">
              <label>Title *</label>
              <input
                type="text"
                value={lesson.title}
                onChange={(e) => setLesson({ ...lesson, title: e.target.value })}
                required
              />
            </div>

            <div className="form-group">
              <label>Target Language *</label>
              <select
                value={lesson.targetLanguage}
                onChange={(e) => setLesson({ ...lesson, targetLanguage: e.target.value as any })}
                required
              >
                <option value="en">English</option>
                <option value="zh">Chinese</option>
                <option value="ko">Korean</option>
              </select>
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Difficulty *</label>
              <select
                value={lesson.difficulty}
                onChange={(e) => setLesson({ ...lesson, difficulty: e.target.value as any })}
                required
              >
                <option value="beginner">Beginner</option>
                <option value="elementary">Elementary</option>
                <option value="intermediate">Intermediate</option>
                <option value="upperIntermediate">Upper Intermediate</option>
                <option value="advanced">Advanced</option>
              </select>
            </div>

            <div className="form-group">
              <label>Category *</label>
              <select
                value={lesson.category || 'vocabulary'}
                onChange={(e) => setLesson({ ...lesson, category: e.target.value as any })}
                required
              >
                <option value="vocabulary">Vocabulary</option>
                <option value="grammar">Grammar</option>
                <option value="listening">Listening</option>
                <option value="speaking">Speaking</option>
                <option value="reading">Reading</option>
                <option value="writing">Writing</option>
              </select>
            </div>

            <div className="form-group">
              <label>Topic *</label>
              <input
                type="text"
                value={lesson.topic}
                onChange={(e) => setLesson({ ...lesson, topic: e.target.value })}
                required
              />
            </div>

            <div className="form-group">
              <label>Duration (minutes) *</label>
              <input
                type="number"
                min="5"
                max="30"
                value={lesson.durationEstimate}
                onChange={(e) => setLesson({ ...lesson, durationEstimate: parseInt(e.target.value) })}
                required
              />
            </div>
          </div>

          {isEditMode && (
            <div className="form-group">
              <label>Change Description</label>
              <textarea
                value={changeDescription}
                onChange={(e) => setChangeDescription(e.target.value)}
                placeholder="Describe what changed in this version..."
                rows={3}
              />
            </div>
          )}
        </div>

        {/* Flashcards Section */}
        <div className="form-section">
          <div className="section-header">
            <h3>Flashcards *</h3>
            <button type="button" onClick={addFlashcard} className="btn-add">
              + Add Flashcard
            </button>
          </div>

          {flashcards.map((flashcard, index) => (
            <div key={index} className="flashcard-item">
              <div className="item-header">
                <h4>Flashcard {index + 1}</h4>
                {flashcards.length > 1 && (
                  <button
                    type="button"
                    onClick={() => removeFlashcard(index)}
                    className="btn-remove"
                  >
                    Remove
                  </button>
                )}
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Front Text (Target Language) *</label>
                  <input
                    type="text"
                    value={flashcard.frontText}
                    onChange={(e) => updateFlashcard(index, 'frontText', e.target.value)}
                    required
                  />
                </div>

                <div className="form-group">
                  <label>Back Text (Translation) *</label>
                  <input
                    type="text"
                    value={flashcard.backText}
                    onChange={(e) => updateFlashcard(index, 'backText', e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Example Usage *</label>
                  <input
                    type="text"
                    value={flashcard.exampleUsage}
                    onChange={(e) => updateFlashcard(index, 'exampleUsage', e.target.value)}
                    required
                  />
                </div>

                <div className="form-group">
                  <label>Audio URL (optional)</label>
                  <input
                    type="url"
                    value={flashcard.audioUrl}
                    onChange={(e) => updateFlashcard(index, 'audioUrl', e.target.value)}
                    placeholder="https://example.com/audio.mp3"
                  />
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Quiz Section */}
        <div className="form-section">
          <div className="section-header">
            <h3>Quiz Questions *</h3>
            <button type="button" onClick={addQuestion} className="btn-add">
              + Add Question
            </button>
          </div>

          {quizQuestions.map((question, qIndex) => (
            <div key={qIndex} className="quiz-item">
              <div className="item-header">
                <h4>Question {qIndex + 1}</h4>
                {quizQuestions.length > 1 && (
                  <button
                    type="button"
                    onClick={() => removeQuestion(qIndex)}
                    className="btn-remove"
                  >
                    Remove
                  </button>
                )}
              </div>

              <div className="form-group">
                <label>Question Type *</label>
                <select
                  value={question.type}
                  onChange={(e) => updateQuestion(qIndex, 'type', e.target.value)}
                  required
                >
                  <option value="multipleChoice">Multiple Choice</option>
                  <option value="fillInBlank">Fill in the Blank</option>
                  <option value="matching">Matching</option>
                  <option value="trueFalse">True/False</option>
                </select>
              </div>

              <div className="form-group">
                <label>Question Text *</label>
                <input
                  type="text"
                  value={question.questionText}
                  onChange={(e) => updateQuestion(qIndex, 'questionText', e.target.value)}
                  required
                />
              </div>

              {question.type === 'multipleChoice' && (
                <div className="form-group">
                  <label>Options *</label>
                  {question.options?.map((option, optIndex) => (
                    <input
                      key={optIndex}
                      type="text"
                      value={option}
                      onChange={(e) => updateQuestionOption(qIndex, optIndex, e.target.value)}
                      placeholder={`Option ${optIndex + 1}`}
                      required
                      style={{ marginBottom: '8px' }}
                    />
                  ))}
                </div>
              )}

              <div className="form-row">
                <div className="form-group">
                  <label>Correct Answer *</label>
                  <input
                    type="text"
                    value={question.correctAnswer}
                    onChange={(e) => updateQuestion(qIndex, 'correctAnswer', e.target.value)}
                    required
                  />
                </div>

                <div className="form-group">
                  <label>Explanation (optional)</label>
                  <input
                    type="text"
                    value={question.explanation}
                    onChange={(e) => updateQuestion(qIndex, 'explanation', e.target.value)}
                  />
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="form-actions">
          <button type="submit" className="btn-primary" disabled={loading}>
            {loading ? 'Saving...' : isEditMode ? 'Update Lesson' : 'Create Lesson'}
          </button>
        </div>
      </form>
    </div>
  );
};

export default LessonForm;
