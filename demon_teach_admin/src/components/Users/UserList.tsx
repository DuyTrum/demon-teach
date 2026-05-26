import React, { useEffect, useState } from 'react';
import { adminService } from '../../services/adminService';
import { toast } from 'react-toastify';
import './UserList.css';

interface User {
  id: string;
  email: string;
  displayName: string;
  role: string;
  nativeLanguage: string;
  targetLanguages: string[];
  createdAt: string;
  lastSignInAt: string;
  disabled: boolean;
}

const UserList: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [roleUpdatingId, setRoleUpdatingId] = useState<string | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const data = await adminService.getUsers({ page, limit: 10, search });
      setUsers(data.users || []);
      setTotalPages(data.pagination?.totalPages || 1);
    } catch (error) {
      console.error('Failed to fetch users', error);
      toast.error('Không thể lấy danh sách người dùng');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [page]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    fetchUsers();
  };

  const handleRoleToggle = async (userId: string, currentRole: string) => {
    const newRole = currentRole === 'admin' ? 'user' : 'admin';
    if (!window.confirm(`Bạn có chắc chắn muốn thay đổi vai trò thành ${newRole.toUpperCase()}?`)) return;

    setRoleUpdatingId(userId);
    try {
      await adminService.updateUserRole(userId, newRole);
      toast.success('Cập nhật vai trò người dùng thành công');
      setUsers(users.map(u => u.id === userId ? { ...u, role: newRole } : u));
    } catch (error) {
      console.error(error);
      toast.error('Cập nhật vai trò thất bại');
    } finally {
      setRoleUpdatingId(null);
    }
  };

  const handleDeleteUser = async (userId: string, email: string) => {
    if (!window.confirm(`⚠️ CẢNH BÁO NGUY HIỂM ⚠️\nBạn có chắc chắn muốn xóa vĩnh viễn tài khoản: ${email}?\nMọi tiến trình học tập, XP, và lộ trình của học sinh này sẽ bị XÓA SẠCH!`)) return;

    setDeletingId(userId);
    try {
      await adminService.deleteUser(userId);
      toast.success('Xóa tài khoản người dùng thành công');
      setUsers(users.filter(u => u.id !== userId));
    } catch (error) {
      console.error(error);
      toast.error('Xóa tài khoản thất bại');
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <div className="user-list-container">
      <div className="list-header">
        <h2>Quản Lý Người Dùng 👥</h2>
        <p>Kiểm soát quyền hạn học giả và quản trị viên</p>
      </div>

      <form onSubmit={handleSearchSubmit} className="search-bar-form filters-bar">
        <input
          type="text"
          placeholder="Tìm kiếm theo email, tên, hoặc UID..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <button type="submit" className="btn-search">Tìm kiếm</button>
      </form>

      {loading ? (
        <div className="loading">
          <div className="spinner"></div>
          <p>Đang tải thông tin học giả...</p>
        </div>
      ) : users.length === 0 ? (
        <div className="empty-state">
          <p>Không tìm thấy học giả nào phù hợp.</p>
        </div>
      ) : (
        <>
          <div className="table-responsive glass-panel">
            <table className="users-table">
              <thead>
                <tr>
                  <th>Tên / Email</th>
                  <th>Học tập</th>
                  <th>Vai trò</th>
                  <th>Hoạt động gần nhất</th>
                  <th>Hành động</th>
                </tr>
              </thead>
              <tbody>
                {users.map((user) => (
                  <tr key={user.id}>
                    <td>
                      <div className="user-identity">
                        <span className="user-avatar">{user.displayName ? user.displayName[0].toUpperCase() : 'U'}</span>
                        <div className="user-details">
                          <strong>{user.displayName}</strong>
                          <span className="user-email-text">{user.email}</span>
                          <span className="user-uid">ID: {user.id}</span>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="user-languages">
                        <span>Gốc: <strong>{user.nativeLanguage.toUpperCase()}</strong></span>
                        <br />
                        <span>Học: <strong>{user.targetLanguages.map(l => l.toUpperCase()).join(', ') || 'Chưa học'}</strong></span>
                      </div>
                    </td>
                    <td>
                      <span className={`role-badge ${user.role}`}>
                        {user.role.toUpperCase()}
                      </span>
                    </td>
                    <td>
                      <div className="user-dates">
                        <span>Đăng ký: {user.createdAt ? new Date(user.createdAt).toLocaleDateString() : 'Không rõ'}</span>
                        <br />
                        <span>Đăng nhập: {user.lastSignInAt ? new Date(user.lastSignInAt).toLocaleDateString() : 'Không rõ'}</span>
                      </div>
                    </td>
                    <td>
                      <div className="action-buttons">
                        <button
                          onClick={() => handleRoleToggle(user.id, user.role)}
                          disabled={roleUpdatingId === user.id}
                          className="btn-action btn-role"
                        >
                          {roleUpdatingId === user.id ? '...' : 'Đổi vai trò'}
                        </button>
                        <button
                          onClick={() => handleDeleteUser(user.id, user.email)}
                          disabled={deletingId === user.id}
                          className="btn-action btn-delete"
                        >
                          {deletingId === user.id ? '...' : 'Xóa'}
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
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1}
              className="btn-pagination"
            >
              Trang trước
            </button>
            <span className="page-info">
              Trang {page} / {totalPages}
            </span>
            <button
              onClick={() => setPage(p => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="btn-pagination"
            >
              Trang sau
            </button>
          </div>
        </>
      )}
    </div>
  );
};

export default UserList;
