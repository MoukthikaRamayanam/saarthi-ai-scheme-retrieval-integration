import json
import os
from pathlib import Path
from typing import Dict, List, Any, Optional
import numpy as np
from sentence_transformers import SentenceTransformer

from app.models import UserProfile

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
SCHEMES_FILE = DATA_DIR / "schemes.json"

DEFAULT_MODEL_NAME = os.environ.get("BGE_M3_MODEL_NAME", "BAAI/bge-m3")


class EmbeddingService:
    def __init__(self, model_name: str = DEFAULT_MODEL_NAME):
        self.model_name = model_name
        self._model: Optional[SentenceTransformer] = None
        self.schemes: List[Dict[str, Any]] = []
        self.scheme_embeddings: Optional[np.ndarray] = None
        self.field_embeddings: Dict[str, Dict[str, np.ndarray]] = {}
        self.is_initialized = False

    def load_model(self) -> None:
        if self._model is None:
            print(f"Loading embedding model: {self.model_name}...")
            # SentenceTransformer handles BAAI/bge-m3 with dense vector extraction
            self._model = SentenceTransformer(self.model_name)
            print("Model loaded successfully.")

    def load_schemes_data(self) -> List[Dict[str, Any]]:
        if not SCHEMES_FILE.exists():
            raise FileNotFoundError(f"Schemes data file not found at {SCHEMES_FILE}")
        with open(SCHEMES_FILE, "r", encoding="utf-8") as f:
            self.schemes = json.load(f)
        return self.schemes

    def initialize(self) -> None:
        """Loads model and precomputes corpus embeddings for fast retrieval."""
        if self.is_initialized:
            return
        
        self.load_model()
        self.load_schemes_data()
        self._precompute_embeddings()
        self.is_initialized = True

    def _build_scheme_composite_text(self, scheme: Dict[str, Any]) -> str:
        name = scheme.get("scheme_name", "")
        obj = scheme.get("objective", "")
        benefits = scheme.get("benefits", "")
        target = scheme.get("target_beneficiary", "")
        btypes = ", ".join(scheme.get("business_types", []))
        bstage = ", ".join(scheme.get("business_stage", []))
        keywords = ", ".join(scheme.get("keywords", []))
        state = scheme.get("state", "All India")
        return (
            f"Scheme Name: {name}. "
            f"Objective: {obj}. "
            f"Benefits: {benefits}. "
            f"Target Beneficiary: {target}. "
            f"Applicable Business Types: {btypes}. "
            f"Applicable Business Stages: {bstage}. "
            f"Keywords: {keywords}. "
            f"State: {state}."
        )

    def _precompute_embeddings(self) -> None:
        if not self.schemes:
            return
        
        print(f"Precomputing embeddings for {len(self.schemes)} schemes...")
        composite_texts = [self._build_scheme_composite_text(s) for s in self.schemes]
        
        # Compute normalized scheme composite embeddings
        self.scheme_embeddings = self._model.encode(
            composite_texts,
            normalize_embeddings=True,
            show_progress_bar=False
        )

        # Precompute individual field embeddings for deterministic why_matched explanations
        self.field_embeddings = {}
        for s in self.schemes:
            s_id = s["scheme_id"]
            fields = {
                "objective": s.get("objective", ""),
                "benefits": s.get("benefits", ""),
                "target_beneficiary": s.get("target_beneficiary", ""),
                "business_types": ", ".join(s.get("business_types", [])),
                "keywords": ", ".join(s.get("keywords", [])),
            }
            # Encode each field text
            field_texts = list(fields.values())
            field_keys = list(fields.keys())
            encoded_fields = self._model.encode(
                field_texts,
                normalize_embeddings=True,
                show_progress_bar=False
            )
            self.field_embeddings[s_id] = {
                k: encoded_fields[i] for i, k in enumerate(field_keys)
            }
        print("Embedding precomputation completed.")

    def construct_query_text(self, query: str, profile: Optional[UserProfile] = None) -> str:
        """Combines raw search query with structured profile data for enriched retrieval."""
        parts = [query.strip()]
        if profile:
            profile_parts = []
            if profile.business_type:
                profile_parts.append(f"Business Type: {profile.business_type}")
            if profile.business_stage:
                profile_parts.append(f"Stage: {profile.business_stage}")
            if profile.goal:
                profile_parts.append(f"Goal: {profile.goal}")
            if profile.state and profile.state.lower() != "all india":
                profile_parts.append(f"State: {profile.state}")
            if profile_parts:
                parts.append(" | Profile: " + ", ".join(profile_parts))
        return " ".join(parts)

    def encode_query(self, query_text: str) -> np.ndarray:
        """Encodes user query (English, Tamil, Hindi) into a normalized vector."""
        if not self.is_initialized:
            self.initialize()
        return self._model.encode(
            [query_text],
            normalize_embeddings=True,
            show_progress_bar=False
        )[0]


# Singleton instance
embedding_service = EmbeddingService()
