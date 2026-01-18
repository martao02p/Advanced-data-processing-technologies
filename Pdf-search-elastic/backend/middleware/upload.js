const multer = require('multer');
const path = require('path');
const fs = require('fs');

const STORAGE_PATH = process.env.STORAGE_PATH || path.join(__dirname, '../../storage');

if (!fs.existsSync(STORAGE_PATH)) {
  fs.mkdirSync(STORAGE_PATH, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, STORAGE_PATH);
  },
  filename: function (req, file, cb) {
    const nazwaPliku = `${Date.now()}-${file.originalname}`;
    cb(null, nazwaPliku);
  }
});

// filtr - akceptowanie tylko PDFów
const fileFilter = (req, file, cb) => {
  if (file.mimetype === 'application/pdf') {
    cb(null, true);
  } else {
    cb(new Error('Tylko PDFy!'), false);
  }
};

// główna konfiguracja multera
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 50 * 1024 * 1024  // max 50MB
  }
});

module.exports = upload;
