import React, { useState } from 'react';
import { adminService } from '../../services/adminService';
import { toast } from 'react-toastify';
import './SystemData.css';

const SystemData: React.FC = () => {
  const [loadingAction, setLoadingAction] = useState<string | null>(null);
  const [consoleOutput, setConsoleOutput] = useState<string>('');
  
  // Verification inputs
  const [wipeFirestoreConfirm, setWipeFirestoreConfirm] = useState('');
  const [wipeAuthConfirm, setWipeAuthConfirm] = useState('');
  const [seedConfirm, setSeedConfirm] = useState('');

  const appendToConsole = (actionName: string, text: string) => {
    const timestamp = new Date().toLocaleTimeString();
    setConsoleOutput(prev => prev + `[${timestamp}] [${actionName}] ${text}\n`);
  };

  const handleWipeFirestore = async (e: React.FormEvent) => {
    e.preventDefault();
    if (wipeFirestoreConfirm !== 'CONFIRM WIPE') {
      toast.warn('Vui lòng nhập chính xác "CONFIRM WIPE" để xác nhận');
      return;
    }

    if (!window.confirm('⚠️ HÀNH ĐỘNG KHÔNG THỂ HOÀN TÁC ⚠️\nBạn chắc chắn muốn XÓA SẠCH toàn bộ collections trên Cloud Firestore chứ?')) {
      return;
    }

    setLoadingAction('wipe_firestore');
    appendToConsole('Wipe Firestore', 'Bắt đầu quá trình dọn dẹp Firestore...');
    try {
      const response = await adminService.wipeFirestore();
      toast.success('Dọn dẹp Firestore thành công!');
      appendToConsole('Wipe Firestore', `Kết quả: ${response.message}`);
      if (response.output) {
        appendToConsole('Wipe Firestore', `Output:\n${response.output}`);
      }
      setWipeFirestoreConfirm('');
    } catch (error: any) {
      console.error(error);
      toast.error('Dọn dẹp Firestore thất bại');
      appendToConsole('Wipe Firestore', `Lỗi: ${error.response?.data?.error || error.message}`);
    } finally {
      setLoadingAction(null);
    }
  };

  const handleWipeAuthUsers = async (e: React.FormEvent) => {
    e.preventDefault();
    if (wipeAuthConfirm !== 'CONFIRM WIPE AUTH') {
      toast.warn('Vui lòng nhập chính xác "CONFIRM WIPE AUTH" để xác nhận');
      return;
    }

    if (!window.confirm('⚠️ HÀNH ĐỘNG CỰC KỲ NGUY HIỂM ⚠️\nBạn chắc chắn muốn XÓA SẠCH toàn bộ người dùng trong danh sách Firebase Authentication?')) {
      return;
    }

    setLoadingAction('wipe_auth');
    appendToConsole('Wipe Auth Users', 'Bắt đầu xóa danh sách Firebase Authentication...');
    try {
      const response = await adminService.wipeAuthUsers();
      toast.success('Xóa tài khoản người dùng Firebase Auth thành công!');
      appendToConsole('Wipe Auth Users', `Kết quả: ${response.message}`);
      if (response.output) {
        appendToConsole('Wipe Auth Users', `Output:\n${response.output}`);
      }
      setWipeAuthConfirm('');
    } catch (error: any) {
      console.error(error);
      toast.error('Xóa người dùng Auth thất bại');
      appendToConsole('Wipe Auth Users', `Lỗi: ${error.response?.data?.error || error.message}`);
    } finally {
      setLoadingAction(null);
    }
  };

  const handleSeedLessons = async (e: React.FormEvent) => {
    e.preventDefault();
    if (seedConfirm !== 'CONFIRM SEED') {
      toast.warn('Vui lòng nhập chính xác "CONFIRM SEED" để xác nhận');
      return;
    }

    setLoadingAction('seed_lessons');
    appendToConsole('Seed Lessons', 'Bắt đầu nạp dữ liệu bài học mẫu mẫu...');
    try {
      const response = await adminService.seedLessons();
      toast.success('Khởi tạo bài học mẫu thành công! 📚');
      appendToConsole('Seed Lessons', `Kết quả: ${response.message}`);
      if (response.output) {
        appendToConsole('Seed Lessons', `Output:\n${response.output}`);
      }
      setSeedConfirm('');
    } catch (error: any) {
      console.error(error);
      toast.error('Nạp bài học thất bại');
      appendToConsole('Seed Lessons', `Lỗi: ${error.response?.data?.error || error.message}`);
    } finally {
      setLoadingAction(null);
    }
  };

  return (
    <div className="system-data-container">
      <div className="system-header">
        <h2>Công Cụ Hệ Thống & Khởi Tạo Dữ Liệu ⚙️</h2>
        <p>Quản lý trạng thái cơ sở dữ liệu và nạp tài liệu học tập mẫu</p>
      </div>

      <div className="system-grid">
        {/* Actions panel */}
        <div className="actions-column">
          {/* Seed Panel */}
          <div className="control-panel glass-panel green-border">
            <div className="panel-title-area">
              <span className="panel-icon">📚</span>
              <div>
                <h3>Khởi Tạo Bài Học Mẫu (Seed)</h3>
                <p>Nạp các bài học ma pháp, từ vựng, flashcard, câu hỏi quiz và chấm phát âm AI mặc định vào Firestore.</p>
              </div>
            </div>
            <form onSubmit={handleSeedLessons} className="panel-form">
              <div className="verification-area">
                <input
                  type="text"
                  placeholder="Nhập 'CONFIRM SEED' để kích hoạt"
                  value={seedConfirm}
                  onChange={(e) => setSeedConfirm(e.target.value)}
                  disabled={loadingAction !== null}
                />
                <button
                  type="submit"
                  disabled={loadingAction !== null || seedConfirm !== 'CONFIRM SEED'}
                  className="btn-system btn-seed"
                >
                  {loadingAction === 'seed_lessons' ? 'Đang nạp...' : 'Khởi tạo bài học'}
                </button>
              </div>
            </form>
          </div>

          {/* Wipe Firestore Panel */}
          <div className="control-panel glass-panel red-border">
            <div className="panel-title-area">
              <span className="panel-icon">🔥</span>
              <div>
                <h3>Dọn Sạch Cơ Sở Dữ Liệu (Wipe Firestore)</h3>
                <p className="danger-text">Xóa tất cả các tiến trình học tập, lịch sử câu hỏi, từ vựng bookmark và bảng xếp hạng. Chỉ giữ lại khung tài khoản.</p>
              </div>
            </div>
            <form onSubmit={handleWipeFirestore} className="panel-form">
              <div className="verification-area">
                <input
                  type="text"
                  placeholder="Nhập 'CONFIRM WIPE' để kích hoạt"
                  value={wipeFirestoreConfirm}
                  onChange={(e) => setWipeFirestoreConfirm(e.target.value)}
                  disabled={loadingAction !== null}
                />
                <button
                  type="submit"
                  disabled={loadingAction !== null || wipeFirestoreConfirm !== 'CONFIRM WIPE'}
                  className="btn-system btn-danger-action"
                >
                  {loadingAction === 'wipe_firestore' ? 'Đang xóa...' : 'Xóa Firestore'}
                </button>
              </div>
            </form>
          </div>

          {/* Wipe Auth Panel */}
          <div className="control-panel glass-panel red-border">
            <div className="panel-title-area">
              <span className="panel-icon">💀</span>
              <div>
                <h3>Xóa Danh Sách Tài Khoản (Wipe Auth)</h3>
                <p className="danger-text">Xóa vĩnh viễn toàn bộ tài khoản người dùng đăng ký khỏi Firebase Authentication. Học sinh sẽ phải đăng ký tài khoản mới.</p>
              </div>
            </div>
            <form onSubmit={handleWipeAuthUsers} className="panel-form">
              <div className="verification-area">
                <input
                  type="text"
                  placeholder="Nhập 'CONFIRM WIPE AUTH' để kích hoạt"
                  value={wipeAuthConfirm}
                  onChange={(e) => setWipeAuthConfirm(e.target.value)}
                  disabled={loadingAction !== null}
                />
                <button
                  type="submit"
                  disabled={loadingAction !== null || wipeAuthConfirm !== 'CONFIRM WIPE AUTH'}
                  className="btn-system btn-danger-action"
                >
                  {loadingAction === 'wipe_auth' ? 'Đang xóa...' : 'Xóa Sạch Auth'}
                </button>
              </div>
            </form>
          </div>
        </div>

        {/* Console output log */}
        <div className="console-column">
          <div className="console-panel glass-panel">
            <div className="console-header">
              <h3>Bảng Nhật Ký Hoạt Động (System Logs)</h3>
              <button onClick={() => setConsoleOutput('')} className="btn-clear-console">Clear 🗑️</button>
            </div>
            <textarea
              className="console-textarea"
              readOnly
              value={consoleOutput || '[Hệ thống sẵn sàng... Chờ lệnh ma thuật]\n'}
              placeholder="Console output will display here..."
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default SystemData;
