# SAHAY (सहाय) — Backend Services

FastAPI-powered backend for Indian Government Scheme Discovery, AI information extraction, and verification.

---

## 🏛️ Architecture Overview

```
                      ┌──────────────────────┐
                      │    Flutter Client    │
                      └──────────┬───────────┘
                                 │ HTTP / JSON
                                 ▼
                      ┌──────────────────────┐
                      │   FastAPI Backend    │
                      └──────────┬───────────┘
                                 │
         ┌───────────────────────┼────────────────────────┐
         ▼                       ▼                        ▼
┌──────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│ Trusted Catalog  │  │  Tavily Search API  │  │   Qwen2.5 (Ollama)  │
│  (DB Interface)  │  │ (Gov Domain Filter) │  │(Structure/Translate)│
└──────────────────┘  └──────────┬──────────┘  └─────────────────────┘
                                 │
                                 ▼
                      ┌─────────────────────┐
                      │ BeautifulSoup (4)   │
                      │ Web Page Extractor  │
                      └──────────┬──────────┘
                                 │
                                 ▼
                      ┌─────────────────────┐
                      │Verification Service │
                      │ Credibility/Conflict│
                      └─────────────────────┘
```

---

## 🔒 Separation of Responsibility: Cloud Firestore Integration

As defined in the project architecture, **Firebase Authentication and Cloud Firestore are maintained by the database engineer**.

To connect Cloud Firestore to the SAHAY backend, implement the `SchemeDatabaseInterface` in `backend/app/database/db_interface.py`:

```python
from backend.app.database.db_interface import SchemeDatabaseInterface
from backend.app.models.scheme_schemas import SchemeModelSchema

class FirestoreSchemeDatabase(SchemeDatabaseInterface):
    def __init__(self, firestore_client):
        self.db = firestore_client

    async def get_scheme(self, scheme_id: str):
        # Fetch from Firestore 'schemes' collection
        ...

    async def search_schemes(self, query: str, ...):
        # Query Firestore with indexes
        ...

    async def list_all_schemes(self, limit: int = 100):
        # List active schemes
        ...

    async def save_discovered_scheme(self, scheme: SchemeModelSchema):
        # Store in 'discovered_schemes' collection with pending verification
        ...
```

Then assign `db_instance = FirestoreSchemeDatabase(...)` in `backend/app/database/db_interface.py`. Zero modifications to the discovery pipeline or routers are needed.

---

## 🚀 Running the Backend

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Configure Environment (`.env`)

```env
TAVILY_API_KEY=your_tavily_api_key_here
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=qwen2.5:latest
DEBUG=True
```

### 3. Start the Server

```bash
uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
```

Interactive API documentation available at: `http://localhost:8000/docs`.

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/health` | Health check & model status |
| `GET` | `/api/schemes` | List verified schemes with category/level/state filtering |
| `GET` | `/api/schemes/{id}` | Retrieve specific scheme metadata & eligibility rules |
| `GET` | `/api/schemes/categories/all` | List 8 standard welfare categories |
| `POST` | `/api/schemes/search` | Hybrid search (catalogue -> Tavily -> Qwen2.5 -> Verifier) |

