import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.models import (
    SearchRequest,
    SearchResponse,
    FeedbackRequest,
    FeedbackResponse,
)
from app.ranking_service import ranking_service
from app.feedback_service import feedback_service
from app.embedding_service import embedding_service


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize embedding model and precompute scheme vectors on startup
    print("Starting SAARTHI AI Semantic Retrieval Service...")
    try:
        embedding_service.initialize()
    except Exception as e:
        print(f"Warning during startup initialization: {e}")
    yield
    print("Shutting down SAARTHI AI Semantic Retrieval Service...")


app = FastAPI(
    title="SAARTHI AI - Semantic Scheme Retrieval API",
    description=(
        "BAAI BGE-M3 Embedding & Semantic Retrieval module for marginalized entrepreneurs. "
        "IMPORTANT: This module handles semantic matching and ranking only; it does NOT decide eligibility."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# Allow Flutter Web during local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_check():
    """Health check endpoint."""
    return {"status": "ok"}


@app.post("/search", response_model=SearchResponse)
def search_schemes(request: SearchRequest):
    """
    Multilingual semantic search and ranking for government schemes.
    Uses BAAI BGE-M3 dense embeddings and field-level semantic comparison.
    Returns relevance score (semantic similarity only, NOT eligibility).
    """
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="Search query cannot be empty")
    
    try:
        results = ranking_service.rank_schemes(request)
        return SearchResponse(results=results)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing semantic search: {str(e)}")


@app.post("/feedback", response_model=FeedbackResponse)
def submit_feedback(request: FeedbackRequest):
    """
    Submits user feedback ('relevant' or 'not_relevant') for a retrieved scheme.
    Stored in data/feedback.json and used for lightweight re-ranking.
    """
    try:
        feedback_service.record_feedback(
            query=request.query,
            scheme_id=request.scheme_id,
            feedback=request.feedback
        )
        return FeedbackResponse(
            status="success",
            message=f"Feedback '{request.feedback}' recorded for scheme '{request.scheme_id}'."
        )
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error saving feedback: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
