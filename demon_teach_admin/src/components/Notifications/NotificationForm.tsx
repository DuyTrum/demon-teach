import React, { useState } from 'react';
import { adminService } from '../../services/adminService';
import { toast } from 'react-toastify';
import './NotificationForm.css';

const NotificationForm: React.FC = () => {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [sending, setSending] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !body.trim()) {
      toast.warn('Vui lòng điền đầy đủ Tiêu đề và Nội dung');
      return;
    }

    setSending(true);
    try {
      await adminService.sendNotification(title, body);
      toast.success('Gửi thông báo toàn hệ thống thành công! 🚀');
      setTitle('');
      setBody('');
    } catch (error) {
      console.error(error);
      toast.error('Gửi thông báo thất bại');
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="notification-form-container">
      <div className="form-header">
        <h2>Thông Báo Đẩy Hệ Thống 📢</h2>
        <p>Phát lệnh truyền tin đến tất cả điện thoại của các học giả ma pháp</p>
      </div>

      <div className="notification-grid">
        {/* Editor Panel */}
        <div className="editor-panel glass-panel purple-glow">
          <h3>Soạn thảo Truyền tin</h3>
          <form onSubmit={handleSubmit} className="compose-form">
            <div className="form-group">
              <label htmlFor="notif-title">Tiêu đề thông báo:</label>
              <input
                id="notif-title"
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Ví dụ: Đêm nay nguyệt thực cực đại! 🌘"
                maxLength={60}
                required
              />
              <span className="char-counter">{title.length}/60</span>
            </div>

            <div className="form-group">
              <label htmlFor="notif-body">Nội dung thông điệp:</label>
              <textarea
                id="notif-body"
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="Ví dụ: Hãy hoàn thành bài tập ma pháp tiếng Anh hôm nay để nhận thêm gấp đôi Linh hồn và duy trì Streak!"
                maxLength={200}
                rows={5}
                required
              />
              <span className="char-counter">{body.length}/200</span>
            </div>

            <button
              type="submit"
              disabled={sending}
              className="btn-send-notification"
            >
              {sending ? 'Đang gửi tín hiệu...' : 'Gửi Thông Báo Toàn Cầu 🚀'}
            </button>
          </form>
        </div>

        {/* Live Preview Panel */}
        <div className="preview-panel glass-panel">
          <h3>Bản xem trước trên Điện thoại 📱</h3>
          <p className="preview-desc">Cách học sinh nhìn thấy thông báo trên thiết bị di động:</p>
          
          <div className="phone-mockup">
            <div className="phone-screen">
              <div className="phone-notch"></div>
              <div className="phone-status-bar">
                <span>14:40</span>
                <div className="status-icons">📶 🔋</div>
              </div>
              
              <div className="phone-notification-layer">
                {title || body ? (
                  <div className="notification-banner">
                    <div className="banner-header">
                      <div className="app-logo">👻</div>
                      <span className="app-name">Demon Teach</span>
                      <span className="banner-time">vừa xong</span>
                    </div>
                    <div className="banner-content">
                      <strong className="banner-title">{title || 'Tiêu đề thông báo'}</strong>
                      <p className="banner-body">{body || 'Nội dung thông điệp sẽ hiển thị ở đây khi bạn nhập vào ô soạn thảo...'}</p>
                    </div>
                  </div>
                ) : (
                  <div className="no-notification">
                    <span>Màn hình đang trống. Nhập nội dung để xem trước!</span>
                  </div>
                )}
              </div>

              <div className="phone-home-indicator"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default NotificationForm;
