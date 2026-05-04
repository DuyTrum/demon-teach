import React from 'react';
import { useNavigate } from 'react-router-dom';
import { authService } from '../../services/authService';
import { toast } from 'react-toastify';
import './Header.css';

const Header: React.FC = () => {
  const navigate = useNavigate();
  const user = authService.getStoredUser();

  const handleLogout = async () => {
    try {
      await authService.logout();
      toast.success('Logged out successfully');
      navigate('/login');
    } catch (error) {
      toast.error('Logout failed');
    }
  };

  return (
    <header className="header">
      <div className="header-left">
        <h1 className="header-title" onClick={() => navigate('/')}>Demon Teach Admin</h1>
        <nav className="header-nav">
          <button onClick={() => navigate('/lessons')} className="nav-link">Lessons</button>
          <button onClick={() => navigate('/generator')} className="nav-link">AI Generator</button>
        </nav>
      </div>

      <div className="header-right">
        <span className="user-email">{user?.email}</span>
        <button onClick={handleLogout} className="btn-logout">
          Logout
        </button>
      </div>
    </header>
  );
};

export default Header;
