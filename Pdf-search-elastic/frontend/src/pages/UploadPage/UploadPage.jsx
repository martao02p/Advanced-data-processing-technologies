import { useState } from 'react';
import { uploadPDF } from '../../services/api';
import './UploadPage.css';

const UploadPage = () => {
  const [file, setFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');
  const [dragActive, setDragActive] = useState(false);

  const handleFileChange = (e) => {
    const selectedFile = e.target.files[0];
    if (selectedFile && selectedFile.type === 'application/pdf') {
      setFile(selectedFile);
      setError('');
      setSuccess('');
    } else {
      setError('Wybierz plik PDF');
      setFile(null);
    }
  };

  const handleDrag = (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true);
    } else if (e.type === 'dragleave') {
      setDragActive(false);
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);

    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      const droppedFile = e.dataTransfer.files[0];
      if (droppedFile.type === 'application/pdf') {
        setFile(droppedFile);
        setError('');
        setSuccess('');
      } else {
        setError('Wybierz plik PDF');
      }
    }
  };

  const handleUpload = async (e) => {
    e.preventDefault();

    if (!file) {
      setError('Wybierz plik PDF');
      return;
    }

    setUploading(true);
    setError('');
    setSuccess('');

    try {
      const result = await uploadPDF(file);
      setSuccess(`Plik "${result.filename}" został pomyślnie przesłany i zaindeksowany!`);
      setFile(null);
      const fileInput = document.getElementById('file-input');
      if (fileInput) fileInput.value = '';
    } catch (err) {
      setError('Błąd podczas uploadu: ' + (err.response?.data?.error || err.message));
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="upload-page">
      <div className="upload-container">
        <div className="upload-header">
          <h1>Upload PDF</h1>
          <p>Prześlij dokumenty PDF do indeksowania i wyszukiwania</p>
        </div>

        <form onSubmit={handleUpload} className="upload-form">
          <div
            className={`drop-zone ${dragActive ? 'active' : ''} ${file ? 'has-file' : ''}`}
            onDragEnter={handleDrag}
            onDragLeave={handleDrag}
            onDragOver={handleDrag}
            onDrop={handleDrop}
          >
            <input
              id="file-input"
              type="file"
              accept="application/pdf"
              onChange={handleFileChange}
              className="file-input"
            />
            
            {!file ? (
              <div className="drop-zone-content">
                <div className="drop-icon">
                  <img src="/search2-rb.png" alt="Upload" />
                </div>
                <p className="drop-text">Przeciągnij i upuść plik PDF tutaj</p>
                <p className="drop-text-small">lub</p>
                <label htmlFor="file-input" className="file-label">
                  Wybierz plik
                </label>
              </div>
            ) : (
              <div className="file-info">
                <div className="file-icon">📄</div>
                <div className="file-details">
                  <p className="file-name">{file.name}</p>
                  <p className="file-size">
                    {(file.size / 1024 / 1024).toFixed(2)} MB
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => setFile(null)}
                  className="remove-file"
                >
                  ✕
                </button>
              </div>
            )}
          </div>

          {file && (
            <button
              type="submit"
              disabled={uploading}
              className="upload-button"
            >
              {uploading ? 'Przesyłanie...' : 'Prześlij i zaindeksuj'}
            </button>
          )}
        </form>

        {error && (
          <div className="message error-message">
            {error}
          </div>
        )}

        {success && (
          <div className="message success-message">
            {success}
          </div>
        )}

        <div className="upload-info card">
          <h3>Informacje</h3>
          <ul>
            <li>Maksymalny rozmiar pliku: 50 MB</li>
            <li>Obsługiwane formaty: PDF</li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default UploadPage;
