const { Client } = require('@elastic/elasticsearch');

const ELASTICSEARCH_URL = process.env.ELASTICSEARCH_URL || 'http://localhost:9200';
const INDEX_NAME = process.env.INDEX_NAME || 'pdfs';

// klient do połączenia z ES
const client = new Client({ node: ELASTICSEARCH_URL });

// konfiguracja indeksu z polskim analyzerem
const indexSettings = {
  settings: {
    analysis: {
      filter: {
        // usuwanie polskich stopwords
        polish_stop: {
          type: 'stop',
          stopwords: '_polish_'
        }
      },
      analyzer: {
        // użycie gotowego analyzera polish z pluginu stempel
        pl_analyzer: {
          type: 'polish'
        }
      }
    }
  },
  mappings: {
    properties: {
      filename: { type: 'keyword' },
      content: {
        type: 'text',
        analyzer: 'pl_analyzer',
        fields: {
          keyword: { type: 'keyword' }  // dodatkowe zapisanie jako keyword
        }
      },
      author: { type: 'keyword' },
      created_at: { type: 'date' },
      file_size: { type: 'long' },
      upload_date: { type: 'date' }
    }
  }
};

// tworzenie indeksu w ES jeśli jeszcze nie istnieje
async function initIndex() {
  try {
    const istnieje = await client.indices.exists({ index: INDEX_NAME });
    
    if (!istnieje) {
      // tworzenie nowego indeksu z polskim analyzerem
      await client.indices.create({
        index: INDEX_NAME,
        body: indexSettings
      });
      console.log(`Indeks "${INDEX_NAME}" utworzony`);
    } else {
      console.log(`Indeks "${INDEX_NAME}" już jest`);
    }
  } catch (err) {
    console.error('Błąd przy tworzeniu indeksu:', err.message);
    throw err;
  }
}

// sprawdzanie czy można się połączyć z ES
async function checkConnection() {
  try {
    const health = await client.cluster.health();
    console.log('Elasticsearch OK:', health.cluster_name);
    return true;
  } catch (err) {
    console.error('Nie można połączyć z Elasticsearch:', err.message);
    return false;
  }
}

module.exports = {
  client,
  INDEX_NAME,
  initIndex,
  checkConnection
};
