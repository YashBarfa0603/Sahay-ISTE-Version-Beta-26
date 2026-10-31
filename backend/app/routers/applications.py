"""
FastAPI Router for SAHAY Agentic AI Application Assistant.
Exposes endpoints for session lifecycles, document OCR processing,
guided forms, multilingual field explanations, deterministic validation,
review synthesis, and controlled direct-web portal interaction.
"""

import base64
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status

from backend.app.dependencies.auth import AuthenticatedUser, get_optional_user
from backend.app.schemas.application_schema import (
    ApplicationAnswerRequest,
    ApplicationSection,
    ApplicationSessionModel,
    ApplicationStartRequest,
    ApplicationValidationResponse,
    DirectWebInspectRequest,
    DirectWebInspectResponse,
    DirectWebPopulateRequest,
    DirectWebPopulateResponse,
    DocumentProcessRequest,
    DocumentProcessResponse,
    FieldConfirmRequest,
    FieldExplanationRequest,
    FieldExplanationResponse,
    SubmissionConfirmationRequest,
)
from backend.app.services.application_service import ApplicationService

router = APIRouter(prefix="/api/applications", tags=["Application Assistant"])
application_service = ApplicationService()


# ==========================================
# Application Sessions
# ==========================================


@router.post("/start", response_model=ApplicationSessionModel)
async def start_application_session(
    request: ApplicationStartRequest,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """
    Starts an intelligent application session for the specified government scheme.
    Retrieves scheme details, checks portal compatibility, and seeds prefilled fields.
    """
    user_profile = {"fullName": "Citizen Applicant", "email": user.email} if not user.is_guest else {}
    return await application_service.start_session(
        scheme_id=request.scheme_id,
        user_id=user.uid,
        user_profile=user_profile,
        requested_mode=request.interaction_mode,
        language=request.language or "en",
    )


@router.get("/{session_id}", response_model=ApplicationSessionModel)
async def get_application_session(
    session_id: str,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Retrieves current application session state."""
    return application_service.get_session(session_id, user.uid)


@router.post("/{session_id}/cancel")
async def cancel_application_session(
    session_id: str,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Cancels an active application session."""
    success = application_service.cancel_session(session_id, user.uid)
    return {"session_id": session_id, "status": "cancelled", "success": success}


@router.get("/{session_id}/context")
async def get_application_context(
    session_id: str,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Returns scheme metadata, required documents, and instructions."""
    session = application_service.get_session(session_id, user.uid)
    return {
        "session_id": session.session_id,
        "scheme_id": session.scheme_id,
        "scheme_name": session.scheme_name,
        "category": session.scheme_category,
        "official_url": session.official_application_url,
        "interaction_mode": session.interaction_mode.value,
        "documents_required": [doc.model_dump() for doc in session.documents],
    }


# ==========================================
# Profile and Documents
# ==========================================


@router.get("/{session_id}/documents")
async def list_session_documents(
    session_id: str,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Lists document checklist and processing statuses for the active scheme."""
    session = application_service.get_session(session_id, user.uid)
    return {"documents": [d.model_dump() for d in session.documents]}


@router.post("/{session_id}/documents/process", response_model=DocumentProcessResponse)
async def process_document(
    session_id: str,
    request: DocumentProcessRequest,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """
    Processes an uploaded document using OpenCV enhancements and EasyOCR bilingual extraction.
    Automatically binds extracted entities into corresponding form fields.
    """
    if not request.file_bytes_base64:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing document file bytes (file_bytes_base64 required).",
        )

    try:
        raw_bytes = base64.b64decode(request.file_bytes_base64)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Malformed base64 file data: {e}",
        )

    return await application_service.process_document_bytes(
        session_id=session_id,
        user_id=user.uid,
        document_id=request.document_id,
        file_bytes=raw_bytes,
        mime_type=request.mime_type or "image/jpeg",
    )


# ==========================================
# Form Understanding & Field Operations
# ==========================================


@router.get("/{session_id}/guided-form")
async def get_guided_form(
    session_id: str,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Returns the structured application sections and dynamic fields."""
    session = application_service.get_session(session_id, user.uid)
    return {
        "session_id": session.session_id,
        "sections": [sec.model_dump() for sec in session.sections],
        "can_submit": session.can_submit,
    }


@router.post("/{session_id}/guided-form/answer", response_model=ApplicationSessionModel)
async def submit_guided_form_answer(
    session_id: str,
    answer: ApplicationAnswerRequest,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Updates an application field answer and validates state."""
    return application_service.answer_field(session_id, user.uid, answer)


@router.post("/{session_id}/confirm-field", response_model=ApplicationSessionModel)
async def confirm_field_conflict(
    session_id: str,
    request: FieldConfirmRequest,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Explicitly confirms a field value when profile and document disagree."""
    return application_service.confirm_field_conflict(
        session_id, user.uid, request.field_id, request.confirmed_value
    )


@router.post("/{session_id}/explain-field", response_model=FieldExplanationResponse)
async def explain_field(
    session_id: str,
    request: FieldExplanationRequest,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Explains a confusing government field in plain English, Hindi or Hinglish."""
    res = application_service.explain_field(
        request.field_id, request.field_label, request.language or "en"
    )
    return FieldExplanationResponse(
        field_id=request.field_id,
        field_label=request.field_label,
        explanation=res["explanation"],
        example=res.get("example"),
        language=res.get("language", request.language or "en"),
    )


# ==========================================
# Validation & Review
# ==========================================


@router.post("/{session_id}/validate", response_model=ApplicationValidationResponse)
async def validate_application(
    session_id: str,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Runs deterministic validation checks across all fields and documents."""
    return application_service.validate_session(session_id, user.uid)


@router.get("/{session_id}/review")
async def get_application_review(
    session_id: str,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Returns complete synthesized review payload prior to final citizen approval."""
    return application_service.get_review_summary(session_id, user.uid)


# ==========================================
# Direct Web Portal Integration
# ==========================================


@router.post("/{session_id}/portal/inspect", response_model=DirectWebInspectResponse)
async def inspect_portal_page(
    session_id: str,
    request: DirectWebInspectRequest,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Inspects inputs on the current official portal webpage via controlled bridge."""
    return application_service.inspect_web_portal(
        session_id, user.uid, request.current_url, request.detected_inputs
    )


@router.post("/{session_id}/portal/populate", response_model=DirectWebPopulateResponse)
async def populate_portal_fields(
    session_id: str,
    request: DirectWebPopulateRequest,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """Emits declarative, safe field population instructions for citizen-approved fields."""
    return application_service.populate_web_portal(
        session_id, user.uid, request.confirmed_fields
    )


# ==========================================
# Final Submission Confirmation
# ==========================================


@router.post("/{session_id}/submission-confirmation")
async def confirm_submission(
    session_id: str,
    request: SubmissionConfirmationRequest,
    user: AuthenticatedUser = Depends(get_optional_user),
):
    """
    Marks application as officially confirmed.
    MANDATORY REQUIREMENT: Explicit citizen approval is strictly enforced.
    """
    success = application_service.confirm_submission(
        session_id=session_id,
        user_id=user.uid,
        user_approved=request.user_explicit_approval,
        acknowledgement_number=request.official_acknowledgement_number,
    )
    return {
        "session_id": session_id,
        "submitted": success,
        "acknowledgement_number": request.official_acknowledgement_number or "SAHAY-ACK-CONFIRMED",
        "status": "submitted_confirmed",
    }

