from typing import List, Dict, Any, Optional
import numpy as np

from app.models import SearchRequest, SchemeResult, UserProfile
from app.embedding_service import embedding_service
from app.feedback_service import feedback_service

# Deterministic mappings from scheme field names to concise reasons
FIELD_REASON_MAP = {
    "business_types": "Matches your business type",
    "objective": "Relevant to your stated business need",
    "benefits": "Provides support related to your goal",
    "target_beneficiary": "Suitable for your beneficiary profile",
    "keywords": "Aligns with selected sector focus",
}


class RankingService:
    def __init__(self):
        pass

    def compute_field_explanations(
        self,
        scheme_id: str,
        query_vec: np.ndarray,
        profile: Optional[UserProfile] = None
    ) -> List[str]:
        """
        Deterministic non-LLM field-level semantic comparison.
        Compares query vector against separate scheme field embeddings,
        picks top 2-3 scoring fields, and returns clear readable reasons.
        """
        field_vectors = embedding_service.field_embeddings.get(scheme_id, {})
        if not field_vectors:
            return ["Matches your business requirements"]

        field_scores = []
        for field_name, field_vec in field_vectors.items():
            # Dot product for normalized vectors = cosine similarity
            sim = float(np.dot(query_vec, field_vec))
            field_scores.append((field_name, sim))

        # Sort fields by similarity descending
        field_scores.sort(key=lambda x: x[1], reverse=True)

        # Select top 2 to 3 matching fields
        reasons = []
        for field_name, _ in field_scores[:3]:
            reason = FIELD_REASON_MAP.get(field_name)
            if reason and reason not in reasons:
                reasons.append(reason)

        # Ensure 2-3 concise reasons
        if len(reasons) < 2 and field_scores:
            first_field = field_scores[0][0]
            reasons.append(FIELD_REASON_MAP.get(first_field, "Relevant to your business profile"))

        return reasons[:3]

    def rank_schemes(self, request: SearchRequest) -> List[SchemeResult]:
        """
        Performs semantic vector search, incorporates lightweight feedback adjustment,
        and generates field-level deterministic match explanations.
        Never computes or returns eligibility scores.
        """
        # Ensure embedding service is ready
        if not embedding_service.is_initialized:
            embedding_service.initialize()

        schemes = embedding_service.schemes
        if not schemes:
            return []

        # Construct enriched query representation
        full_query_text = embedding_service.construct_query_text(request.query, request.profile)
        query_vec = embedding_service.encode_query(full_query_text)

        # Compute cosine similarity with all precomputed scheme embeddings
        # Since vectors are normalized, dot product equals cosine similarity
        raw_similarities = np.dot(embedding_service.scheme_embeddings, query_vec)

        # Get feedback adjustments
        feedback_adjustments = feedback_service.get_feedback_adjustments()

        scored_schemes = []
        for idx, scheme in enumerate(schemes):
            s_id = scheme["scheme_id"]
            sim = float(raw_similarities[idx])

            # Apply lightweight feedback adjustment
            fb_adj = feedback_adjustments.get(s_id, 0.0)
            adjusted_score = sim + fb_adj

            # Clamp between 0.0 and 1.0
            relevance_score = max(0.0, min(1.0, adjusted_score))

            scored_schemes.append({
                "scheme": scheme,
                "relevance_score": relevance_score,
                "raw_sim": sim,
            })

        # Rank strictly by relevance_score descending
        scored_schemes.sort(key=lambda x: x["relevance_score"], reverse=True)

        # Top-k selection
        top_k = min(max(1, request.top_k), len(scored_schemes))
        top_results = scored_schemes[:top_k]

        # Build SchemeResult objects with deterministic why_matched explanations
        results: List[SchemeResult] = []
        for item in top_results:
            scheme = item["scheme"]
            s_id = scheme["scheme_id"]
            why_matched = self.compute_field_explanations(s_id, query_vec, request.profile)

            results.append(
                SchemeResult(
                    scheme_id=s_id,
                    scheme_name=scheme["scheme_name"],
                    relevance_score=round(item["relevance_score"], 4),
                    why_matched=why_matched,
                    objective=scheme.get("objective"),
                    benefits=scheme.get("benefits"),
                    target_beneficiary=scheme.get("target_beneficiary"),
                    business_types=scheme.get("business_types"),
                    state=scheme.get("state"),
                )
            )

        return results


ranking_service = RankingService()
