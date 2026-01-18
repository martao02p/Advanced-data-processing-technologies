const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');
const { uploadDocument } = require('../controllers/uploadController');
const { searchDocuments, analyzeQuery } = require('../controllers/searchController');
const { getDocument, downloadDocument, listDocuments } = require('../controllers/documentController');
const { deleteDocument } = require('../controllers/deleteController');

router.post('/upload', upload.single('file'), uploadDocument);
router.get('/search', searchDocuments);
router.post('/analyze', analyzeQuery);
router.get('/documents', listDocuments);
router.get('/doc/:id', getDocument);
router.get('/doc/:id/download', downloadDocument);
router.delete('/doc/:id', deleteDocument);

module.exports = router;
