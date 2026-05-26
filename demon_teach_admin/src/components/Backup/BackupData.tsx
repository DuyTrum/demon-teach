import React, { useRef, useState } from 'react';
import { adminService } from '../../services/adminService';
import { toast } from 'react-toastify';
import './BackupData.css';

const BackupData: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [importedData, setImportedData] = useState<any>(null);
  const [fileName, setFileName] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleExport = async () => {
    setLoading(true);
    try {
      const data = await adminService.exportBackup();
      
      // Create and download file
      const jsonString = `data:text/json;charset=utf-8,${encodeURIComponent(
        JSON.stringify(data, null, 2)
      )}`;
      const downloadAnchor = document.createElement('a');
      downloadAnchor.setAttribute('href', jsonString);
      
      const dateStr = new Date().toISOString().split('T')[0];
      downloadAnchor.setAttribute('download', `demonteach_backup_${dateStr}.json`);
      document.body.appendChild(downloadAnchor);
      downloadAnchor.click();
      downloadAnchor.remove();

      toast.success('Xuất bản sao lưu dữ liệu thành công!');
    } catch (error) {
      console.error(error);
      toast.error('Lỗi khi xuất bản sao lưu');
    } finally {
      setLoading(false);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setFileName(file.name);
    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const parsed = JSON.parse(event.target?.result as string);
        setImportedData(parsed);
        toast.info(`Đã đọc tệp sao lưu. Sẵn sàng khôi phục.`);
      } catch (err) {
        console.error(err);
        toast.error('Định dạng tệp JSON không hợp lệ');
        setImportedData(null);
        setFileName('');
      }
    };
    reader.readAsText(file);
  };

  const handleImport = async () => {
    if (!importedData) return;

    if (!window.confirm('⚠️ XÁC NHẬN GHI ĐÈ DỮ LIỆU ⚠️\nBạn có chắc chắn muốn nạp bản sao lưu này?\nCác tài liệu trùng ID sẽ bị ghi đè dữ liệu mới!')) {
      return;
    }

    setLoading(true);
    try {
      const response = await adminService.importBackup(importedData);
      toast.success(response.message || 'Khôi phục dữ liệu thành công!');
      setImportedData(null);
      setFileName('');
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    } catch (error) {
      console.error(error);
      toast.error('Lỗi khi nạp khôi phục dữ liệu');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="backup-data-container">
      <div className="backup-header">
        <h2>Sao Lưu & Khôi Phục Dữ Liệu 💾</h2>
        <p>Xuất toàn bộ cơ sở dữ liệu Firestore sang tệp JSON hoặc nhập lại dữ liệu cũ</p>
      </div>

      <div className="backup-grid">
        {/* Export Panel */}
        <div className="backup-card glass-panel purple-glow">
          <div className="card-header-icon">📥</div>
          <h3>Xuất Sao Lưu (Export)</h3>
          <p>Tải xuống bản sao lưu đầy đủ của hệ thống bao gồm: thông tin người dùng, tiến trình học, bài học, và các cài đặt khác dưới dạng tệp tin `.json`.</p>
          
          <button
            onClick={handleExport}
            disabled={loading}
            className="btn-backup btn-export"
          >
            {loading ? 'Đang đóng gói...' : 'Tải Bản Sao Lưu (.JSON) 📥'}
          </button>
        </div>

        {/* Import Panel */}
        <div className="backup-card glass-panel orange-glow">
          <div className="card-header-icon">📤</div>
          <h3>Khôi Phục Dữ Liệu (Import)</h3>
          <p>Tải lên tệp sao lưu định dạng `.json` đã lưu từ trước để khôi phục toàn bộ trạng thái dữ liệu của hệ thống.</p>
          
          <div className="upload-section">
            <input
              type="file"
              accept=".json"
              ref={fileInputRef}
              onChange={handleFileChange}
              style={{ display: 'none' }}
              id="backup-file-upload"
            />
            <label htmlFor="backup-file-upload" className="file-upload-label">
              {fileName ? `📂 ${fileName}` : 'Chọn tệp sao lưu JSON...'}
            </label>
          </div>

          {importedData && (
            <div className="backup-preview glass-panel">
              <h4>Chi tiết tệp sao lưu:</h4>
              <ul>
                {Object.keys(importedData).map((key) => (
                  <li key={key}>
                    Collection <strong>{key}</strong>: {Array.isArray(importedData[key]) ? `${importedData[key].length} dòng` : '0 dòng'}
                  </li>
                ))}
              </ul>
              <button
                onClick={handleImport}
                disabled={loading}
                className="btn-backup btn-import"
              >
                {loading ? 'Đang ghi đè dữ liệu...' : 'Xác Nhận Khôi Phục Dữ Liệu 📤'}
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default BackupData;
