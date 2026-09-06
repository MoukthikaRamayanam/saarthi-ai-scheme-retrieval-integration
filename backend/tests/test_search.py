import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.feedback_service import feedback_service
from app.models import SearchRequest, UserProfile
from app.ranking_service import ranking_service

client = TestClient(app)


def test_health():
    """Verify health check endpoint returns 200 and ok status."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_english_semantic_search():
    """Verify semantic search with English query and structured profile."""
    payload = {
        "query": "I need funding for my tailoring business",
        "profile": {
            "business_type": "Tailoring",
            "business_stage": "Startup",
            "goal": "Funding",
            "state": "Tamil Nadu"
        },
        "top_k": 3
    }
    response = client.post("/search", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "results" in data
    results = data["results"]
    assert len(results) <= 3
    assert len(results) > 0

    first_match = results[0]
    assert "scheme_id" in first_match
    assert "scheme_name" in first_match
    assert "relevance_score" in first_match
    assert 0.0 <= first_match["relevance_score"] <= 1.0

    # Ensure deterministic why_matched explanations exist
    assert "why_matched" in first_match
    assert isinstance(first_match["why_matched"], list)
    assert len(first_match["why_matched"]) >= 1

    # Verify terminology strictly forbids eligibility claiming
    assert "eligibility" not in first_match


def test_top_k_results_count():
    """Verify top_k parameter accurately controls number of retrieved schemes."""
    # Test top_k = 2
    res2 = client.post("/search", json={
        "query": "machinery grant for artisan cluster",
        "top_k": 2
    })
    assert res2.status_code == 200
    assert len(res2.json()["results"]) == 2

    # Test top_k = 5
    res5 = client.post("/search", json={
        "query": "machinery grant for artisan cluster",
        "top_k": 5
    })
    assert res5.status_code == 200
    assert len(res5.json()["results"]) == 5


def test_tamil_cross_language_search():
    """Verify cross-lingual retrieval with Tamil query without prior translation."""
    tamil_query = "எனது தையல் தொழிலுக்கு நிதி உதவி வேண்டும்"
    response = client.post("/search", json={
        "query": tamil_query,
        "profile": {
            "business_type": "Tailoring",
            "business_stage": "Startup",
            "goal": "Funding",
            "state": "Tamil Nadu"
        },
        "top_k": 3
    })
    assert response.status_code == 200
    results = response.json()["results"]
    assert len(results) > 0
    # Tailoring/artisan/MSME schemes (S003, S001, S002, S010) should be prioritized
    retrieved_ids = [r["scheme_id"] for r in results]
    assert any(tid in retrieved_ids for tid in ["S001", "S002", "S003", "S006", "S010"])


def test_hindi_cross_language_search():
    """Verify cross-lingual retrieval with Hindi query without prior translation."""
    hindi_query = "मुझे अपने सिलाई व्यवसाय के लिए वित्तीय सहायता चाहिए"
    response = client.post("/search", json={
        "query": hindi_query,
        "profile": {
            "business_type": "Tailoring",
            "business_stage": "Startup",
            "goal": "Funding",
            "state": "All India"
        },
        "top_k": 3
    })
    assert response.status_code == 200
    results = response.json()["results"]
    assert len(results) > 0
    retrieved_ids = [r["scheme_id"] for r in results]
    assert any(tid in retrieved_ids for tid in ["S001", "S002", "S003", "S006", "S010"])


def test_feedback_endpoint():
    """Verify submitting relevant and not_relevant feedback."""
    payload_rel = {
        "query": "I need funding for my tailoring business",
        "scheme_id": "S003",
        "feedback": "relevant"
    }
    res_rel = client.post("/feedback", json=payload_rel)
    assert res_rel.status_code == 200
    assert res_rel.json()["status"] == "success"

    payload_not_rel = {
        "query": "I need funding for my tailoring business",
        "scheme_id": "S009",
        "feedback": "not_relevant"
    }
    res_not_rel = client.post("/feedback", json=payload_not_rel)
    assert res_not_rel.status_code == 200
    assert res_not_rel.json()["status"] == "success"


def test_feedback_reranking_adjustment():
    """Verify feedback modifies score adjustments."""
    adjustments = feedback_service.get_feedback_adjustments()
    assert isinstance(adjustments, dict)
    # S003 received 'relevant' feedback so adjustment should be positive
    if "S003" in adjustments:
        assert adjustments["S003"] > 0
    # S009 received 'not_relevant' feedback so adjustment should be negative
    if "S009" in adjustments:
        assert adjustments["S009"] < 0
