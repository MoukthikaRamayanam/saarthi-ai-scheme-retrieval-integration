# SAARTHI AI – BAAI BGE-M3 Embedding & Semantic Retrieval Backend

Backend service for **SAARTHI AI**: an AI-driven opportunity navigation and scheme discovery platform designed for marginalized entrepreneurs.

> [!IMPORTANT]
> **CRITICAL ARCHITECTURAL RULE – ELIGIBILITY SEPARATION:**
> The embedding model (`BAAI/bge-m3`) does **NOT** determine or verify applicant eligibility. It strictly performs **semantic retrieval and relevance ranking** based on cosine similarity in dense vector space. 
> Official eligibility verification must be conducted by an independent deterministic rule engine or official departmental portal validation.
>
> **DISCLAIMER:** The schemes contained in `data/schemes.json` are simplified sample representations for demonstration and testing purposes. They do not constitute official legal guidelines.

---

## Demonstrated Features

This module implements the 9 core requirements:

1. **Semantic Scheme Retrieval:** Retrieves relevant government schemes using dense vector representations instead of fragile keyword matching.
2. **Relevant Scheme Ranking:** Calculates cosine similarity between user queries and scheme representations to rank results.
3. **Profile/Requirement-Based Search:** Combines free-text queries with structured business profiles (Business Type, Stage, Goal, State) into an enriched contextual prompt.
4. **Vector Embedding Generation:** Uses `BAAI/bge-m3` via `sentence-transformers` to generate 1024-dimensional normalized embeddings.
5. **Vector Search / RAG Support:** Pre-computes normalized corpus vectors and retrieves matching contexts with fast dot-product matrix multiplication.
6. **Top Relevant Scheme Retrieval:** Returns configurable `top_k` highest-ranked schemes (e.g. Top 3 or Top 5).
7. **Why This Scheme Matched:** Deterministic non-LLM explanation mechanism that compares user query vectors against individual scheme field vectors (`business_types`, `objective`, `benefits`, `target_beneficiary`, `keywords`) and highlights the top matching factors.
8. **Cross-Language Semantic Search:** Direct native multilingual embedding support for English, Tamil ("எனது தையல் தொழிலுக்கு நிதி உதவி வேண்டும்"), and Hindi ("मुझे अपने सिलाई व्यवसाय के लिए वित्तीय सहायता चाहिए") without translation intermediaries.
9. **Feedback-Based Re-ranking:** Lightweight online adjustment mechanism that records user feedback (👍 Relevant / 👎 Not Relevant) in `data/feedback.json` and adjusts relevance scores within a bounded range while keeping semantic similarity as the primary signal.

---

## API Endpoints

### 1. Health Check
- **Endpoint:** `GET /health`
- **Response:**
  ```json
  {
    "status": "ok"
  }
  ```

### 2. Semantic Search
- **Endpoint:** `POST /search`
- **Request:**
  ```json
  {
    "query": "I need funding for my tailoring business",
    "profile": {
      "business_type": "Tailoring",
      "business_stage": "Startup",
      "goal": "Funding",
      "state": "Tamil Nadu"
    },
    "top_k": 3
  }
  ```
- **Response:**
  ```json
  {
    "results": [
      {
        "scheme_id": "S003",
        "scheme_name": "PM Vishwakarma Scheme",
        "relevance_score": 0.8842,
        "why_matched": [
          "Matches your business type",
          "Provides support related to your goal",
          "Relevant to your stated business need"
        ],
        "objective": "...",
        "benefits": "...",
        "state": "All India"
      }
    ]
  }
  ```

### 3. Feedback Submission
- **Endpoint:** `POST /feedback`
- **Request:**
  ```json
  {
    "query": "I need funding for my tailoring business",
    "scheme_id": "S003",
    "feedback": "relevant"
  }
  ```
- **Response:**
  ```json
  {
    "status": "success",
    "message": "Feedback 'relevant' recorded for scheme 'S003'."
  }
  ```

---

## Quickstart

### Prerequisites
- Python 3.10+
- PyTorch & sentence-transformers

### Installation
```bash
# Navigate to backend directory
cd backend

# (Optional) Create and activate virtual environment
python -m venv .venv
# On Windows:
.venv\Scripts\activate
# On Linux/macOS:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Running the Server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
Interactive API docs will be available at `http://127.0.0.1:8000/docs`.

### Running Tests
```bash
pytest tests/test_search.py -v
```
