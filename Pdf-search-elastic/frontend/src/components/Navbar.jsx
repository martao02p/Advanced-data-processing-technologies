import { Link, useLocation } from 'react-router-dom';
import './Navbar.css';

const Navbar = () => {
  const location = useLocation();

  return (
    <nav className="navbar">
      <div className="navbar-container">
        <div className="navbar-left">
          <img src="/icon.png" alt="Logo" className="navbar-icon" />
          <Link to="/" className="navbar-logo">
            PDF Research
          </Link>
        </div>
        <div className="navbar-links">
          <Link 
            to="/" 
            className={location.pathname === '/' ? 'active' : ''}
          >
            Wyszukiwanie
          </Link>
          <Link 
            to="/upload" 
            className={location.pathname === '/upload' ? 'active' : ''}
          >
            Upload
          </Link>
          <Link 
            to="/documents" 
            className={location.pathname === '/documents' ? 'active' : ''}
          >
            Dokumenty
          </Link>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
