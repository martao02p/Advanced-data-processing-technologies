# PDF Search - Wyszukiwarka dokumentów PDF

System wyszukiwania pełnotekstowego w dokumentach PDF z wykorzystaniem Elasticsearch i polskiego analizera morfologicznego. Projekt umożliwia przesyłanie dokumentów PDF, indeksowanie ich zawartości oraz zaawansowane wyszukiwanie z wyróżnianiem znalezionych fraz.


## Demo



https://github.com/user-attachments/assets/9496fef9-d5c7-4c5c-8941-33e507906ed4



## Funkcjonalności

- **Upload dokumentów PDF** - przesyłanie plików przez drag & drop lub wybór pliku
- **Wyszukiwanie pełnotekstowe** - zaawansowane wyszukiwanie z obsługą polskiego stemmera
- **Highlighting** - wyróżnianie znalezionych fraz w wynikach
- **Zarządzanie dokumentami** - przeglądanie, pobieranie i usuwanie dokumentów
- **Analiza morfologiczna** - obsługa polskich stopwords i stemmingu

## Technologie

**Backend:**
- Node.js + Express
- Elasticsearch 8.17.0 (z pluginem analysis-stempel)
- Apache Tika 2.9.2.1 (ekstrakcja tekstu z PDF)

**Frontend:**
- React 19
- Vite
- React Router
- Axios

## Wymagania

- Docker & Docker Compose
- Node.js 18+ 
- npm

## Instalacja

### 1. Sklonowanie repozytorium
```bash
git clone https://github.com/martao02p/Advanced-data-processing-technologies
cd pdf-search-elastic
```

### 2. Docker (Elasticsearch + Tika)
```bash
docker-compose up -d
```

```bash
docker ps
```

### 3. Backend
```bash
cd backend
npm install
npm run dev
```

Backend wystartuje na `http://localhost:3000`

### 4. Frontend
```bash
cd frontend
npm install
npm run dev
```

Frontend będzie dostępny pod `http://localhost:5173`

## Użytkowanie

1. **Upload dokumentów**
   - Przejście do zakładki *Upload*
   - Przeciągnięcie pliku PDF lub kliknięcie *Wybierz plik*
   - Dokument zostanie automatycznie przetworzony i zaindeksowany

2. **Wyszukiwanie**
   - Wpisywanie zapytań w pole wyszukiwania
   - System automatycznie stosuje polski stemmer
   - Wyniki zawierają wyróżnione fragmenty tekstu

3. **Zarządzanie dokumentami**
   - Zakładka *Dokumenty* pokazuje wszystkie zaindeksowane pliki
   - Możliwość pobrania lub usunięcia dokumentu

## Konfiguracja

### Zmienne środowiskowe Backend (backend/.env)
```env
PORT=3000
ELASTICSEARCH_URL=http://localhost:9200
TIKA_URL=http://localhost:9998
INDEX_NAME=pdfs
STORAGE_PATH=./storage
```

### Zmienne środowiskowe Frontend (frontend/.env)
```env
VITE_API_URL=http://localhost:3000/api
```

## API Endpoints

- `POST /api/upload` - Upload PDF
- `GET /api/search?q=zapytanie` - Wyszukiwanie
- `GET /api/documents` - Lista dokumentów
- `GET /api/doc/:id` - Metadane dokumentu
- `GET /api/doc/:id/download` - Pobierz PDF
- `DELETE /api/doc/:id` - Usuń dokument
- `POST /api/analyze` - Test analizera (stemmer)

<br>

---
<br>
Projekt stworzony w ramach kursu ZTPD.
