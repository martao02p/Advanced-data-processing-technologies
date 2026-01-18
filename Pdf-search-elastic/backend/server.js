require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { checkConnection, initIndex } = require('./config/elasticsearch');
const { checkTikaConnection } = require('./utils/tika');
const apiRoutes = require('./routes/api');

const app = express();
const PORT = process.env.PORT || 3000;

// podstawowe middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// logowanie requestów
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// healthcheck
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// routing
app.use('/api', apiRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint nie znaleziony' });
});

// error handler
app.use((err, req, res, next) => {
  console.error('Błąd:', err);
  res.status(500).json({ 
    error: 'Błąd serwera',
    details: err.message 
  });
});


async function startServer() {
  try {
    console.log('Uruchamianie...\n');
    
    // czy ES działa
    const esOk = await checkConnection();
    if (!esOk) {
      throw new Error('Elasticsearch nie działa');
    }
    
    // tworzenie indeksu jeśli nie ma
    await initIndex();
    
    // czy Tika działa
    const tikaOk = await checkTikaConnection();
    if (!tikaOk) {
      console.warn('UWAGA: Tika nie działa');
    }
    
    // odpalanie serwera
    app.listen(PORT, () => {
      console.log(`\nSerwer na http://localhost:${PORT}`);
    });
    
  } catch (err) {
    console.error('Nie udało się wystartować:', err.message);
    process.exit(1);
  }
}

startServer();
