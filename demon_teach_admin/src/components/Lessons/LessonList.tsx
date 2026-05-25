import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { lessonService } from '../../services/lessonService';
import { Lesson } from '../../types';
import { toast } from 'react-toastify';
import './LessonList.css';

const LessonList: React.FC = () => {
  const [lessons, setLessons] = useState<Lesson[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [filters, setFilters] = useState({
    targetLanguage: '',
    difficulty: '',
    category: '',
    topic: '',
    isPublished: '',
  });
  const navigate = useNavigate();

  useEffect(() => {
    fetchLessons();
  }, [page, filters]);

  const fetchLessons = async () => {
    setLoading(true);
    try {
      const params: any = { page, limit: 12 };
      
      if (filters.targetLanguage) params.targetLanguage = filters.targetLanguage;
      if (filters.difficulty) params.difficulty = filters.difficulty;
      if (filters.category) params.category = filters.category;
      if (filters.topic) params.topic = filters.topic;
      if (filters.isPublished !== '') params.isPublished = filters.isPublished === 'true';

      const response = await lessonService.getLessons(params);
      setLessons(response.lessons);
      setTotalPages(response.pagination.totalPages);
    } catch (error) {
      toast.error('Failed to fetch lessons');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string, title: string) => {
    if (!window.confirm(`Are you sure you want to delete "${title}"?`)) {
      return;
    }

    try {
      await lessonService.deleteLesson(id);
      toast.success('Lesson deleted successfully');
      fetchLessons();
    } catch (error) {
      toast.error('Failed to delete lesson');
    }
  };

  const handlePublish = async (id: string, title: string) => {
    try {
      await lessonService.publishLesson(id);
      toast.success(`"${title}" published successfully`);
      fetchLessons();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to publish lesson');
    }
  };

  const handleFilterChange = (key: string, value: string) => {
    setFilters({ ...filters, [key]: value });
    setPage(1);
  };

  const getLanguageBadge = (lang: string) => {
    const labels: any = {
      en: 'English',
      zh: 'Chinese',
      ko: 'Korean',
    };
    return <span className="language-badge">{labels[lang] || lang}</span>;
  };

  return (
    <div className="lesson-list-container">
      <div className="list-header">
        <h2>Lessons Library</h2>
        <button
          className="btn-primary"
          onClick={() => navigate('/lessons/new')}
        >
          + New Lesson
        </button>
      </div>

      <div className="filters-bar">
        <select
          value={filters.targetLanguage}
          onChange={(e) => handleFilterChange('targetLanguage', e.target.value)}
        >
          <option value="">All Languages</option>
          <option value="en">English</option>
          <option value="zh">Chinese</option>
          <option value="ko">Korean</option>
        </select>

        <select
          value={filters.difficulty}
          onChange={(e) => handleFilterChange('difficulty', e.target.value)}
        >
          <option value="">All Difficulties</option>
          <option value="beginner">Beginner</option>
          <option value="elementary">Elementary</option>
          <option value="intermediate">Intermediate</option>
          <option value="upperIntermediate">Upper Intermediate</option>
          <option value="advanced">Advanced</option>
        </select>

        <select
          value={filters.category}
          onChange={(e) => handleFilterChange('category', e.target.value)}
        >
          <option value="">All Categories</option>
          <option value="vocabulary">Vocabulary</option>
          <option value="grammar">Grammar</option>
          <option value="listening">Listening</option>
          <option value="speaking">Speaking</option>
          <option value="reading">Reading</option>
          <option value="writing">Writing</option>
        </select>

        <input
          type="text"
          placeholder="Search by topic..."
          value={filters.topic}
          onChange={(e) => handleFilterChange('topic', e.target.value)}
        />

        <select
          value={filters.isPublished}
          onChange={(e) => handleFilterChange('isPublished', e.target.value)}
        >
          <option value="">All Status</option>
          <option value="true">Published</option>
          <option value="false">Drafts</option>
        </select>
      </div>

      {loading ? (
        <div className="loading">Loading lessons...</div>
      ) : lessons.length === 0 ? (
        <div className="no-results">
          <p>No lessons found</p>
          <button
            className="btn-primary"
            onClick={() => navigate('/lessons/new')}
          >
            Create your first lesson
          </button>
        </div>
      ) : (
        <>
          <div className="lessons-grid">
            {lessons.map((lesson) => (
              <div key={lesson.id} className="lesson-card" onClick={() => navigate(`/lessons/${lesson.id}`)}>
                <div className="card-header">
                  <h3>{lesson.title}</h3>
                  {getLanguageBadge(lesson.targetLanguage)}
                </div>
                
                <div className="card-meta">
                  <div className="meta-item">
                    <span>Topic:</span>
                    <strong>{lesson.topic}</strong>
                  </div>
                  <div className="meta-item">
                    <span>Category:</span>
                    <strong>{lesson.category || 'Vocabulary'}</strong>
                  </div>
                  <div className="meta-item">
                    <span>Difficulty:</span>
                    <strong>{lesson.difficulty}</strong>
                  </div>
                  <div className="meta-item">
                    <span>Duration:</span>
                    <strong>{lesson.durationEstimate} min</strong>
                  </div>
                </div>

                <div className="card-footer">
                  <span className="version-badge">v{lesson.version}</span>
                  <div>
                    {lesson.isPublished ? (
                      <span className="status-published">Published</span>
                    ) : (
                      <span className="status-draft">Draft</span>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>

          <div className="pagination">
            <button
              onClick={() => setPage(page - 1)}
              disabled={page === 1}
              className="btn-secondary"
            >
              Previous
            </button>
            <span className="page-info">
              Page {page} of {totalPages}
            </span>
            <button
              onClick={() => setPage(page + 1)}
              disabled={page === totalPages}
              className="btn-secondary"
            >
              Next
            </button>
          </div>
        </>
      )}
    </div>
  );
};

export default LessonList;
