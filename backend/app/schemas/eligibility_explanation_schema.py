"""
Pydantic Schemas for SAHAY Evidence-Based Eligibility Reasoning System.
Standardizes condition-by-condition comparison results, difference computations,
provenance tracing, and conversational AI explanation envelopes.
"""

from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, ConfigDict


class ConditionEvaluationStatus(str, Enum):
    satisfied = "satisfied"
    not_satisfied = "not_satisfied"
    missing = "missing"
    unverified = "unverified"


class OverallAssessmentVerdict(str, Enum):
    may_qualify = "may_qualify"
    does_not_appear_to_qualify = "does_not_appear_to_qualify"
    needs_more_information = "needs_more_information"


class DifferenceDetail(BaseModel):
    amount: Optional[float] = None
    description: str


class ConditionComparisonDetail(BaseModel):
    field: str
    label: str
    labelHindi: Optional[str] = None
    required: str
    requiredHindi: Optional[str] = None
    userValue: Optional[Any] = None
    formattedUserValue: str
    status: ConditionEvaluationStatus
    isMandatory: bool = True
    isBorderline: bool = False
    reason: str
    reasonHindi: Optional[str] = None
    difference: Optional[DifferenceDetail] = None
    sourceUrl: Optional[str] = None
    sourceQuote: Optional[str] = None
    verifyingDocument: Optional[str] = None
    verifyingDocumentHindi: Optional[str] = None
    verificationStatus: str = "self_reported"  # self_reported | document_uploaded | document_verified


class AlternativeSchemeSuggestion(BaseModel):
    schemeId: str
    schemeName: str
    schemeNameHindi: Optional[str] = None
    category: str
    reasonWhyRelevant: str
    reasonWhyRelevantHindi: Optional[str] = None


class MissingFieldPrompt(BaseModel):
    field: str
    label: str
    labelHindi: Optional[str] = None
    questionText: str
    questionTextHindi: Optional[str] = None
    inputType: str  # number, single_choice, boolean
    options: Optional[List[str]] = None
    reasonNeeded: str


class DeterministicEligibilityReport(BaseModel):
    schemeId: str
    schemeName: str
    schemeNameHindi: Optional[str] = None
    verdict: OverallAssessmentVerdict
    summaryExplanation: str
    summaryExplanationHindi: Optional[str] = None
    mandatorySatisfiedCount: int = 0
    mandatoryTotalCount: int = 0
    optionalSatisfiedCount: int = 0
    optionalTotalCount: int = 0
    conditions: List[ConditionComparisonDetail] = Field(default_factory=list)
    satisfiedConditions: List[ConditionComparisonDetail] = Field(default_factory=list)
    unsatisfiedConditions: List[ConditionComparisonDetail] = Field(default_factory=list)
    missingConditions: List[ConditionComparisonDetail] = Field(default_factory=list)
    optionalConditions: List[ConditionComparisonDetail] = Field(default_factory=list)
    missingFieldPrompts: List[MissingFieldPrompt] = Field(default_factory=list)
    alternativeSchemes: List[AlternativeSchemeSuggestion] = Field(default_factory=list)
    requiredDocumentsToVerify: List[str] = Field(default_factory=list)
    requiredDocumentsToVerifyHindi: List[str] = Field(default_factory=list)
    nextSteps: List[str] = Field(default_factory=list)
    nextStepsHindi: List[str] = Field(default_factory=list)
    disclaimer: str
    disclaimerHindi: Optional[str] = None

    # Backward compatibility with existing SchemeEvaluationReport
    @property
    def legacy_verdict(self) -> str:
        if self.verdict == OverallAssessmentVerdict.may_qualify:
            return "mayQualify"
        if self.verdict == OverallAssessmentVerdict.needs_more_information:
            return "needsMoreInformation"
        return "doesNotQualify"


class EligibilityExplanationRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    schemeId: str
    user_answers: Dict[str, Any] = Field(default_factory=dict, alias="answers")
    language: str = "en"
    force_ai: bool = False


class AIExplanationResponse(BaseModel):
    deterministicReport: DeterministicEligibilityReport
    conversationalExplanation: str
    language: str
    generatedByAi: bool = False
    modelUsed: str = "deterministic_template"



class ClarifyRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    schemeId: str
    existing_answers: Dict[str, Any] = Field(default_factory=dict, alias="answers")
    additional_answers: Dict[str, Any] = Field(default_factory=dict)
    language: str = "en"
