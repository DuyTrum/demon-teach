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
      const params: any = { page, limit: 20 };
      
      if (filters.targetLanguage) params.targetLanguage = filters.targetLanguage;
      if (filters.difficulty) params.difficulty = filters.difficulty;
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

  const getDifficultyBadge = (difficulty: string) => {
    const colors: any = {
      basic: '#4caf50',
      intermediate: '#ff9800',
      advanced: '#f44336',
    };
    return (
      <span
        className="badge"
        style={{ backgroundColor: colors[difficulty] || '#999' }}
      >
        {difficulty}
      </span>
    );
  };

  const getLanguageBadge = (lang: string) => {
    const labels: any = {
      en: 'English',
      zh: 'Chinese',
      ko: 'Korean',
    };
    return <span className="badge badge-language">{labels[lang] || lang}</span>;
  };

  return (
    <div className="lesson-list-container">
      <div className="page-header">
        <h2>Lessons</h2>
        <button
          className="btn-primary"
          onClick={() => navigate('/lessons/new')}
        >
          + New Lesson
        </button>
      </div>

      <div className="filters">
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
          <option value="basic">Basic</option>
          <option value="intermediate">Intermediate</option>
          <option value="advanced">Advanced</option>
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
          <option value="false">Unpublished</option>
        </select>
      </div>

      {loading ? (
        <div className="loading">Loading lessons...</div>
      ) : lessons.length === 0 ? (
        <div className="empty-state">
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
          <div className="lesson-table">
            <table>
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Language</th>
                  <th>Difficulty</th>
                  <th>Topic</th>
                  <th>Duration</th>
                  <th>Version</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {lessons.map((lesson) => (
                  <tr key={lesson.id}>
                    <td>
                      <strong>{lesson.title}</strong>
                    </td>
                    <td>{getLanguageBadge(lesson.targetLanguage)}</td>
                    <td>{getDifficultyBadge(lesson.difficulty)}</td>
                    <td>{lesson.topic}</td>
                    <td>{lesson.durationEstimate} min</td>
                    <td>v{lesson.version}</td>
                    <td>
                      {lesson.isPublished ? (
                        <span className="status-published">Published</span>
                      ) : (
                        <span className="status-draft">Draft</span>
                      )}
                    </td>
                    <td>
                      <div className="action-buttons">
                        <button
                          className="btn-small btn-view"
                          onClick={() => navigate(`/lessons/${lesson.id}`)}
                        >
                          View
                        </button>
                        <button
                          className="btn-small btn-edit"
                          onClick={() => navigate(`/lessons/${lesson.id}/edit`)}
                        >
                          Edit
                        </button>
                        {!lesson.isPublished && (
                          <button
                            className="btn-small btn-publish"
                            onClick={() => handlePublish(lesson.id, lesson.title)}
                          >
                            Publish
                          </button>
                        )}
                        <button
                          className="btn-small btn-delete"
                          onClick={() => handleDelete(lesson.id, lesson.title)}
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="pagination">
            <button
              onClick={() => setPage(page - 1)}
              disabled={page === 1}
              className="btn-pagination"
            >
              Previous
            </button>
            <span className="page-info">
              Page {page} of {totalPages}
            </span>
            <button
              onClick={() => setPage(page + 1)}
              disabled={page === totalPages}
              className="btn-pagination"
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
