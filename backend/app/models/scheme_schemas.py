from datetime import datetime
from enum import Enum
from typing import Any, List, Optional
from pydantic import BaseModel, Field


class GovernmentLevel(str, Enum):
    central = "central"
    state = "state"


class SchemeStatus(str, Enum):
    active = "active"
    inactive = "inactive"
    underVerification = "underVerification"


class VerificationStatus(str, Enum):
    pending = "pending"
    verified = "verified"
    rejected = "rejected"


class SchemeSourceType(str, Enum):
    curated = "curated"
    discovered = "discovered"


class EligibilityOperator(str, Enum):
    equals = "equals"
    notEquals = "notEquals"
    greaterThan = "greaterThan"
    greaterThanOrEqual = "greaterThanOrEqual"
    lessThan = "lessThan"
    lessThanOrEqual = "lessThanOrEqual"
    inList = "inList"
    notInList = "notInList"
    isTrue = "isTrue"
    isFalse = "isFalse"


class EligibilityRuleSchema(BaseModel):
    field: str
    operator: EligibilityOperator
    value: Any
    isMandatory: bool = True
    description: Optional[str] = None


class SchemeModelSchema(BaseModel):
    schemeId: str
    name: str
    nameHindi: Optional[str] = None
    description: str
    descriptionHindi: Optional[str] = None
    category: str
    ministry: str
    governmentLevel: GovernmentLevel
    applicableStates: List[str] = Field(default_factory=list)
    benefits: str
    benefitsHindi: Optional[str] = None
    eligibilityRules: List[EligibilityRuleSchema] = Field(default_factory=list)
    requiredDocuments: List[str] = Field(default_factory=list)
    applicationProcess: str
    applicationUrl: Optional[str] = None
    officialSourceUrl: str
    sourceName: Optional[str] = None
    sourceType: SchemeSourceType = SchemeSourceType.curated
    discoveredAt: Optional[datetime] = None
    verificationStatus: VerificationStatus = VerificationStatus.pending
    status: SchemeStatus = SchemeStatus.underVerification
    lastVerified: Optional[datetime] = None
    isPopular: bool = False
    popularityRank: int = 0
    createdAt: datetime = Field(default_factory=datetime.utcnow)
    updatedAt: datetime = Field(default_factory=datetime.utcnow)


class SchemeSearchQuery(BaseModel):
    query: str
    category: Optional[str] = None
    governmentLevel: Optional[GovernmentLevel] = None
    state: Optional[str] = None
    forceDynamicDiscovery: bool = False
    language: str = "en"


class SchemeSearchResponse(BaseModel):
    total: int
    results: List[SchemeModelSchema]
    isDynamicDiscovery: bool = False
    sourcesChecked: List[str] = Field(default_factory=list)
    message: Optional[str] = None

