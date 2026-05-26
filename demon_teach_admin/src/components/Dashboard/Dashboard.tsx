import React, { useEffect, useState } from 'react';
import { adminService } from '../../services/adminService';
import './Dashboard.css';

interface DashboardStats {
  totalUsers: number;
  completedLessons: number;
  averageStreak: number;
  averageAccuracy: number;
  totalXP: number;
}

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const data = await adminService.getStats();
        setStats(data);
      } catch (error) {
        console.error('Failed to load stats', error);
      } finally {
        setLoading(false);
      }
    };
    fetchStats();
  }, []);

  if (loading) {
    return (
      <div className="dashboard-loading">
        <div className="spinner"></div>
        <p>Đang triệu hồi số liệu ma thuật...</p>
      </div>
    );
  }

  return (
    <div className="dashboard-container">
      <div className="dashboard-header">
        <h2>Thống Kê Hệ Thống 🔮</h2>
        <p>Quan sát tiến trình học tập của các học giả ma pháp</p>
      </div>

      <div className="stats-grid">
        <div className="stat-card glass-panel purple-glow">
          <div className="stat-icon">👻</div>
          <div className="stat-info">
            <h3>Tổng số Học Giả</h3>
            <p className="stat-value">{stats?.totalUsers || 0}</p>
          </div>
        </div>

        <div className="stat-card glass-panel green-glow">
          <div className="stat-icon">⚔️</div>
          <div className="stat-info">
            <h3>Số Nghi Thức Hoàn Thành</h3>
            <p className="stat-value">{stats?.completedLessons || 0}</p>
          </div>
        </div>

        <div className="stat-card glass-panel orange-glow">
          <div className="stat-icon">🔥</div>
          <div className="stat-info">
            <h3>Chuỗi Ngày Học Trung Bình</h3>
            <p className="stat-value">{stats?.averageStreak || 0} Ngày</p>
          </div>
        </div>

        <div className="stat-card glass-panel red-glow">
          <div className="stat-icon">🎯</div>
          <div className="stat-info">
            <h3>Độ Chính Xác Trung Bình</h3>
            <p className="stat-value">{stats?.averageAccuracy || 0}%</p>
          </div>
        </div>
      </div>

      <div className="dashboard-charts-placeholder glass-panel">
        <h3>Xếp Hạng Năng Lực Ma Pháp</h3>
        <p className="total-xp-info">
          Tổng tích lũy toàn hệ thống: ⚡ <strong>{stats?.totalXP || 0} XP</strong>
        </p>
        <div className="progress-bars-container">
          <div className="progress-item">
            <span className="progress-label">Học từ vựng (Flashcard)</span>
            <div className="progress-track">
              <div className="progress-fill" style={{ width: '78%' }}></div>
            </div>
            <span className="progress-percent">78%</span>
          </div>
          <div className="progress-item">
            <span className="progress-label">Luyện nói (AI Gemini chấm)</span>
            <div className="progress-track">
              <div className="progress-fill" style={{ width: '64%' }}></div>
            </div>
            <span className="progress-percent">64%</span>
          </div>
          <div className="progress-item">
            <span className="progress-label">Luyện nghe (Edge TTS)</span>
            <div className="progress-track">
              <div className="progress-fill" style={{ width: '85%' }}></div>
            </div>
            <span className="progress-percent">85%</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
