const { client, INDEX_NAME } = require('../config/elasticsearch');

async function searchDocuments(req, res) {
  try {
    const { q, page = 1, size = 10 } = req.query;

    if (!q) {
      return res.status(400).json({ error: 'Brak zapytania' });
    }

    // sprawdzanie czy zapytanie to same stopwords
    const analiza = await client.indices.analyze({
      index: INDEX_NAME,
      field: 'content',
      text: q
    });

    const tokeny = analiza.tokens || [];
    const samoStopwords = tokeny.length === 0 && q.trim().length > 0;

    const od = (page - 1) * size;

    // wyszukiwanie w ES
    const wynik = await client.search({
      index: INDEX_NAME,
      body: {
        from: od,
        size: parseInt(size),
        query: {
          multi_match: {
            query: q,
            fields: ['content', 'filename^2', 'author'],
            fuzziness: 'AUTO'  // pozwalanie na literówki
          }
        },
        highlight: {
          fields: {
            content: {
              fragment_size: 150,
              number_of_fragments: 3,
              pre_tags: ['<mark>'],
              post_tags: ['</mark>']
            }
          }
        },
        sort: [
          { _score: 'desc' },  // najpierw po score
          { upload_date: 'desc' }  // potem po dacie
        ]
      }
    });

    const trafienia = wynik.hits.hits.map(hit => ({
      id: hit._id,
      score: hit._score,
      filename: hit._source.filename,
      author: hit._source.author,
      created_at: hit._source.created_at,
      upload_date: hit._source.upload_date,
      highlights: hit.highlight?.content || []
    }));

    res.json({
      success: true,
      total: wynik.hits.total.value,
      page: parseInt(page),
      size: parseInt(size),
      results: trafienia,
      warning: samoStopwords ? 'Samo stopwords - pominięte' : undefined
    });

  } catch (err) {
    console.error('Błąd wyszukiwania:', err);
    res.status(500).json({ 
      error: 'Nie udało się wyszukać',
      details: err.message 
    });
  }
}

// funkcja testowa - jak analyzer rozbija tekst na tokeny
async function analyzeQuery(req, res) {
  try {
    const { text, analyzer = 'pl_analyzer' } = req.body;

    if (!text) {
      return res.status(400).json({ error: 'Brak tekstu' });
    }

    const wynik = await client.indices.analyze({
      index: INDEX_NAME,
      body: {
        analyzer: analyzer,
        text: text
      }
    });

    const tokeny = wynik.tokens.map(t => t.token);

    res.json({
      success: true,
      original: text,
      analyzer: analyzer,
      tokens: tokeny
    });

  } catch (err) {
    console.error('Błąd analizy:', err);
    res.status(500).json({ 
      error: 'Nie udało się zanalizować',
      details: err.message 
    });
  }
}

module.exports = {
  searchDocuments,
  analyzeQuery
};
