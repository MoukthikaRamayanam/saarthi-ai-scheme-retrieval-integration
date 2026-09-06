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
        "BAAI BGE-M3 Embedding & Semantic Retrieval module for marginalized "
        "entrepreneurs. IMPORTANT: This module handles semantic matching and "
        "ranking only; it does NOT decide eligibility."
    ),
    version="1.2.0",
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
    return {"status": "ok"}


@app.post("/search")
def search_schemes(request: SearchRequest):
    """
    Multilingual semantic search using BAAI BGE-M3.

    relevance_score means retrieval relevance only.
    It does NOT represent eligibility.
    """

    if not request.query.strip():
        raise HTTPException(
            status_code=400,
            detail="Please enter your business need."
        )

    try:
        results = ranking_service.rank_schemes(request)

        # Query was rejected by validation
        if (
            not results
            and ranking_service.last_validation_message
        ):
            return {
                "results": [],
                "message": ranking_service.last_validation_message,
                "valid_query": False,
            }

        return {
            "results": results,
            "message": None,
            "valid_query": True,
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error processing semantic search: {str(e)}"
        )


@app.get("/schemes/{scheme_id}")
def get_scheme_details(scheme_id: str):
    """
    Returns full stored details for one scheme.

    This endpoint displays scheme information only.
    It does NOT determine whether a user is eligible.
    """

    if not embedding_service.is_initialized:
        embedding_service.initialize()

    for scheme in embedding_service.schemes:
        if scheme.get("scheme_id") == scheme_id:

            return {
                "scheme_id": scheme.get("scheme_id"),
                "scheme_name": scheme.get("scheme_name"),
                "objective": scheme.get("objective"),
                "benefits": scheme.get("benefits"),
                "target_beneficiary": scheme.get(
                    "target_beneficiary"
                ),
                "business_types": scheme.get(
                    "business_types",
                    []
                ),
                "business_stage": scheme.get(
                    "business_stage",
                    []
                ),
                "state": scheme.get("state"),
                "eligibility_rules": scheme.get(
                    "eligibility_rules",
                    []
                ),
                "required_documents": scheme.get(
                    "required_documents",
                    []
                ),
                "official_link": scheme.get(
                    "official_link"
                ),
            }

    raise HTTPException(
        status_code=404,
        detail=f"Scheme '{scheme_id}' not found"
    )


@app.post("/feedback", response_model=FeedbackResponse)
def submit_feedback(request: FeedbackRequest):
    """
    Stores relevant / not relevant feedback for lightweight re-ranking.
    """

    try:
        feedback_service.record_feedback(
            query=request.query,
            scheme_id=request.scheme_id,
            feedback=request.feedback
        )

        return FeedbackResponse(
            status="success",
            message=(
                f"Feedback '{request.feedback}' recorded "
                f"for scheme '{request.scheme_id}'."
            )
        )

    except ValueError as ve:
        raise HTTPException(
            status_code=400,
            detail=str(ve)
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error saving feedback: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )