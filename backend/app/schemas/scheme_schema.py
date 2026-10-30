"""
Pydantic Schema definitions for SAHAY Scheme Catalogue (Schema v2).
Enforces strict typing, official source validation, and deterministic rule consistency.
"""

from datetime import datetime
from typing import Any, Dict, List, Literal, Optional, Union
from pydantic import BaseModel, Field, field_validator, model_validator


# ---------------------------------------------------------------------------
# Controlled Vocabularies
# ---------------------------------------------------------------------------

ALLOWED_CATEGORIES = {
    "agriculture",
    "health",
    "social-security",
    "housing",
    "finance",
    "education",
    "women-child",
    "employment-skills",
    "business",
    "rural-development",
    "utilities",
    "food-security",
    "tribal-welfare",
}

ALLOWED_TAGS = {
    "farmers",
    "women",
    "girl-child",
    "students",
    "senior-citizens",
    "youth",
    "workers",
    "street-vendors",
    "entrepreneurs",
    "artisans",
    "bpl",
    "sc",
    "st",
    "minorities",
    "disabled",
    "pregnant-women",
    "rural",
    "urban",
    "health",
    "pension",
    "insurance",
    "loan",
    "scholarship",
    "housing",
    "skill-training",
    "employment",
}

ALLOWED_GOVERNMENT_LEVELS = {"central", "state"}
ALLOWED_SCHEME_STATUS = {"active", "inactive", "underVerification"}
ALLOWED_VERIFICATION_STATUS = {"verified", "pending"}
ALLOWED_VERIFIED_BY = {"agent", "human", None}
ALLOWED_SOURCE_TYPE = {"curated", "discovered"}

ALLOWED_OPERATORS = {
    "equals",
    "notEquals",
    "greaterThan",
    "greaterThanOrEqual",
    "lessThan",
    "lessThanOrEqual",
    "inList",
    "notInList",
    "isTrue",
    "isFalse",
}

ALLOWED_STAGE_OUTCOMES = {"eligible", "mayBeEligible", "notEligible"}

ALLOWED_STATE_CODES = {
    "ALL_INDIA",
    "AN", "AP", "AR", "AS", "BR", "CH", "CG", "DN", "DD", "DL", "GA", "GJ",
    "HR", "HP", "JK", "JH", "KA", "KL", "LA", "LD", "MP", "MH", "MN", "ML",
    "MZ", "NL", "OD", "PY", "PB", "RJ", "SK", "TN", "TS", "TR", "UP", "UK", "WB"
}


# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------

class DataQuality(BaseModel):
    """Tracks completeness, translation review, and investigation flags."""
    hasBenefits: bool = False
    hasDocuments: bool = False
    hasRules: bool = False
    hasHindi: bool = False
    hindiReviewed: bool = False
    flags: List[str] = Field(default_factory=list)


class EligibilityRule(BaseModel):
    """
    Deterministic rule condition evaluated by client or backend.
    Must map directly to a known profile field and contain exact official provenance.
    """
    field: str
    operator: Literal[
        "equals",
        "notEquals",
        "greaterThan",
        "greaterThanOrEqual",
        "lessThan",
        "lessThanOrEqual",
        "inList",
        "notInList",
        "isTrue",
        "isFalse",
    ]
    value: Any = None
    isMandatory: bool = True
    description: str
    descriptionHindi: Optional[str] = None
    sourceUrl: str
    sourceQuote: str

    @field_validator("sourceQuote")
    @classmethod
    def validate_source_quote_length(cls, v: str) -> str:
        word_count = len(v.strip().split())
        if word_count > 25:
            raise ValueError(f"sourceQuote must be max 25 words (got {word_count} words): '{v}'")
        return v


class StageCondition(BaseModel):
    field: str
    operator: str
    value: Any = None
    reason: str
    reasonHindi: Optional[str] = None


class RuleStage(BaseModel):
    """Staged rule evaluation block for multi-tiered schemes (e.g. Ayushman Bharat)."""
    id: str
    appliesIf: Dict[str, Any] = Field(default_factory=dict)
    outcomeIfAnyTrue: Literal["eligible", "mayBeEligible", "notEligible"]
    listAllTriggered: bool = False
    conditions: List[StageCondition] = Field(default_factory=list)


class SchemeDocument(BaseModel):
    """
    Schema v2 for Cloud Firestore `schemes/{schemeId}`.
    Designed for deterministic filtering, cursor pagination, and multilingual UI.
    """
    schemeId: str
    name: str
    nameHindi: Optional[str] = None
    description: str = ""
    descriptionHindi: Optional[str] = None
    category: str
    tags: List[str] = Field(default_factory=list)
    ministry: Optional[str] = None
    governmentLevel: Literal["central", "state"]
    applicableStates: List[str]
    benefits: str = ""
    benefitsHindi: Optional[str] = None
    eligibilityText: Optional[str] = None
    eligibilityTextHindi: Optional[str] = None
    eligibilityRules: List[EligibilityRule] = Field(default_factory=list)
    ruleStages: Optional[List[RuleStage]] = None
    rulesComplete: bool = False
    rulesVerificationStatus: Literal["unverified", "verified"] = "unverified"
    eligibilityEnabled: bool = False
    requiredDocuments: List[str] = Field(default_factory=list)
    requiredDocumentsHindi: List[str] = Field(default_factory=list)
    applicationProcess: str = ""
    applicationProcessHindi: Optional[str] = None
    applicationUrl: Optional[str] = None
    officialSourceUrl: Optional[str] = None
    sourceName: Optional[str] = None
    sourceUrls: List[str] = Field(default_factory=list)
    sourceType: Literal["curated", "discovered"] = "curated"
    discoveredAt: Optional[Union[datetime, str]] = None
    verificationStatus: Literal["verified", "pending"] = "pending"
    verifiedBy: Optional[Literal["agent", "human"]] = None
    status: Literal["active", "inactive", "underVerification"] = "active"
    lastVerified: Optional[Union[datetime, str]] = None
    isPopular: bool = False
    popularityRank: int = 0
    searchKeywords: List[str] = Field(default_factory=list)
    nameLower: str = ""
    dataQuality: DataQuality = Field(default_factory=DataQuality)
    schemaVersion: int = 2
    createdAt: Optional[Union[datetime, str]] = None
    updatedAt: Optional[Union[datetime, str]] = None

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: str) -> str:
        if v not in ALLOWED_CATEGORIES:
            raise ValueError(f"Category '{v}' is not in controlled categories: {ALLOWED_CATEGORIES}")
        return v

    @field_validator("tags")
    @classmethod
    def validate_tags(cls, v: List[str]) -> List[str]:
        for tag in v:
            if tag not in ALLOWED_TAGS:
                raise ValueError(f"Tag '{tag}' is not in controlled tags: {ALLOWED_TAGS}")
        return v

    @field_validator("applicableStates")
    @classmethod
    def validate_applicable_states(cls, v: List[str], info) -> List[str]:
        if not v:
            raise ValueError("applicableStates cannot be empty. Central schemes must use ['ALL_INDIA'].")
        for state in v:
            if state not in ALLOWED_STATE_CODES:
                raise ValueError(f"Invalid state code '{state}'.")
        return v

    @field_validator("requiredDocumentsHindi")
    @classmethod
    def validate_docs_hindi_length(cls, v: List[str], info) -> List[str]:
        # Handled in model_validator for cross-field access
        return v

    @field_validator("searchKeywords")
    @classmethod
    def validate_search_keywords(cls, v: List[str]) -> List[str]:
        if len(v) > 25:
            raise ValueError(f"searchKeywords max allowed is 25, got {len(v)}")
        seen = set()
        for kw in v:
            if kw != kw.lower():
                raise ValueError(f"searchKeywords must be lowercase, got '{kw}'")
            if kw in seen:
                raise ValueError(f"searchKeywords contains duplicate: '{kw}'")
            seen.add(kw)
        return v

    @model_validator(mode="after")
    def validate_consistency(self) -> "SchemeDocument":
        # 1. nameLower must equal lowercase name
        expected_lower = self.name.lower().strip()
        if self.nameLower != expected_lower:
            self.nameLower = expected_lower

        # 2. Central vs State rules
        if self.governmentLevel == "central":
            if self.applicableStates != ["ALL_INDIA"]:
                raise ValueError(f"Central scheme must have applicableStates=['ALL_INDIA'], got {self.applicableStates}")
        elif self.governmentLevel == "state":
            if "ALL_INDIA" in self.applicableStates or not self.applicableStates:
                raise ValueError(f"State scheme must have specific state codes, got {self.applicableStates}")

        # 3. Documents Hindi parity: must be empty list OR same length as requiredDocuments
        if self.requiredDocumentsHindi and len(self.requiredDocumentsHindi) != len(self.requiredDocuments):
            raise ValueError(
                f"requiredDocumentsHindi must be empty list or match length of requiredDocuments "
                f"({len(self.requiredDocumentsHindi)} != {len(self.requiredDocuments)})"
            )

        # 4. Agent seeding safety: rulesVerificationStatus must be 'unverified' and eligibilityEnabled must be False
        if self.verifiedBy == "agent":
            if self.rulesVerificationStatus == "verified":
                raise ValueError("Agent must never set rulesVerificationStatus to 'verified'. Human only.")
            if self.eligibilityEnabled:
                raise ValueError("Agent must never set eligibilityEnabled to True. Human only.")

        # 5. eligibilityEnabled invariant
        expected_enabled = (
            self.rulesVerificationStatus == "verified"
            and self.rulesComplete is True
            and bool(self.eligibilityRules or self.ruleStages)
        )
        if self.eligibilityEnabled != expected_enabled:
            raise ValueError(
                f"eligibilityEnabled ({self.eligibilityEnabled}) does not match required condition "
                f"rulesVerificationStatus == 'verified' AND rulesComplete == True AND rules exist ({expected_enabled})"
            )

        # 6. Verification Status consistency
        if self.verificationStatus == "verified":
            if not self.officialSourceUrl:
                raise ValueError("verificationStatus 'verified' requires a non-null officialSourceUrl")
            if not self.lastVerified:
                raise ValueError("verificationStatus 'verified' requires lastVerified timestamp")
            if not self.verifiedBy:
                raise ValueError("verificationStatus 'verified' requires verifiedBy ('agent' or 'human')")

        # 7. Popularity ranking consistency
        if self.isPopular:
            if not (1 <= self.popularityRank <= 10):
                raise ValueError(f"isPopular=True requires popularityRank between 1 and 10 (got {self.popularityRank})")
        else:
            if self.popularityRank != 0:
                raise ValueError(f"isPopular=False requires popularityRank=0 (got {self.popularityRank})")

        return self


# ---------------------------------------------------------------------------
# Categories and Profile Fields Models
# ---------------------------------------------------------------------------

class CategoryItem(BaseModel):
    categoryId: str
    name: str
    nameHindi: str
    description: str
    descriptionHindi: str
    iconName: str
    isActive: bool = True
    displayOrder: int
    schemeCount: int = 0
    createdAt: Optional[Union[datetime, str]] = None
    updatedAt: Optional[Union[datetime, str]] = None


class ProfileFieldItem(BaseModel):
    key: str
    type: Literal["number", "bool", "choice"]
    allowedValues: Optional[List[str]] = None
    question: str
    questionHindi: str
    alwaysKnown: bool = False


class ProfileFieldsConfig(BaseModel):
    fields: List[ProfileFieldItem]

