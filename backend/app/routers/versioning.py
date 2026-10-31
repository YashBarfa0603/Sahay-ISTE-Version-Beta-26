"""
Scheme Rule Versioning and Provenance API Router.
Enforces rule audit trails, candidate review, and version rollback capabilities.
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from backend.app.database.db_interface import SchemeDatabaseInterface, get_scheme_db
from backend.app.models.scheme_schemas import EligibilityRuleSchema
from backend.app.services.versioning_service import (
    CandidateRuleProposal,
    RuleVersionRecord,
    SchemeVersioningService,
)

router = APIRouter(prefix="/api/versioning", tags=["Versioning"])

_versioning_service = SchemeVersioningService()


class ApprovalRequest(BaseModel):
    proposal_id: str
    reviewer_id: str
    review_notes: str


class RollbackRequest(BaseModel):
    scheme_id: str
    target_version: int
    operator_id: str
    reason: str


@router.get("/{scheme_id}/history", response_model=List[RuleVersionRecord])
async def get_rule_version_history(
    scheme_id: str,
    db: SchemeDatabaseInterface = Depends(get_scheme_db),
):
    """Retrieves auditable version history for a scheme's eligibility rules."""
    scheme = await db.get_scheme(scheme_id)
    if not scheme:
        raise HTTPException(status_code=404, detail=f"Scheme '{scheme_id}' not found")

    # Initialize v1 if not present
    _versioning_service.initialize_scheme_version(scheme)
    return _versioning_service.get_version_history(scheme_id)


@router.get("/proposals/pending", response_model=List[CandidateRuleProposal])
async def list_pending_rule_proposals(
    scheme_id: Optional[str] = Query(None, description="Optional schemeId filter"),
):
    """Lists candidate rules proposed by AI discovery or scraper waiting for human verification."""
    return _versioning_service.list_pending_proposals(scheme_id)


@router.post("/proposals", response_model=str)
async def submit_candidate_rule_proposal(proposal: CandidateRuleProposal):
    """Submits a candidate rule update. Does NOT modify production rules without human approval."""
    return _versioning_service.submit_candidate_proposal(proposal)


@router.post("/approve", response_model=RuleVersionRecord)
async def approve_rule_proposal(
    request: ApprovalRequest,
    db: SchemeDatabaseInterface = Depends(get_scheme_db),
):
    """Approves a candidate proposal, minting a new active rule version for the scheme."""
    record = _versioning_service.approve_proposal(
        proposal_id=request.proposal_id,
        reviewer_id=request.reviewer_id,
        notes=request.review_notes,
    )
    if not record:
        raise HTTPException(status_code=400, detail="Proposal not found or already processed")

    # Update database record rules
    scheme = await db.get_scheme(record.schemeId)
    if scheme:
        scheme.eligibilityRules = record.rules
        scheme.lastVerified = record.effectiveFrom
        await db.save_discovered_scheme(scheme)

    return record


@router.post("/rollback", response_model=RuleVersionRecord)
async def rollback_scheme_rules(
    request: RollbackRequest,
    db: SchemeDatabaseInterface = Depends(get_scheme_db),
):
    """Rolls back scheme eligibility rules to a specified prior verified version."""
    record = _versioning_service.rollback_to_version(
        scheme_id=request.scheme_id,
        target_version=request.target_version,
        operator_id=request.operator_id,
        reason=request.reason,
    )
    if not record:
        raise HTTPException(
            status_code=400,
            detail=f"Target version {request.target_version} not found in history for {request.scheme_id}",
        )

    # Update database record rules
    scheme = await db.get_scheme(record.schemeId)
    if scheme:
        scheme.eligibilityRules = record.rules
        scheme.lastVerified = record.effectiveFrom
        await db.save_discovered_scheme(scheme)

    return record

