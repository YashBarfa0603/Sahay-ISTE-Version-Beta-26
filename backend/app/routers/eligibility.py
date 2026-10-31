"""
Eligibility Assessment and Explanation Router for SAHAY FastAPI Backend.
Exposes deterministic rule evaluation, condition-by-condition comparisons,
provenance tracking, and conversational AI explanations (Qwen2.5 via Ollama).
"""

import logging
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException
from backend.app.database.db_interface import SchemeDatabaseInterface, get_scheme_db
from backend.app.models.scheme_schemas import SchemeModelSchema
from backend.app.schemas.eligibility_explanation_schema import (
    AIExplanationResponse,
    DeterministicEligibilityReport,
    EligibilityExplanationRequest,
    ClarifyRequest,
)
from backend.app.services.eligibility_explanation_service import (
    EligibilityExplanationService,
)
from backend.app.services.ollama_service import OllamaService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/eligibility", tags=["Eligibility"])

_explanation_service = EligibilityExplanationService()
_ollama_service = OllamaService()


@router.post("/assess", response_model=DeterministicEligibilityReport)
async def assess_eligibility(
    request: EligibilityExplanationRequest,
    db: SchemeDatabaseInterface = Depends(get_scheme_db),
):
    """
    Evaluates citizen profile against verified scheme rules deterministically.
    Returns condition-by-condition evidence, differences, required documents,
    and alternative scheme suggestions. Zero LLM involvement.
    """
    scheme = await db.get_scheme(request.schemeId)
    if not scheme:
        raise HTTPException(
            status_code=404,
            detail=f"Scheme with ID '{request.schemeId}' not found in catalogue",
        )

    all_schemes = await db.list_all_schemes(limit=100)
    report = _explanation_service.evaluate_scheme(
        scheme=scheme,
        user_answers=request.user_answers,
        catalog_schemes=all_schemes,
    )
    return report


@router.post("/explain", response_model=AIExplanationResponse)
async def explain_eligibility(
    request: EligibilityExplanationRequest,
    db: SchemeDatabaseInterface = Depends(get_scheme_db),
):
    """
    Evaluates eligibility deterministically, then enhances the explanation using Qwen2.5
    via Ollama. If Ollama is offline or unavailable, automatically falls back to the
    deterministic explanation with zero downtime.
    """
    scheme = await db.get_scheme(request.schemeId)
    if not scheme:
        raise HTTPException(
            status_code=404,
            detail=f"Scheme with ID '{request.schemeId}' not found in catalogue",
        )

    all_schemes = await db.list_all_schemes(limit=100)
    report = _explanation_service.evaluate_scheme(
        scheme=scheme,
        user_answers=request.user_answers,
        catalog_schemes=all_schemes,
    )

    lang = (request.language or "en").lower()

    # Try conversational enhancement with Qwen2.5
    conversational_text = None
    generated_by_ai = False
    model_used = "deterministic_template"

    if hasattr(_ollama_service, "explain_eligibility"):
        try:
            ai_text = await _ollama_service.explain_eligibility(report, language=lang)
            if ai_text and len(ai_text.strip()) > 10:
                conversational_text = ai_text.strip()
                generated_by_ai = True
                model_used = getattr(_ollama_service, "model", "qwen2.5")
        except Exception as e:
            logger.warning(f"Ollama conversational explanation unavailable: {e}. Using deterministic text.")

    # Fallback to deterministic summary if Ollama was offline or failed
    if not conversational_text:
        if lang == "hi" and report.summaryExplanationHindi:
            conversational_text = report.summaryExplanationHindi
        else:
            conversational_text = report.summaryExplanation

    return AIExplanationResponse(
        deterministicReport=report,
        conversationalExplanation=conversational_text,
        language=lang,
        generatedByAi=generated_by_ai,
        modelUsed=model_used,
    )


@router.post("/clarify", response_model=AIExplanationResponse)
async def clarify_eligibility(
    request: ClarifyRequest,
    db: SchemeDatabaseInterface = Depends(get_scheme_db),
):
    """
    Allows citizen to submit previously missing fields to update their assessment incrementally.
    """
    merged_answers = {**request.existing_answers, **request.additional_answers}
    req = EligibilityExplanationRequest(
        schemeId=request.schemeId,
        user_answers=merged_answers,
        language=request.language,
    )
    return await explain_eligibility(req, db)

