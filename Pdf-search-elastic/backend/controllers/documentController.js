const fs = require('fs').promises;
const path = require('path');
const { client, INDEX_NAME } = require('../config/elasticsearch');

const STORAGE_PATH = process.env.STORAGE_PATH || path.join(__dirname, '../../storage');

// zwracanie pojedynczego dokumentu po ID
async function getDocument(req, res) {
  try {
    const { id } = req.params;

    // pobieranie z ES
    const wynik = await client.get({
      index: INDEX_NAME,
      id: id
    });

    if (!wynik.found) {
      return res.status(404).json({ error: 'Nie ma takiego dokumentu' });
    }

    const dok = wynik._source;
    
    res.json({
      success: true,
      document: {
        id: wynik._id,
        filename: dok.filename,
        author: dok.author,
        created_at: dok.created_at,
        upload_date: dok.upload_date,
        file_size: dok.file_size,
        content_preview: dok.content.substring(0, 500) + '...'
      }
    });

  } catch (err) {
    console.error('Błąd pobierania dokumentu:', err);
    
    if (err.meta?.statusCode === 404) {
      return res.status(404).json({ error: 'Nie ma takiego' });
    }
    
    res.status(500).json({ 
      error: 'Nie udało się pobrać',
      details: err.message 
    });
  }
}

// dawanie możliwości pobrania pliku PDFa
async function downloadDocument(req, res) {
  try {
    const { id } = req.params;

    // pobieranie info z ES
    const wynik = await client.get({
      index: INDEX_NAME,
      id: id
    });

    if (!wynik.found) {
      return res.status(404).json({ error: 'Nie ma takiego' });
    }

    const dok = wynik._source;
    
    if (!dok.file_path) {
      return res.status(404).json({ error: 'Dokument bez pliku' });
    }
    
    const sciezka = path.join(STORAGE_PATH, dok.file_path);

    // sprawdzanie czy plik istnieje na dysku
    try {
      await fs.access(sciezka);
    } catch {
      return res.status(404).json({ error: 'Brak pliku na dysku' });
    }

    res.download(sciezka, dok.filename);

  } catch (err) {
    console.error('Błąd pobierania pliku:', err);
    
    if (err.meta?.statusCode === 404) {
      return res.status(404).json({ error: 'Nie ma takiego' });
    }
    
    res.status(500).json({ 
      error: 'Nie udało się pobrać pliku',
      details: err.message 
    });
  }
}

// zwracanie listy wszystkich dokumentów
async function listDocuments(req, res) {
  try {
    const { page = 1, size = 20 } = req.query;
    const od = (page - 1) * size;

    // pobieranie wszystkiego z ES posortowanego po dacie
    const wynik = await client.search({
      index: INDEX_NAME,
      body: {
        from: od,
        size: parseInt(size),
        query: {
          match_all: {}
        },
        sort: [
          { upload_date: 'desc' }
        ],
        _source: ['filename', 'author', 'created_at', 'upload_date', 'file_size']
      }
    });

    const dokumenty = wynik.hits.hits.map(hit => ({
      id: hit._id,
      ...hit._source
    }));

    res.json({
      success: true,
      total: wynik.hits.total.value,
      page: parseInt(page),
      size: parseInt(size),
      documents: dokumenty
    });

  } catch (err) {
    console.error('Błąd listowania:', err);
    res.status(500).json({ 
      error: 'Nie udało się pobrać listy',
      details: err.message 
    });
  }
}

module.exports = {
  getDocument,
  downloadDocument,
  listDocuments
};
