from typing import List, Dict, Any, Optional, Tuple
import re
import numpy as np

from app.models import SearchRequest, SchemeResult, UserProfile
from app.embedding_service import embedding_service
from app.feedback_service import feedback_service


FIELD_REASON_MAP = {
    "business_types": "Matches your business type",
    "objective": "Relevant to your stated business need",
    "benefits": "Provides support related to your goal",
    "target_beneficiary": "Suitable for your beneficiary profile",
    "keywords": "Aligns with selected sector focus",
}


# ---------------------------------------------------------
# Ranking configuration
# ---------------------------------------------------------

SEMANTIC_WEIGHT = 0.70
PROFILE_WEIGHT = 0.30

MIN_QUERY_CONFIDENCE = 0.32

# Business-intent validation
MIN_BUSINESS_INTENT = 0.40
INTENT_MARGIN = 0.02


GOAL_KEYWORDS = {
    "funding": [
        "fund",
        "funding",
        "loan",
        "credit",
        "finance",
        "financial",
        "subsidy",
        "capital",
        "working capital",
        "interest",
    ],
    "training": [
        "training",
        "skill",
        "development",
        "capacity building",
    ],
    "equipment": [
        "equipment",
        "machine",
        "machinery",
        "tool",
        "toolkit",
    ],
    "marketing": [
        "marketing",
        "market",
        "branding",
        "promotion",
    ],
}


# ---------------------------------------------------------
# Semantic intent examples
# ---------------------------------------------------------

BUSINESS_INTENT_EXAMPLES = [
    "I want to start a small business",
    "I need a loan for my business",
    "I need funding for my enterprise",
    "I want government financial support",
    "I need subsidy for my business",
    "I need machinery for my business",
    "I want equipment support for my enterprise",
    "I want to expand my existing business",
    "I need working capital",
    "I need business training",
    "I need support for food processing",
    "I want to start a tailoring business",
    "I want to start a manufacturing unit",
    "I need financial help for agriculture infrastructure",
    "I am an entrepreneur looking for a government scheme",
    "I want support to start a micro enterprise",
]


NON_BUSINESS_EXAMPLES = [
    "hello",
    "hi how are you",
    "good morning",
    "good evening",
    "thank you",
    "what is your name",
    "tell me a joke",
    "I like watching movies",
    "what movie should I watch",
    "what is the weather today",
    "I like cricket",
    "who won the match",
    "play a song",
    "tell me a story",
    "what should I eat today",
    "help me with my homework",
]


class RankingService:
    def __init__(self):
        self.last_validation_message: Optional[str] = None

        # Intent vectors will be created only once.
        self.business_intent_vectors = None
        self.non_business_vectors = None

    # ---------------------------------------------------------
    # Text helpers
    # ---------------------------------------------------------

    def normalize_text(self, value: Any) -> str:
        if value is None:
            return ""

        return " ".join(
            str(value).strip().lower().split()
        )

    def get_profile_value(
        self,
        profile: Optional[UserProfile],
        *names: str,
    ) -> str:

        if profile is None:
            return ""

        for name in names:
            value = getattr(profile, name, None)

            if value is not None:
                text = self.normalize_text(value)

                if text:
                    return text

        return ""

    # ---------------------------------------------------------
    # Intent embeddings
    # ---------------------------------------------------------

    def initialize_intent_vectors(self):

        if (
            self.business_intent_vectors is not None
            and self.non_business_vectors is not None
        ):
            return

        print("Preparing business-intent validation vectors...")

        self.business_intent_vectors = np.array(
            [
                embedding_service.encode_query(text)
                for text in BUSINESS_INTENT_EXAMPLES
            ]
        )

        self.non_business_vectors = np.array(
            [
                embedding_service.encode_query(text)
                for text in NON_BUSINESS_EXAMPLES
            ]
        )

        print("Business-intent validation ready.")

    # ---------------------------------------------------------
    # Basic invalid-input check
    # ---------------------------------------------------------

    def basic_query_check(
        self,
        query: str,
    ) -> Tuple[bool, str]:

        query = query.strip()

        if not query:
            return (
                False,
                "Please enter your business need."
            )

        letters = [
            char
            for char in query
            if char.isalpha()
        ]

        # Reject numbers / symbols only
        if len(letters) < 3:
            return (
                False,
                "Please enter a meaningful business need."
            )

        visible_chars = [
            char
            for char in query
            if not char.isspace()
        ]

        if visible_chars:
            letter_ratio = (
                len(letters)
                / len(visible_chars)
            )

            if letter_ratio < 0.45:
                return (
                    False,
                    "Please enter a meaningful business need."
                )

        compact = re.sub(
            r"\s+",
            "",
            query.lower(),
        )

        # Repeated-character garbage
        if (
            len(compact) >= 5
            and len(set(compact)) <= 2
        ):
            return (
                False,
                "Please enter a meaningful business need."
            )

        # -----------------------------------------------------
        # Latin-script gibberish protection
        # -----------------------------------------------------

        latin_letters = [
            char
            for char in query.lower()
            if "a" <= char <= "z"
        ]

        all_letters_are_latin = (
            len(letters) > 0
            and len(latin_letters) == len(letters)
        )

        if all_letters_are_latin:

            vowels = sum(
                1
                for char in latin_letters
                if char in "aeiou"
            )

            vowel_ratio = (
                vowels / len(latin_letters)
            )

            # Example:
            # nhdv nfj
            # sdfgh jkl
            if (
                len(latin_letters) >= 6
                and vowel_ratio < 0.15
            ):
                return (
                    False,
                    "Please enter a meaningful business need."
                )

        return True, ""

    # ---------------------------------------------------------
    # Business intent check
    # ---------------------------------------------------------

    def business_intent_check(
        self,
        query: str,
    ) -> Tuple[bool, float, float]:

        """
        Uses BGE-M3 to check whether the query is related
        to business/scheme needs.

        This helps reject:

        hello
        good morning
        I like movies

        while accepting:

        I need a business loan
        I want to start food processing
        Tamil/Hindi/Telugu business queries
        """

        self.initialize_intent_vectors()

        query_vec = embedding_service.encode_query(
            query.strip()
        )

        business_scores = np.dot(
            self.business_intent_vectors,
            query_vec,
        )

        non_business_scores = np.dot(
            self.non_business_vectors,
            query_vec,
        )

        business_score = float(
            np.max(business_scores)
        )

        non_business_score = float(
            np.max(non_business_scores)
        )

        # Query must look sufficiently business-related
        if business_score < MIN_BUSINESS_INTENT:
            return (
                False,
                business_score,
                non_business_score,
            )

        # If query is more similar to casual/non-business
        # examples, reject it.
        if (
            non_business_score
            > business_score - INTENT_MARGIN
        ):
            return (
                False,
                business_score,
                non_business_score,
            )

        return (
            True,
            business_score,
            non_business_score,
        )

    # ---------------------------------------------------------
    # Semantic scheme confidence
    # ---------------------------------------------------------

    def semantic_query_check(
        self,
        query: str,
    ) -> Tuple[bool, float]:

        query_vec = embedding_service.encode_query(
            query.strip()
        )

        similarities = np.dot(
            embedding_service.scheme_embeddings,
            query_vec,
        )

        if len(similarities) == 0:
            return False, 0.0

        max_similarity = float(
            np.max(similarities)
        )

        return (
            max_similarity >= MIN_QUERY_CONFIDENCE,
            max_similarity,
        )

    # ---------------------------------------------------------
    # Full validation
    # ---------------------------------------------------------

    def validate_query(
        self,
        query: str,
    ) -> bool:

        # STEP 1 — basic garbage check

        basic_valid, message = (
            self.basic_query_check(query)
        )

        if not basic_valid:

            self.last_validation_message = message

            print("\n--- QUERY REJECTED ---")
            print(f"Query: {query!r}")
            print("Reason: Basic/gibberish validation")
            print("----------------------\n")

            return False

        # STEP 2 — business intent

        (
            intent_valid,
            business_score,
            non_business_score,
        ) = self.business_intent_check(query)

        print("\n--- INTENT DEBUG ---")
        print(f"Query: {query!r}")
        print(
            f"Business intent score: "
            f"{business_score:.4f}"
        )
        print(
            f"Non-business score: "
            f"{non_business_score:.4f}"
        )
        print("--------------------")

        if not intent_valid:

            self.last_validation_message = (
                "Please describe a business, funding, "
                "training, equipment or scheme-related need."
            )

            print("Result: REJECTED - unrelated input\n")

            return False

        # STEP 3 — query similarity with scheme corpus

        semantic_valid, confidence = (
            self.semantic_query_check(query)
        )

        print(
            f"Scheme semantic confidence: "
            f"{confidence:.4f}"
        )

        if not semantic_valid:

            self.last_validation_message = (
                "Your request could not be matched "
                "confidently with available schemes."
            )

            print(
                "Result: REJECTED - "
                "low scheme confidence\n"
            )

            return False

        self.last_validation_message = None

        print("Result: VALID BUSINESS QUERY\n")

        return True

    # ---------------------------------------------------------
    # Structured profile matching
    # ---------------------------------------------------------

    def list_contains_value(
        self,
        values: Any,
        target: str,
    ) -> bool:

        if not target:
            return False

        if not isinstance(values, list):
            values = [values]

        target = self.normalize_text(target)

        for value in values:

            candidate = self.normalize_text(value)

            if not candidate:
                continue

            if (
                target == candidate
                or target in candidate
                or candidate in target
            ):
                return True

        return False

    def compute_goal_match(
        self,
        scheme: Dict[str, Any],
        goal: str,
    ) -> float:

        if not goal:
            return 0.0

        goal = self.normalize_text(goal)

        searchable_text = " ".join(
            [
                self.normalize_text(
                    scheme.get("objective")
                ),
                self.normalize_text(
                    scheme.get("benefits")
                ),
                " ".join(
                    self.normalize_text(x)
                    for x in scheme.get(
                        "keywords",
                        [],
                    )
                ),
            ]
        )

        if goal in searchable_text:
            return 1.0

        related_words = GOAL_KEYWORDS.get(
            goal,
            [goal],
        )

        matched = sum(
            1
            for word in related_words
            if word in searchable_text
        )

        if matched == 0:
            return 0.0

        return min(
            1.0,
            matched / 2.0,
        )

    def compute_profile_score(
        self,
        scheme: Dict[str, Any],
        profile: Optional[UserProfile],
    ) -> float:

        """
        Structured relevance only.

        IMPORTANT:
        This is NOT eligibility.
        """

        if profile is None:
            return 0.0

        business_type = self.get_profile_value(
            profile,
            "business_type",
            "businessType",
        )

        business_stage = self.get_profile_value(
            profile,
            "business_stage",
            "stage",
            "businessStage",
        )

        goal = self.get_profile_value(
            profile,
            "goal",
            "primary_goal",
            "primaryGoal",
        )

        user_state = self.get_profile_value(
            profile,
            "state",
        )

        total_weight = 0.0
        weighted_score = 0.0

        # Business type
        if business_type:

            weight = 0.45
            total_weight += weight

            if self.list_contains_value(
                scheme.get(
                    "business_types",
                    [],
                ),
                business_type,
            ):
                weighted_score += weight

        # Business stage
        if business_stage:

            weight = 0.20
            total_weight += weight

            if self.list_contains_value(
                scheme.get(
                    "business_stage",
                    [],
                ),
                business_stage,
            ):
                weighted_score += weight

        # State
        if user_state:

            weight = 0.20
            total_weight += weight

            scheme_state = self.normalize_text(
                scheme.get("state")
            )

            if scheme_state == user_state:

                weighted_score += weight

            elif scheme_state in {
                "all india",
                "india",
                "national",
            }:

                weighted_score += (
                    weight * 0.85
                )

        # Goal
        if goal:

            weight = 0.15
            total_weight += weight

            goal_match = self.compute_goal_match(
                scheme,
                goal,
            )

            weighted_score += (
                weight * goal_match
            )

        if total_weight == 0:
            return 0.0

        return (
            weighted_score
            / total_weight
        )

    # ---------------------------------------------------------
    # Match explanations
    # ---------------------------------------------------------

    def compute_field_explanations(
        self,
        scheme_id: str,
        query_vec: np.ndarray,
        profile: Optional[UserProfile] = None,
    ) -> List[str]:

        field_vectors = (
            embedding_service
            .field_embeddings
            .get(
                scheme_id,
                {},
            )
        )

        if not field_vectors:
            return [
                "Matches your business requirements"
            ]

        field_scores = []

        for field_name, field_vec in field_vectors.items():

            similarity = float(
                np.dot(
                    query_vec,
                    field_vec,
                )
            )

            field_scores.append(
                (
                    field_name,
                    similarity,
                )
            )

        field_scores.sort(
            key=lambda item: item[1],
            reverse=True,
        )

        reasons = []

        for field_name, _ in field_scores[:3]:

            reason = FIELD_REASON_MAP.get(
                field_name
            )

            if (
                reason
                and reason not in reasons
            ):
                reasons.append(reason)

        if (
            len(reasons) < 2
            and field_scores
        ):

            first_field = field_scores[0][0]

            fallback_reason = FIELD_REASON_MAP.get(
                first_field,
                "Relevant to your business profile",
            )

            if fallback_reason not in reasons:
                reasons.append(
                    fallback_reason
                )

        return reasons[:3]

    # ---------------------------------------------------------
    # Main ranking
    # ---------------------------------------------------------

    def rank_schemes(
        self,
        request: SearchRequest,
    ) -> List[SchemeResult]:

        """
        Hybrid retrieval:

        70% BGE-M3 semantic relevance
        30% structured profile relevance

        + feedback re-ranking

        The resulting score is a RELEVANCE score,
        NOT an eligibility percentage.
        """

        if not embedding_service.is_initialized:
            embedding_service.initialize()

        schemes = embedding_service.schemes

        if not schemes:
            return []

        # ---------------------------------------------
        # STEP 1 — validate typed query
        # ---------------------------------------------

        if not self.validate_query(
            request.query
        ):
            return []

        # ---------------------------------------------
        # STEP 2 — full query + profile
        # ---------------------------------------------

        full_query_text = (
            embedding_service.construct_query_text(
                request.query,
                request.profile,
            )
        )

        query_vec = embedding_service.encode_query(
            full_query_text
        )

        # ---------------------------------------------
        # STEP 3 — semantic similarity
        # ---------------------------------------------

        raw_similarities = np.dot(
            embedding_service.scheme_embeddings,
            query_vec,
        )

        feedback_adjustments = (
            feedback_service
            .get_feedback_adjustments()
        )

        scored_schemes = []

        # ---------------------------------------------
        # STEP 4 — hybrid score
        # ---------------------------------------------

        for idx, scheme in enumerate(schemes):

            scheme_id = scheme["scheme_id"]

            semantic_score = float(
                raw_similarities[idx]
            )

            semantic_score = max(
                0.0,
                min(
                    1.0,
                    semantic_score,
                ),
            )

            profile_score = (
                self.compute_profile_score(
                    scheme,
                    request.profile,
                )
            )

            hybrid_score = (
                SEMANTIC_WEIGHT
                * semantic_score
                +
                PROFILE_WEIGHT
                * profile_score
            )

            feedback_adjustment = (
                feedback_adjustments.get(
                    scheme_id,
                    0.0,
                )
            )

            adjusted_score = (
                hybrid_score
                + feedback_adjustment
            )

            relevance_score = max(
                0.0,
                min(
                    1.0,
                    adjusted_score,
                ),
            )

            scored_schemes.append(
                {
                    "scheme": scheme,
                    "semantic_score": semantic_score,
                    "profile_score": profile_score,
                    "relevance_score": relevance_score,
                }
            )

        # ---------------------------------------------
        # STEP 5 — sort
        # ---------------------------------------------

        scored_schemes.sort(
            key=lambda item: item[
                "relevance_score"
            ],
            reverse=True,
        )

        top_k = min(
            max(
                1,
                request.top_k,
            ),
            len(scored_schemes),
        )

        top_results = scored_schemes[:top_k]

        # ---------------------------------------------
        # Debug
        # ---------------------------------------------

        print(
            "\n--- SAARTHI RANKING DEBUG ---"
        )

        print(
            f"Query: {request.query}"
        )

        for index, item in enumerate(
            top_results,
            start=1,
        ):

            print(
                f"{index}. "
                f"{item['scheme']['scheme_id']} "
                f"{item['scheme']['scheme_name']} | "
                f"semantic="
                f"{item['semantic_score']:.4f} | "
                f"profile="
                f"{item['profile_score']:.4f} | "
                f"final="
                f"{item['relevance_score']:.4f}"
            )

        print(
            "-----------------------------\n"
        )

        # ---------------------------------------------
        # STEP 6 — API response
        # ---------------------------------------------

        results: List[SchemeResult] = []

        for item in top_results:

            scheme = item["scheme"]

            scheme_id = scheme["scheme_id"]

            why_matched = (
                self.compute_field_explanations(
                    scheme_id,
                    query_vec,
                    request.profile,
                )
            )

            results.append(
                SchemeResult(
                    scheme_id=scheme_id,

                    scheme_name=(
                        scheme["scheme_name"]
                    ),

                    relevance_score=round(
                        item["relevance_score"],
                        4,
                    ),

                    why_matched=why_matched,

                    objective=scheme.get(
                        "objective"
                    ),

                    benefits=scheme.get(
                        "benefits"
                    ),

                    target_beneficiary=(
                        scheme.get(
                            "target_beneficiary"
                        )
                    ),

                    business_types=(
                        scheme.get(
                            "business_types"
                        )
                    ),

                    state=scheme.get(
                        "state"
                    ),

                    eligibility_rules=(
                        scheme.get(
                            "eligibility_rules"
                        )
                    ),

                    required_documents=(
                        scheme.get(
                            "required_documents"
                        )
                    ),

                    official_link=(
                        scheme.get(
                            "official_link"
                        )
                    ),
                )
            )

        return results


ranking_service = RankingService()