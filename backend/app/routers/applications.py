"""
FastAPI Router for SAHAY Smart Application Filler.
Exposes endpoints for the 10-scheme central registry, resumable sessions,
missing field answering, conflict resolution, declarative portal population payloads,
read-back verification, and citizen submission confirmation.
"""

from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status

from backend.app.dependencies.auth import AuthenticatedUser, get_optional_user
from backend.app.schemas.application_schema import (
    ApplicationSessionModel,
    ApplicationStartRequest,
    ApplicationValidationResponse,
    ConflictResolveRequest,
    MissingFieldsAnswerRequest,
    PortalPopulationPayload,
    PortalReadBackVerifyRequest,
    ReadBackVerificationReport,
    SchemeRegistryEntry,
    SubmissionConfirmationRequest,
)
from backend.app.services.application_service import ApplicationService

router = APIRouter(prefix="/api/applications", tags=["Smart Application Filler"])
application_service = ApplicationService()


# ==========================================
# Central Registry of Supported Schemes
# ==========================================


@router.get("/supported-schemes", response_model=List[SchemeRegistryEntry])
def get_supported_schemes():
    """
    Returns the central registry of the 10 verified government scheme workflows
    supported by the SAHAY Smart Application Filler.
    """
    return application_service.get_supported_schemes()


# ==========================================
# Application Sessions (Resumable Workflow)
# ==========================================


@router.post("/start", response_model=ApplicationSessionModel)
def start_application_session(
    request: ApplicationStartRequest,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """
    Starts or resumes an application session for one of the 10 supported schemes.
    Collates profile answers and document vault records with provenance.
    """
    user_id = user.uid if not user.is_guest else "guest_user"
    return application_service.start_session(
        scheme_id=request.scheme_id,
        user_id=user_id,
        user_profile=request.user_profile_answers,
        language=request.language or "en",
    )


@router.get("/{session_id}", response_model=ApplicationSessionModel)
def get_application_session(
    session_id: str,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Retrieves current application session state."""
    return application_service.get_session(session_id)


# ==========================================
# Missing Information & Conflict Resolution
# ==========================================


@router.post("/{session_id}/answer-missing", response_model=ApplicationSessionModel)
def answer_missing_fields(
    session_id: str,
    request: MissingFieldsAnswerRequest,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Answers genuinely missing fields identified for the target scheme."""
    return application_service.answer_missing_fields(session_id, request.answers)


@router.post("/{session_id}/resolve-conflict", response_model=ApplicationSessionModel)
def resolve_conflict(
    session_id: str,
    request: ConflictResolveRequest,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Resolves conflicting values where user profile and document OCR disagree."""
    return application_service.resolve_field_conflict(
        session_id=session_id,
        field_id=request.field_id,
        confirmed_value=request.confirmed_value,
        chosen_source=request.chosen_source,
    )


# ==========================================
# Portal Automation & Read-Back Verification
# ==========================================


@router.get("/{session_id}/portal/populate-payload", response_model=PortalPopulationPayload)
def get_portal_populate_payload(
    session_id: str,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """
    Emits declarative, sanitized field population commands and read-back selectors
    for the official government portal.
    """
    return application_service.get_portal_population_payload(session_id)


@router.post("/{session_id}/portal/verify-readback", response_model=ReadBackVerificationReport)
def verify_portal_readback(
    session_id: str,
    request: PortalReadBackVerifyRequest,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """
    Compares expected populated values against read-back values directly inspected
    from the portal DOM, generating a deterministic verification report.
    """
    return application_service.verify_portal_readback(
        session_id=session_id,
        actual_dom_values=request.read_back_data,
    )


# ==========================================
# Validation & Submission Confirmation
# ==========================================


@router.post("/{session_id}/validate", response_model=ApplicationValidationResponse)
def validate_application(
    session_id: str,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Runs deterministic pre-submission validation checks across all sections."""
    return application_service.validate_session(session_id)


@router.post("/{session_id}/confirm-submission", response_model=ApplicationSessionModel)
def confirm_submission(
    session_id: str,
    request: SubmissionConfirmationRequest,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """
    CRITICAL CITIZEN GATE:
    Finalizes the application only after the citizen gives explicit confirmation.
    """
    return application_service.confirm_submission(
        session_id=session_id,
        user_explicit_approval=request.user_explicit_approval,
        acknowledgement_number=request.official_acknowledgement_number,
    )
