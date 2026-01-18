import { useState, useEffect } from 'react';
import { getDocuments, getDownloadUrl, deleteDocument } from '../../services/api';
import './DocumentsPage.css';

const DocumentsPage = () => {
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [total, setTotal] = useState(0);
  const [deleting, setDeleting] = useState(null);

  useEffect(() => {
    fetchDocuments();
  }, []);

  const fetchDocuments = async () => {
    setLoading(true);
    setError('');

    try {
      const data = await getDocuments(1, 100);
      setDocuments(data.documents);
      setTotal(data.total);
    } catch (err) {
      setError('Błąd podczas pobierania dokumentów: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id, filename) => {
    if (!confirm(`Czy na pewno chcesz usunąć dokument "${filename}"?`)) {
      return;
    }

    setDeleting(id);
    try {
      await deleteDocument(id);
      await fetchDocuments();
    } catch (err) {
      setError('Błąd podczas usuwania: ' + err.message);
    } finally {
      setDeleting(null);
    }
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'Brak daty';
    return new Date(dateString).toLocaleDateString('pl-PL', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  const formatFileSize = (bytes) => {
    if (!bytes) return 'Brak danych';
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
    return (bytes / 1024 / 1024).toFixed(2) + ' MB';
  };

  return (
    <div className="documents-page">
      <div className="documents-header">
        <h1>Wszystkie dokumenty</h1>
        <p>Lista {total} zaindeksowanych dokumentów PDF</p>
      </div>

      {error && <div className="error-message">{error}</div>}
      {loading && <div className="spinner"></div>}

      {!loading && documents.length === 0 && (
        <div className="no-documents card">
          <p>Brak dokumentów w bazie.</p>
          <p>Przejdź do zakładki Upload, aby dodać dokumenty.</p>
        </div>
      )}

      {!loading && documents.length > 0 && (
        <>
          <div className="documents-grid">
              {documents.map((doc) => (
                <div key={doc.id} className="document-card card">
                  <div className="document-icon">
                    <img src="/article.png" alt="PDF" />
                  </div>
                  
                  <div className="document-info">
                    <h3 className="document-name">{doc.filename}</h3>
                    
                    <div className="document-meta">
                      {doc.author && doc.author !== 'unknown' && (
                        <div className="meta-item">
                          <span className="meta-label">Autor:</span>
                          <span className="meta-value">{doc.author}</span>
                        </div>
                      )}
                      
                      {doc.created_at && (
                        <div className="meta-item">
                          <span className="meta-label">Utworzono:</span>
                          <span className="meta-value">{formatDate(doc.created_at)}</span>
                        </div>
                      )}
                      
                      <div className="meta-item">
                        <span className="meta-label">Przesłano:</span>
                        <span className="meta-value">{formatDate(doc.upload_date)}</span>
                      </div>
                      
                      <div className="meta-item">
                        <span className="meta-label">Rozmiar:</span>
                        <span className="meta-value">{formatFileSize(doc.file_size)}</span>
                      </div>
                    </div>
                  </div>

                  <div className="document-actions">
                    <a
                      href={getDownloadUrl(doc.id)}
                      className="download-link"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      Pobierz
                    </a>
                    <button
                      onClick={() => handleDelete(doc.id, doc.filename)}
                      disabled={deleting === doc.id}
                      className="delete-button"
                    >
                      {deleting === doc.id ? '...' : 'Usuń'}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
    </div>
  );
};

export default DocumentsPage;
