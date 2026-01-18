const fs = require('fs').promises;
const path = require('path');
const { client, INDEX_NAME } = require('../config/elasticsearch');
const { extractTextFromPDF, extractMetadataFromPDF } = require('../utils/tika');

const STORAGE_PATH = process.env.STORAGE_PATH || path.join(__dirname, '../../storage');

async function uploadDocument(req, res) {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Brak pliku' });
    }

    const plik = req.file;
    const sciezka = plik.path;
    
    console.log(`Przetwarzanie: ${plik.originalname}`);

    // wyciąganie tekstu z PDFa przez Tikę
    const tekst = await extractTextFromPDF(sciezka);
    // wyciąganie metadanych (autor, data)
    const meta = await extractMetadataFromPDF(sciezka);
    
    // do zapisania
    const dokument = {
      filename: plik.originalname,
      content: tekst,
      author: meta['dc:creator'] || meta['meta:author'] || 'unknown',
      created_at: meta['dcterms:created'] || new Date().toISOString(),
      file_size: plik.size,
      upload_date: new Date().toISOString(),
      file_path: path.basename(sciezka)
    };

    const wynik = await client.index({
      index: INDEX_NAME,
      body: dokument,
      refresh: true
    });

    console.log(`Zapisano: ${wynik._id}`);

    res.status(201).json({
      success: true,
      documentId: wynik._id,
      filename: plik.originalname,
      message: 'Dokument zaindeksowany'
    });

  } catch (err) {
    console.error('Błąd uploadu:', err);
    
    if (req.file) {
      try {
        await fs.unlink(req.file.path);
      } catch (e) {
        console.error('Nie udało się usunąć pliku:', e);
      }
    }
    
    res.status(500).json({ 
      error: 'Nie udało się przetworzyć',
      details: err.message 
    });
  }
}

module.exports = {
  uploadDocument
};
