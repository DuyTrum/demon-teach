import React, { useEffect, useState } from 'react';
import { adminService } from '../../services/adminService';
import { toast } from 'react-toastify';
import './LeaderboardManage.css';

interface LeaderboardEntry {
  rank: number;
  id: string; // progress document ID
  userId: string;
  displayName: string;
  email: string;
  totalXP: number;
  currentStreak: number;
  souls: number;
  updatedAt: string;
}

const LeaderboardManage: React.FC = () => {
  const [language, setLanguage] = useState('en');
  const [entries, setEntries] = useState<LeaderboardEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingEntry, setEditingEntry] = useState<LeaderboardEntry | null>(null);
  
  // Form fields for editing
  const [editXP, setEditXP] = useState(0);
  const [editStreak, setEditStreak] = useState(0);
  const [editSouls, setEditSouls] = useState(0);
  const [saving, setSaving] = useState(false);

  const fetchLeaderboard = async () => {
    setLoading(true);
    try {
      const data = await adminService.getLeaderboard(language);
      setEntries(data || []);
    } catch (error) {
      console.error(error);
      toast.error('Không thể lấy bảng xếp hạng');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLeaderboard();
  }, [language]);

  const handleEditClick = (entry: LeaderboardEntry) => {
    setEditingEntry(entry);
    setEditXP(entry.totalXP);
    setEditStreak(entry.currentStreak);
    setEditSouls(entry.souls);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingEntry) return;

    setSaving(true);
    try {
      await adminService.updateLeaderboardProgress(editingEntry.id, {
        totalXP: editXP,
        currentStreak: editStreak,
        souls: editSouls
      });
      toast.success('Cập nhật chỉ số thành công');
      setEditingEntry(null);
      fetchLeaderboard();
    } catch (error) {
      console.error(error);
      toast.error('Cập nhật chỉ số thất bại');
    } finally {
      setSaving(false);
    }
  };

  const handleReset = async (progressId: string, displayName: string) => {
    if (!window.confirm(`Bạn có chắc chắn muốn đặt lại toàn bộ điểm số của "${displayName}" về 0?`)) return;

    try {
      await adminService.resetLeaderboardProgress(progressId);
      toast.success('Đã đặt lại tiến trình học giả');
      fetchLeaderboard();
    } catch (error) {
      console.error(error);
      toast.error('Đặt lại chỉ số thất bại');
    }
  };

  return (
    <div className="leaderboard-manage-container">
      <div className="manage-header">
        <h2>Bảng Xếp Hạng & Điểm Số 🏆</h2>
        <p>Điều chỉnh XP, Chuỗi ngày học (Streak), và Linh hồn của học giả</p>
      </div>

      <div className="filters-bar glass-panel">
        <div className="filter-group">
          <label htmlFor="language-select">Môn học Pháp thuật (Ngôn ngữ):</label>
          <select
            id="language-select"
            value={language}
            onChange={(e) => setLanguage(e.target.value)}
          >
            <option value="en">English (Anh ngữ)</option>
            <option value="ja">Japanese (Nhật ngữ)</option>
            <option value="zh">Chinese (Trung ngữ)</option>
            <option value="ko">Korean (Hàn ngữ)</option>
          </select>
        </div>
        <button onClick={fetchLeaderboard} className="btn-refresh">Làm mới 🔄</button>
      </div>

      {loading ? (
        <div className="loading">
          <div className="spinner"></div>
          <p>Đang đọc biểu đồ năng lượng học giả...</p>
        </div>
      ) : entries.length === 0 ? (
        <div className="empty-state glass-panel">
          <p>Chưa có học giả nào bắt đầu học ngôn ngữ này.</p>
        </div>
      ) : (
        <div className="table-responsive glass-panel">
          <table className="leaderboard-table">
            <thead>
              <tr>
                <th className="col-rank">Hạng</th>
                <th>Tên / Email</th>
                <th>Tổng XP ⚡</th>
                <th>Chuỗi ngày 🔥</th>
                <th>Linh hồn 👻</th>
                <th>Cập nhật cuối</th>
                <th className="col-actions">Hành động</th>
              </tr>
            </thead>
            <tbody>
              {entries.map((entry) => (
                <tr key={entry.id} className={entry.rank <= 3 ? `top-rank-${entry.rank}` : ''}>
                  <td className="col-rank">
                    <span className="rank-badge">
                      {entry.rank === 1 ? '🥇' : entry.rank === 2 ? '🥈' : entry.rank === 3 ? '🥉' : entry.rank}
                    </span>
                  </td>
                  <td>
                    <div className="user-info">
                      <strong>{entry.displayName}</strong>
                      <span className="user-email">{entry.email}</span>
                    </div>
                  </td>
                  <td className="xp-value">⚡ {entry.totalXP} XP</td>
                  <td className="streak-value">🔥 {entry.currentStreak} ngày</td>
                  <td className="souls-value">👻 {entry.souls}</td>
                  <td className="date-value">{entry.updatedAt ? new Date(entry.updatedAt).toLocaleDateString() : 'Chưa rõ'}</td>
                  <td>
                    <div className="action-buttons">
                      <button
                        onClick={() => handleEditClick(entry)}
                        className="btn-action btn-edit"
                      >
                        Chỉnh sửa
                      </button>
                      <button
                        onClick={() => handleReset(entry.id, entry.displayName)}
                        className="btn-action btn-reset"
                      >
                        Đặt lại
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Edit Modal Dialog */}
      {editingEntry && (
        <div className="modal-overlay">
          <div className="modal-content glass-panel purple-glow">
            <h3>Hiệu Chỉnh Năng Lực Học Giả 🔮</h3>
            <p className="modal-subtitle">Đang chỉnh sửa: <strong>{editingEntry.displayName}</strong></p>

            <form onSubmit={handleSave} className="modal-form">
              <div className="form-group">
                <label>Tổng Tích Lũy XP (⚡):</label>
                <input
                  type="number"
                  min="0"
                  value={editXP}
                  onChange={(e) => setEditXP(parseInt(e.target.value) || 0)}
                  required
                />
              </div>

              <div className="form-group">
                <label>Chuỗi Học Tập (🔥):</label>
                <input
                  type="number"
                  min="0"
                  value={editStreak}
                  onChange={(e) => setEditStreak(parseInt(e.target.value) || 0)}
                  required
                />
              </div>

              <div className="form-group">
                <label>Linh Hồn Tích Lũy (👻):</label>
                <input
                  type="number"
                  min="0"
                  value={editSouls}
                  onChange={(e) => setEditSouls(parseInt(e.target.value) || 0)}
                  required
                />
              </div>

              <div className="modal-actions">
                <button
                  type="button"
                  onClick={() => setEditingEntry(null)}
                  className="btn-modal btn-cancel"
                  disabled={saving}
                >
                  Hủy bỏ
                </button>
                <button
                  type="submit"
                  className="btn-modal btn-submit"
                  disabled={saving}
                >
                  {saving ? 'Đang lưu...' : 'Lưu Thay Đổi'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default LeaderboardManage;
