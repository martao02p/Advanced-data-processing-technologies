const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

const TIKA_URL = process.env.TIKA_URL || 'http://localhost:9998';

// wyciąganie tekstu z PDFa przez Tikę
async function extractTextFromPDF(filePath) {
  try {
    const plik = fs.createReadStream(filePath);
    
    // wysyłanie PDFa do Tiki i dostawanie tekstu z powrotem
    const res = await axios.put(`${TIKA_URL}/tika`, plik, {
      headers: {
        'Content-Type': 'application/pdf',
        'Accept': 'text/plain'
      },
      maxContentLength: Infinity,
      maxBodyLength: Infinity
    });

    return res.data;
  } catch (err) {
    console.error('Błąd wyciągania tekstu:', err.message);
    throw new Error('Tika nie mogła wyciągnąć tekstu');
  }
}

// wyciąganie metadanych (autor, data itp) z PDFa
async function extractMetadataFromPDF(filePath) {
  try {
    const plik = fs.createReadStream(filePath);
    
    // wysyłanie do Tiki endpoint /meta
    const res = await axios.put(`${TIKA_URL}/meta`, plik, {
      headers: {
        'Content-Type': 'application/pdf',
        'Accept': 'application/json'
      },
      maxContentLength: Infinity,
      maxBodyLength: Infinity
    });

    return res.data;
  } catch (err) {
    console.error('Błąd wyciągania metadanych:', err.message);
    return {};
  }
}

// pingowanie Tiki żeby sprawdzić czy żyje
async function checkTikaConnection() {
  try {
    await axios.get(`${TIKA_URL}/tika`);
    console.log('Tika OK');
    return true;
  } catch (err) {
    console.error('Tika nie działa:', err.message);
    return false;
  }
}

module.exports = {
  extractTextFromPDF,
  extractMetadataFromPDF,
  checkTikaConnection
};
