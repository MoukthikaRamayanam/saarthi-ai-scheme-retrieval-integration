from typing import List, Optional

from pydantic import BaseModel, Field


class UserProfile(BaseModel):
    business_type: Optional[str] = Field(
        default="",
        description="Type of business (e.g. Tailoring, Handicrafts)"
    )

    business_stage: Optional[str] = Field(
        default="",
        description="Stage of business (e.g. Startup, Idea)"
    )

    goal: Optional[str] = Field(
        default="",
        description="Primary business goal (e.g. Funding, Loan)"
    )

    state: Optional[str] = Field(
        default="All India",
        description="State of operation"
    )


class SearchRequest(BaseModel):
    query: str = Field(
        ...,
        description="User search query or business need description"
    )

    profile: Optional[UserProfile] = Field(
        default=None,
        description="Structured business profile"
    )

    top_k: int = Field(
        default=3,
        ge=1,
        le=20,
        description="Number of top relevant schemes to retrieve"
    )


class SchemeResult(BaseModel):
    scheme_id: str
    scheme_name: str

    relevance_score: float = Field(
        ...,
        description=(
            "Semantic relevance score (0.0 to 1.0). "
            "Represents semantic similarity only, NOT eligibility."
        )
    )

    why_matched: List[str] = Field(
        default_factory=list,
        description=(
            "Concise reasons explaining semantic match "
            "based on field-level vector alignment"
        )
    )

    objective: Optional[str] = None
    benefits: Optional[str] = None
    target_beneficiary: Optional[str] = None
    business_types: Optional[List[str]] = None
    state: Optional[str] = None

    # New fields for extended scheme details flow
    eligibility_rules: Optional[List[str]] = None
    required_documents: Optional[List[str]] = None
    official_link: Optional[str] = None


class SearchResponse(BaseModel):
    results: List[SchemeResult]


class FeedbackRequest(BaseModel):
    query: str = Field(
        ...,
        description="Search query associated with the feedback"
    )

    scheme_id: str = Field(
        ...,
        description="Target scheme identifier"
    )

    feedback: str = Field(
        ...,
        description="'relevant' or 'not_relevant'"
    )


class FeedbackResponse(BaseModel):
    status: str
    message: str