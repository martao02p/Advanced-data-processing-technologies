# Raport z projektu PDF Search Elastic

## 1. Wprowadzenie

### 1.1 Cel projektu
Stworzenie systemu do indeksowania i przeszukiwania dokumentów PDF w języku polskim z wykorzystaniem Elasticsearch i polskiego analyzera stemmerowego.

### 1.2 Zakres funkcjonalności
- Upload plików PDF z automatyczną ekstrakcją tekstu
- Indeksowanie treści z wykorzystaniem polskiego analyzera (stempel)
- Wyszukiwanie pełnotekstowe z obsługą odmiany słów
- Podświetlanie wyników w kontekście
- Lista wszystkich dokumentów
- Usuwanie dokumentów
- Pobieranie plików PDF

---

## 2. Architektura systemu

### 2.1 Wykorzystane technologie

**Backend:**
- Node.js + Express 5.2.1
- Elasticsearch 8.17.0 (z pluginem analysis-stempel)
- Apache Tika 2.9.2.1 (ekstrakcja tekstu z PDF)
- Multer 2.0.2 (upload plików)

**Frontend:**
- React 19.2.0
- Vite 7.2.4
- React Router DOM
- Axios

**Docker:**
- Elasticsearch + Kibana
- Apache Tika

### 2.2 Architektura aplikacji

Aplikacja składa się z czterech głównych komponentów:

**1. Frontend (React + Vite)** - interfejs
   - Strona wyszukiwania
   - Formularz uploadu plików
   - Lista dokumentów z opcją usuwania
   - Uruchomiony na porcie 5173

**2. Backend (Node.js + Express)** - serwer REST API
   - Obsługa uploadu plików (zapis do folderu `./storage`)
   - Komunikacja z Elasticsearch (indeksowanie, wyszukiwanie)
   - Wywoływanie Tiki do ekstrakcji tekstu z PDF
   - Uruchomiony na porcie 3000

**3. Elasticsearch** - silnik wyszukiwania
   - Przechowuje zaindeksowane dokumenty
   - Wykonuje wyszukiwanie z polskim analyzerem
   - Plugin `analysis-stempel` dla stemmingu
   - Uruchomiony na porcie 9200

**4. Apache Tika** - ekstrakcja tekstu
   - Wyciąga tekst z plików PDF
   - Pobiera metadane (autor, data utworzenia)
   - Uruchomiony na porcie 9998

**Jak to działa:**

*Upload dokumentu:*
1. Użytkownik wybiera PDF i klika "Upload"
2. Frontend wysyła plik do backendu (`POST /api/upload`)
3. Backend zapisuje PDF w folderze `./storage`
4. Backend wysyła plik do Tiki → dostaje tekst i metadane
5. Backend zapisuje dokument w Elasticsearch z analyzerem `pl_analyzer`
6. Frontend dostaje potwierdzenie

*Wyszukiwanie:*

1. Użytkownik wpisuje zapytanie
2. Frontend wysyła request do backendu (`GET /api/search?q=...`)
3. Backend wykonuje zapytanie do Elasticsearch z polskim analyzerem
4. Elasticsearch znajduje dokumenty, stemuje zapytanie i zwraca wyniki z highlighting
5. Frontend pokazuje listę wyników z podświetlonymi fragmentami
   
---

## 3. Konfiguracja polskiego analyzera

### 3.1 Ustawienia indeksu

W projekcie wykorzystałam gotowy analyzer `polish` z pluginu `analysis-stempel`. Plugin ten implementuje algorytm Stempel - polski algorytm stemmingowy opracowany specjalnie dla języka polskiego.

**Główne komponenty analyzera:**
- **Tokenizer `standard`** - dzieli tekst na słowa według białych znaków i interpunkcji
- **Filtr `lowercase`** - konwertuje wszystkie znaki na małe litery
- **Filtr `polish_stop`** - usuwa polskie stopwords (spójniki, przyimki, zaimki)
- **Filtr `polish_stem`** - redukuje słowa do form podstawowych (algorytm Stempel)

### 3.2 Kod konfiguracji

W projekcie wykorzystano gotowy analyzer `polish` z pluginu `analysis-stempel`:

```javascript
const indexSettings = {
  settings: {
    analysis: {
      filter: {
        polish_stop: {
          type: 'stop',
          stopwords: '_polish_'
        }
      },
      analyzer: {
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
          keyword: { type: 'keyword' }
        }
      },
      author: { type: 'keyword' },
      created_at: { type: 'date' },
      file_size: { type: 'long' },
      upload_date: { type: 'date' }
    }
  }
};
```

Analyzer `polish` automatycznie zawiera:
- Tokenizer `standard`
- Filtr `lowercase`
- Filtr `polish_stop` (stopwords)
- Filtr `polish_stem` (stemmer oparty na algorytmie Stempel)

---

## 4. Testy i przykłady użycia

### 4.1 Test: analiza tekstu z polskim analyzerem

Zapytanie:
```json
POST /api/analyze
{
  "text": "książki programowania komputerów",
  "analyzer": "pl_analyzer"
}
```

Wynik:
```bash
$ curl -X POST http://localhost:3000/api/analyze -H "Content-Type: application/json" -d "{\"text\":\"książki programowania komputerów\", \"analyzer\":\"pl_analyzer\"}"

{"success":true,"original":"książki programowania komputerów","analyzer":"pl_analyzer","tokens":["książ","programować","komputer"]}
```


### 4.2 Test: standard analyzer (dla porównania)

Zapytanie:
```json
POST /api/analyze
{
  "text": "książki programowania komputerów",
  "analyzer": "standard"
}
```

Wynik:
```bash
$ curl -X POST http://localhost:3000/api/analyze -H "Content-Type: application/json" -d "{\"text\":\"książki programowania komputerów\", \"analyzer\":\"standard\"}"

{"success":true,"original":"książki programowania komputerów","analyzer":"standard","tokens":["książki","programowania","komputerów"]}
```

### 4.3 Test: filtrowanie stopwords

Zapytanie zawierające tylko stopwords:

```bash
$ curl -X POST http://localhost:3000/api/analyze -H "Content-Type: application/json" -d "{\"text\":\"w i na z o do\", \"analyzer\":\"pl_analyzer\"}"

{"success":true,"original":"w i na z o do","analyzer":"pl_analyzer","tokens":[]}
```

Wszystkie tokeny zostały usunięte przez filtr `polish_stop`.

### 4.4 Test: wyszukiwanie z highlighting

1. Upload dokumentu PDF:

```bash
$ curl -X POST http://localhost:3000/api/upload -F "file=@LOB.pdf"

{"success":true,"documentId":"Z3Vl0psB_zRNsPIuWJbp","filename":"LOB.pdf","message":"Dokument zaindeksowany"}
```

2. Wyszukanie coś w dokumencie, na przykład:

```bash
$ curl "http://localhost:3000/api/search?q=zapytanie&size=1"

{"success":true,"total":1,"page":1,"size":1,"results":[{"id":"Z3Vl0psB_zRNsPIuWJbp","score":0.2063951,"filename":"LOB.pdf","author":"Marek Wojciechowski","created_at":"2018-10-20T20:23:20Z","upload_date":"2026-01-18T18:36:56.257Z","highlights":["INSTR, SUBSTR (dla znakowych i binarnych LOB) \n\n– LOADFROMFILE , LOADBLOBFROMFILE , LOADCLOBFROMFILE  \n\n– READ, WRITE, WRITEAPPEND \n\n \n\n\n\nOtwieranie i <mark>zamykanie</mark>"]}]}
```

### 4.5 Test: zarządzanie dokumentami (upload i usuwanie)

1. Lista dokumentów przed uploadem:

```bash
$ curl http://localhost:3000/api/documents
{"success":true,"total":1,"page":1,"size":20,"documents":[{"id":"Z3Vl0psB_zRNsPIuWJbp","filename":"LOB.pdf","author":"Marek Wojciechowski","created_at":"2018-10-20T20:23:20Z","file_size":2081128,"upload_date":"2026-01-18T18:36:56.257Z"}]}
```

2. Usunięcie dokumentu:

```bash
$ curl -X DELETE http://localhost:3000/api/doc/Z3Vl0psB_zRNsPIuWJbp
{"success":true,"message":"Dokument usunięty"}
```

System usuwa zarówno wpis z Elasticsearch jak i plik z dysku (`./storage`).


### 4.6 Wnioski z testów
- Polski analyzer skutecznie redukuje słowa do form podstawowych
- Stopwords są całkowicie usuwane (co może być problematyczne dla fraz typu "w tym")
- Standard analyzer zachowuje oryginalne formy - mniej elastyczne wyszukiwanie

---

## 5. Wnioski

### 5.1 Osiągnięte cele

Udało się stworzyć w pełni funkcjonalny system wyszukiwania dokumentów PDF z obsługą języka polskiego. Kluczowe elementy:

- **Polski stemmer działa poprawnie**

- **Stopwords są filtrowane** - system ostrzega gdy zapytanie składa się wyłącznie ze stopwords

- **Highlighting działa** - wyniki wyszukiwania pokazują fragmenty z podświetlonymi frazami

- **Architektura mikrousługowa** - oddzielenie frontendu, backendu, ES i Tiki w kontenerach Docker

### 5.2 Możliwe usprawnienia

- obsługa wielu języków (detekcja języka, różne analyzery)
- podgląd PDF bezpośrednio w przeglądarce
- filtry zaawansowane (data, autor, rozmiar)
- sugestie zapytań

### 5.3 Podsumowanie

Projekt pokazał praktyczne zastosowanie Elasticsearch do wyszukiwania pełnotekstowego w dokumentach niestrukturalnych. Największym wyzwaniem była poprawna konfiguracja polskiego analyzera. 

Projekt był dobrą okazją do poznania stosu technologicznego używanego w rzeczywistych aplikacjach enterprise do wyszukiwania treści.

---

## 6. Instrukcja uruchomienia

Plik [README.md](README.md) dla szczegółowej instrukcji instalacji i uruchomienia.

---

## 7. Źródła

- Elasticsearch Documentation: https://www.elastic.co/guide/
- Apache Tika Documentation: https://tika.apache.org/
- Stempel Analyzer: https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-stempel.html
