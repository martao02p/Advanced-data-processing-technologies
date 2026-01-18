const { client, INDEX_NAME } = require('../config/elasticsearch');
const fs = require('fs').promises;
const path = require('path');

const STORAGE_PATH = process.env.STORAGE_PATH || path.join(__dirname, '../../storage');

// usuwanie dokumentu z ES i pliku z dysku
async function deleteDocument(req, res) {
  try {
    const { id } = req.params;

    // najpierw pobieranie dokumentu żeby znać ścieżkę do pliku
    const wynik = await client.get({
      index: INDEX_NAME,
      id: id
    });

    if (!wynik.found) {
      return res.status(404).json({ error: 'Nie ma takiego dokumentu' });
    }

    const dok = wynik._source;

    // usuwanie pliku z dysku jeśli istnieje
    if (dok.file_path) {
      const sciezka = path.join(STORAGE_PATH, dok.file_path);
      
      try {
        await fs.unlink(sciezka);
        console.log(`Usunięto plik: ${dok.file_path}`);
      } catch (err) {
        console.warn('Nie udało się usunąć pliku:', err.message);
      }
    }

    // usuwanie z Elasticsearch
    await client.delete({
      index: INDEX_NAME,
      id: id,
      refresh: true
    });

    console.log(`Usunięto dokument: ${id}`);

    res.json({
      success: true,
      message: 'Dokument usunięty'
    });

  } catch (err) {
    console.error('Błąd usuwania:', err);
    
    if (err.meta?.statusCode === 404) {
      return res.status(404).json({ error: 'Nie ma takiego dokumentu' });
    }
    
    res.status(500).json({ 
      error: 'Nie udało się usunąć',
      details: err.message 
    });
  }
}

module.exports = {
  deleteDocument
};
