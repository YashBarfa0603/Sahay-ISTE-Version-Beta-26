"""
Assistance Router for SAHAY FastAPI Backend.
Provides income estimation, CSC location, conflict diagnostics, and human referral packages.
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from backend.app.database.db_interface import SchemeDatabaseInterface, get_scheme_db
from backend.app.services.assistance_service import (
    AssistanceService,
    ConflictReport,
    CscCentreRecord,
    HumanAssistanceReferral,
)
from backend.app.services.income_estimator_service import (
    IncomeEstimationInput,
    IncomeEstimationOutput,
    IncomeEstimatorService,
)

router = APIRouter(prefix="/api/assistance", tags=["Assistance"])

_income_service = IncomeEstimatorService()
_assistance_service = AssistanceService()


@router.post("/estimate-income", response_model=IncomeEstimationOutput)
async def estimate_income(
    input_data: IncomeEstimationInput,
    db: SchemeDatabaseInterface = Depends(get_scheme_db),
):
    """
    Estimates conservative annual household income range for citizens with informal/unknown income.
    Privacy guarantee: Data is evaluated in-memory and not stored.
    """
    # Fetch income thresholds from all active schemes
    all_schemes = await db.list_all_schemes()
    thresholds = {}
    for s in all_schemes:
        for r in s.eligibilityRules:
            if r.field in ["annualIncome", "annualFamilyIncome"] and r.value is not None:
                try:
                    thresholds[s.schemeId] = float(r.value)
                except (ValueError, TypeError):
                    pass

    return _income_service.estimate_income(input_data, thresholds)


@router.get("/csc", response_model=List[CscCentreRecord])
async def search_csc_centres(
    state: Optional[str] = Query(None, description="State name (e.g. Madhya Pradesh)"),
    district: Optional[str] = Query(None, description="District name (e.g. Bhopal)"),
    pin_code: Optional[str] = Query(None, description="6-digit Indian PIN Code"),
    limit: int = Query(10, ge=1, le=50),
):
    """Searches verified directory of Common Service Centres (CSCs) / Jan Seva Kendras."""
    return _assistance_service.search_csc(state=state, district=district, pin_code=pin_code, limit=limit)


@router.get("/conflicts/{scheme_id}", response_model=List[ConflictReport])
async def check_scheme_conflicts(
    scheme_id: str,
    db: SchemeDatabaseInterface = Depends(get_scheme_db),
):
    """Detects discrepancies, outdated conditions, and verification flags for a scheme."""
    scheme = await db.get_scheme(scheme_id)
    if not scheme:
        raise HTTPException(status_code=404, detail=f"Scheme '{scheme_id}' not found")
    return _assistance_service.detect_scheme_conflicts(scheme)


@router.get("/referral/{scheme_id}", response_model=HumanAssistanceReferral)
async def get_human_referral_package(
    scheme_id: str,
    reason: str = Query("Citizen requires in-person document verification", description="Reason for referral"),
    state: Optional[str] = Query(None),
    district: Optional[str] = Query(None),
    db: SchemeDatabaseInterface = Depends(get_scheme_db),
):
    """Generates official referral instructions, helpline info, and suggested CSC centre."""
    scheme = await db.get_scheme(scheme_id)
    if not scheme:
        raise HTTPException(status_code=404, detail=f"Scheme '{scheme_id}' not found")
    return _assistance_service.generate_human_referral(
        scheme=scheme,
        reason=reason,
        user_state=state,
        user_district=district,
    )

