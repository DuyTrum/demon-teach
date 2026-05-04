import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { lessonService } from '../../services/lessonService';
import { Lesson, LessonVersion } from '../../types';
import { toast } from 'react-toastify';
import './LessonDetail.css';

const LessonDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [lesson, setLesson] = useState<Lesson | null>(null);
  const [versions, setVersions] = useState<LessonVersion[]>([]);
  const [activeTab, setActiveTab] = useState<'content' | 'versions'>('content');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (id) {
      fetchLesson(id);
      fetchVersions(id);
    }
  }, [id]);

  const fetchLesson = async (lessonId: string) => {
    try {
      const data = await lessonService.getLessonById(lessonId);
      setLesson(data);
    } catch (error) {
      toast.error('Failed to fetch lesson');
      navigate('/lessons');
    } finally {
      setLoading(false);
    }
  };

  const fetchVersions = async (lessonId: string) => {
    try {
      const data = await lessonService.getLessonVersions(lessonId);
      setVersions(data);
    } catch (error) {
      console.error('Failed to fetch versions:', error);
    }
  };

  const handlePublish = async () => {
    if (!id || !lesson) return;

    try {
      await lessonService.publishLesson(id);
      toast.success('Lesson published successfully');
      fetchLesson(id);
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to publish lesson');
    }
  };

  const handleDelete = async () => {
    if (!id || !lesson) return;

    if (!window.confirm(`Are you sure you want to delete "${lesson.title}"?`)) {
      return;
    }

    try {
      await lessonService.deleteLesson(id);
      toast.success('Lesson deleted successfully');
      navigate('/lessons');
    } catch (error) {
      toast.error('Failed to delete lesson');
    }
  };

  if (loading) {
    return <div className="loading">Loading lesson...</div>;
  }

  if (!lesson) {
    return <div className="loading">Lesson not found</div>;
  }

  return (
    <div className="lesson-detail-container">
      <div className="detail-header">
        <div>
          <h2>{lesson.title}</h2>
          <div className="lesson-meta">
            <span className="meta-item">
              Language: <strong>{lesson.targetLanguage.toUpperCase()}</strong>
            </span>
            <span className="meta-item">
              Difficulty: <strong>{lesson.difficulty}</strong>
            </span>
            <span className="meta-item">
              Topic: <strong>{lesson.topic}</strong>
            </span>
            <span className="meta-item">
              Duration: <strong>{lesson.durationEstimate} min</strong>
            </span>
            <span className="meta-item">
              Version: <strong>v{lesson.version}</strong>
            </span>
            <span className="meta-item">
              Status:{' '}
              <strong className={lesson.isPublished ? 'status-published' : 'status-draft'}>
                {lesson.isPublished ? 'Published' : 'Draft'}
              </strong>
            </span>
          </div>
        </div>

        <div className="header-actions">
          <button onClick={() => navigate(`/lessons/${id}/edit`)} className="btn-edit">
            Edit
          </button>
          {!lesson.isPublished && (
            <button onClick={handlePublish} className="btn-publish">
              Publish
            </button>
          )}
          <button onClick={handleDelete} className="btn-delete">
            Delete
          </button>
          <button onClick={() => navigate('/lessons')} className="btn-secondary">
            Back to List
          </button>
        </div>
      </div>

      <div className="tabs">
        <button
          className={`tab ${activeTab === 'content' ? 'active' : ''}`}
          onClick={() => setActiveTab('content')}
        >
          Content
        </button>
        <button
          className={`tab ${activeTab === 'versions' ? 'active' : ''}`}
          onClick={() => setActiveTab('versions')}
        >
          Version History ({versions.length})
        </button>
      </div>

      {activeTab === 'content' && (
        <div className="content-section">
          {/* Flashcards */}
          <div className="content-block">
            <h3>Flashcards ({lesson.content.flashcards.length})</h3>
            <div className="flashcard-list">
              {lesson.content.flashcards.map((flashcard, index) => (
                <div key={index} className="flashcard-card">
                  <div className="flashcard-front">
                    <strong>Front:</strong> {flashcard.frontText}
                  </div>
                  <div className="flashcard-back">
                    <strong>Back:</strong> {flashcard.backText}
                  </div>
                  <div className="flashcard-example">
                    <strong>Example:</strong> {flashcard.exampleUsage}
                  </div>
                  {flashcard.audioUrl && (
                    <div className="flashcard-audio">
                      <strong>Audio:</strong>{' '}
                      <a href={flashcard.audioUrl} target="_blank" rel="noopener noreferrer">
                        {flashcard.audioUrl}
                      </a>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Quiz */}
          <div className="content-block">
            <h3>Quiz ({lesson.content.quiz.questions.length} questions)</h3>
            <div className="quiz-list">
              {lesson.content.quiz.questions.map((question, index) => (
                <div key={index} className="quiz-card">
                  <div className="quiz-question">
                    <strong>Q{index + 1}:</strong> {question.questionText}
                  </div>
                  <div className="quiz-type">
                    <strong>Type:</strong> {question.type}
                  </div>
                  {question.options && question.options.length > 0 && (
                    <div className="quiz-options">
                      <strong>Options:</strong>
                      <ul>
                        {question.options.map((option, optIndex) => (
                          <li
                            key={optIndex}
                            className={option === question.correctAnswer ? 'correct-option' : ''}
                          >
                            {option}
                            {option === question.correctAnswer && ' ✓'}
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}
                  <div className="quiz-answer">
                    <strong>Correct Answer:</strong> {question.correctAnswer}
                  </div>
                  {question.explanation && (
                    <div className="quiz-explanation">
                      <strong>Explanation:</strong> {question.explanation}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Listening Exercise */}
          {lesson.content.listeningExercise && (
            <div className="content-block">
              <h3>Listening Exercise</h3>
              <div className="listening-card">
                <p>
                  <strong>Audio URL:</strong>{' '}
                  <a
                    href={lesson.content.listeningExercise.audioUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {lesson.content.listeningExercise.audioUrl}
                  </a>
                </p>
                <p>
                  <strong>Duration:</strong> {lesson.content.listeningExercise.durationSeconds}{' '}
                  seconds
                </p>
                <p>
                  <strong>Questions:</strong> {lesson.content.listeningExercise.questions.length}
                </p>
              </div>
            </div>
          )}

          {/* Speaking Exercise */}
          {lesson.content.speakingExercise && (
            <div className="content-block">
              <h3>Speaking Exercise</h3>
              <div className="speaking-card">
                <p>
                  <strong>Phrase:</strong> {lesson.content.speakingExercise.phrase}
                </p>
                <p>
                  <strong>Model Audio:</strong>{' '}
                  <a
                    href={lesson.content.speakingExercise.modelAudioUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {lesson.content.speakingExercise.modelAudioUrl}
                  </a>
                </p>
              </div>
            </div>
          )}
        </div>
      )}

      {activeTab === 'versions' && (
        <div className="versions-section">
          {versions.length === 0 ? (
            <p className="empty-message">No version history available</p>
          ) : (
            <div className="version-list">
              {versions.map((version) => (
                <div key={version.id} className="version-card">
                  <div className="version-header">
                    <h4>Version {version.version}</h4>
                    <span className="version-date">
                      {new Date(version.createdAt).toLocaleString()}
                    </span>
                  </div>
                  <div className="version-details">
                    <p>
                      <strong>Title:</strong> {version.title}
                    </p>
                    <p>
                      <strong>Difficulty:</strong> {version.difficulty}
                    </p>
                    <p>
                      <strong>Topic:</strong> {version.topic}
                    </p>
                    {version.changeDescription && (
                      <p>
                        <strong>Changes:</strong> {version.changeDescription}
                      </p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default LessonDetail;
