import { useState } from 'react';
import { searchDocuments } from '../../services/api';
import './SearchPage.css';

const SearchPage = () => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [searchPerformed, setSearchPerformed] = useState(false);
  const [warning, setWarning] = useState('');

  const handleSearch = async (e) => {
    e.preventDefault();
    
    if (!query.trim()) {
      setError('Wprowadź zapytanie');
      return;
    }

    setLoading(true);
    setError('');
    setWarning('');
    setSearchPerformed(true);

    try {
      const data = await searchDocuments(query);
      setResults(data.results);
      if (data.warning) {
        setWarning(data.warning);
      }
    } catch (err) {
      setError('Błąd podczas wyszukiwania: ' + err.message);
      setResults([]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="search-page">
      <div className="search-container">
        <div className="search-header">
          <h1>Wyszukaj w dokumentach PDF</h1>
          <p>Przeszukuj dokumenty używając polskiego stemmera i filtrów</p>
        </div>

        <form onSubmit={handleSearch} className="search-form">
          <div className="search-input-group">
            <input
              type="search"
              placeholder="Zapytanie..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="search-input"
            />
            <button type="submit" disabled={loading} className="search-button">
              {loading ? 'Szukam...' : 'Szukaj'}
            </button>
          </div>
        </form>

        {error && (
          <div className="error-message">
            {error}
          </div>
        )}

        {warning && (
          <div className="warning-message">
            {warning}
          </div>
        )}

        {loading && <div className="spinner"></div>}

        {!loading && searchPerformed && results.length === 0 && (
          <div className="no-results">
            <p>Nie znaleziono dokumentów dla zapytania: <strong>{query}</strong></p>
          </div>
        )}

        {!loading && results.length > 0 && (
          <div className="results-container">
            <div className="results-header">
              <h2>Znaleziono {results.length} wyników</h2>
            </div>
            
            <div className="results-list">
              {results.map((result) => (
                <div key={result.id} className="result-card card">
                  <div className="result-header">
                    <h3 className="result-filename">{result.filename}</h3>
                    <span className="result-score">
                      Trafność: {result.score.toFixed(2)}
                    </span>
                  </div>
                  
                  <div className="result-meta">
                    {result.author && result.author !== 'unknown' && (
                      <span>{result.author}</span>
                    )}
                    {result.created_at && (
                      <span>{new Date(result.created_at).toLocaleDateString('pl-PL')}</span>
                    )}
                  </div>

                  {result.highlights && result.highlights.length > 0 && (
                    <div className="result-highlights">
                      {result.highlights.map((highlight, idx) => (
                        <p 
                          key={idx} 
                          className="highlight-snippet"
                          dangerouslySetInnerHTML={{ __html: '...' + highlight + '...' }}
                        />
                      ))}
                    </div>
                  )}

                  <div className="result-actions">
                    <a 
                      href={`http://localhost:3000/api/doc/${result.id}/download`}
                      className="download-button"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      Pobierz PDF
                    </a>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default SearchPage;
