import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import SearchPage from './pages/SearchPage/SearchPage';
import UploadPage from './pages/UploadPage/UploadPage';
import DocumentsPage from './pages/DocumentsPage/DocumentsPage';
import './App.css';

function App() {
  return (
    <Router>
      <div className="App">
        <Navbar />
        <main className="main-content">
          <Routes>
            <Route path="/" element={<SearchPage />} />
            <Route path="/upload" element={<UploadPage />} />
            <Route path="/documents" element={<DocumentsPage />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;
