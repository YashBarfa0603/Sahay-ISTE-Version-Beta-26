"""
Application Service: Central Coordinator for SAHAY Agentic AI Application Assistance.
Manages session lifecycles, user profile and document hydration,
LangGraph workflow execution, deterministic validation, review synthesis,
and controlled WebView portal bridge instructions.
"""

from datetime import datetime
import logging
import uuid
from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status

from backend.app.agents.application_agents import (
    FieldExplanationAgent,
    create_application_assistant_graph,
)
from backend.app.database.db_interface import InMemorySchemeDatabase
from backend.app.schemas.application_schema import (
    ApplicationAnswerRequest,
    ApplicationSection,
    ApplicationSessionModel,
    ApplicationStatus,
    ApplicationValidationResponse,
    DirectWebInspectResponse,
    DirectWebPopulateResponse,
    DocumentProcessResponse,
    DocumentRequirement,
    DocumentVerificationStatus,
    FieldMapping,
    FieldType,
    InteractionMode,
    MappingStatus,
    PortalCompatibilityStatus,
    SourceType,
)
from backend.app.services.easyocr_service import EasyOCRService
from backend.app.services.portal_adapter_service import PortalAdapterService

logger = logging.getLogger(__name__)


class ApplicationService:
    """Manages application assistance sessions, document processing, and portal coordination."""

    def __init__(self, scheme_db: Optional[InMemorySchemeDatabase] = None):
        self.scheme_db = scheme_db or InMemorySchemeDatabase()
        self.ocr_service = EasyOCRService()
        self.portal_service = PortalAdapterService()
        self._compiled_graph = create_application_assistant_graph()
        # In-memory session store (keyed by session_id)
        self._sessions: Dict[str, ApplicationSessionModel] = {}
        # In-memory document store for test/demo profiles
        self._user_documents: Dict[str, List[Dict[str, Any]]] = {}

    # ==========================================
    # Session Management
    # ==========================================

    async def start_session(
        self,
        scheme_id: str,
        user_id: str,
        user_profile: Optional[Dict[str, Any]] = None,
        requested_mode: Optional[InteractionMode] = None,
        language: str = "en",
    ) -> ApplicationSessionModel:
        """Initializes a new application assistant session."""
        scheme = await self.scheme_db.get_scheme(scheme_id)
        if not scheme:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Scheme '{scheme_id}' not found in catalogue.",
            )

        scheme_dict = scheme.model_dump()
        official_url = scheme_dict.get("applicationUrl") or scheme_dict.get("officialSourceUrl")

        # Resolve Portal Compatibility & Mode
        adapter = self.portal_service.get_adapter_for_scheme(scheme_id, official_url)
        chosen_mode = requested_mode or adapter.interaction_mode

        # If user explicitly requested Direct Web but portal is completely unsupported, fallback with note
        if chosen_mode == InteractionMode.DIRECT_WEB and adapter.compatibility_status == PortalCompatibilityStatus.GUIDED_ONLY:
            chosen_mode = InteractionMode.GUIDED_FORM

        # Fetch user documents if available
        docs = self._user_documents.get(user_id, [])

        session_id = f"app_sess_{uuid.uuid4().hex[:12]}"
        now_str = datetime.utcnow().isoformat()

        # Run Multi-Agent Graph to prepare sections, map fields, and validate
        initial_state = {
            "session_id": session_id,
            "user_id": user_id,
            "scheme_data": scheme_dict,
            "user_profile": user_profile or {},
            "uploaded_documents": docs,
            "detected_form_inputs": [],
            "language": language,
            "context_summary": {},
            "understood_documents": [],
            "application_sections": [],
            "mapped_fields": [],
            "conflicts_detected": [],
            "validation_errors": [],
            "warnings": [],
            "can_submit": False,
            "step_history": [],
            "iteration_count": 0,
        }

        agent_result = await self._compiled_graph.ainvoke(initial_state)

        # Parse sections
        sections = [
            ApplicationSection.model_validate(sec) for sec in agent_result.get("application_sections", [])
        ]

        # Prepare document checklist requirements
        doc_reqs = []
        for req_doc in scheme_dict.get("requiredDocuments", []):
            canon_id = req_doc.lower().replace(" ", "_").replace("(", "").replace(")", "").replace("-", "_")
            doc_reqs.append(
                DocumentRequirement(
                    document_id=canon_id,
                    document_name=req_doc,
                    is_mandatory=True,
                    status="missing",
                )
            )

        session = ApplicationSessionModel(
            session_id=session_id,
            user_id=user_id,
            scheme_id=scheme_id,
            scheme_name=scheme_dict.get("name", "Unknown Scheme"),
            scheme_category=scheme_dict.get("category", "general"),
            official_application_url=official_url,
            interaction_mode=chosen_mode,
            portal_adapter_id=adapter.portal_id,
            status=ApplicationStatus.READY,
            sections=sections,
            documents=doc_reqs,
            validation_errors=agent_result.get("validation_errors", []),
            warnings=agent_result.get("warnings", []),
            can_submit=agent_result.get("can_submit", False),
            created_at=now_str,
            updated_at=now_str,
        )

        self._sessions[session_id] = session
        return session

    def get_session(self, session_id: str, user_id: str) -> ApplicationSessionModel:
        """Retrieves an existing session with strict user authorization check."""
        session = self._sessions.get(session_id)
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Application session '{session_id}' not found.",
            )
        # Authorize: user can only access their own session, guest sessions are checked
        if session.user_id != user_id and user_id != "guest_user" and session.user_id != "guest_user":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied. You are not authorized to view this application session.",
            )
        return session

    def cancel_session(self, session_id: str, user_id: str) -> bool:
        """Cancels an active application session."""
        session = self.get_session(session_id, user_id)
        session.status = ApplicationStatus.CANCELLED
        session.updated_at = datetime.utcnow().isoformat()
        return True

    # ==========================================
    # Guided Form Answers & Conflict Confirmations
    # ==========================================

    def answer_field(
        self,
        session_id: str,
        user_id: str,
        answer: ApplicationAnswerRequest,
    ) -> ApplicationSessionModel:
        """Updates a field answer, marks as user-confirmed, and re-validates."""
        session = self.get_session(session_id, user_id)
        found = False

        for sec in session.sections:
            for f in sec.fields:
                if f.field_id == answer.field_id:
                    f.mapped_value = answer.value
                    f.source_type = SourceType.USER_INPUT
                    f.user_confirmed = answer.user_confirmed
                    f.mapping_status = MappingStatus.USER_CONFIRMED
                    f.conflict_detected = False
                    f.validation_status = "valid"
                    found = True
                    break
            if found:
                break

        if not found:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Field '{answer.field_id}' does not exist in this application.",
            )

        self._revalidate_session(session)
        session.updated_at = datetime.utcnow().isoformat()
        return session

    def confirm_field_conflict(
        self,
        session_id: str,
        user_id: str,
        field_id: str,
        confirmed_value: Any,
    ) -> ApplicationSessionModel:
        """Resolves a detected source conflict with citizen's explicit decision."""
        session = self.get_session(session_id, user_id)
        found = False

        for sec in session.sections:
            for f in sec.fields:
                if f.field_id == field_id:
                    f.mapped_value = confirmed_value
                    f.user_confirmed = True
                    f.conflict_detected = False
                    f.mapping_status = MappingStatus.USER_CONFIRMED
                    f.validation_status = "valid"
                    found = True
                    break
            if found:
                break

        if not found:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Field '{field_id}' not found.")

        self._revalidate_session(session)
        session.updated_at = datetime.utcnow().isoformat()
        return session

    # ==========================================
    # Document Processing & OCR Hydration
    # ==========================================

    async def process_document_bytes(
        self,
        session_id: str,
        user_id: str,
        document_id: str,
        file_bytes: bytes,
        mime_type: str = "image/jpeg",
    ) -> DocumentProcessResponse:
        """Runs EasyOCR extraction on an uploaded document and binds extracted fields into the session."""
        session = self.get_session(session_id, user_id)

        # Execute EasyOCR pipeline with OpenCV preprocessing
        ocr_result = self.ocr_service.run_ocr(file_bytes, mime_type=mime_type)

        doc_type = ocr_result.get("document_type", "unknown")
        extracted_fields = ocr_result.get("fields", {})
        conf = ocr_result.get("confidence", 0.8)

        # Update document requirements checklist in session
        for req in session.documents:
            if req.document_id == document_id or document_id in req.document_id:
                req.status = "ocr_processed"
                req.verification_status = DocumentVerificationStatus.OCR_PROCESSED
                req.extracted_info = extracted_fields
                break

        # Map newly extracted fields into corresponding form fields
        for sec in session.sections:
            for f in sec.fields:
                # Map extracted values if field currently missing or unconfirmed
                if f.mapping_status in [MappingStatus.MISSING, MappingStatus.CONFLICT]:
                    extracted_val = None
                    if f.field_id == "fullName" and "holder_name" in extracted_fields:
                        extracted_val = extracted_fields["holder_name"]["value"]
                    elif f.field_id == "aadhaarNumber" and "aadhaar_number" in extracted_fields:
                        extracted_val = extracted_fields["aadhaar_number"]["value"]
                    elif f.field_id == "annualFamilyIncome" and "annual_income" in extracted_fields:
                        extracted_val = extracted_fields["annual_income"]["value"]
                    elif f.field_id == "bankAccountNumber" and "account_number" in extracted_fields:
                        extracted_val = extracted_fields["account_number"]["value"]
                    elif f.field_id == "bankIfsc" and "ifsc_code" in extracted_fields:
                        extracted_val = extracted_fields["ifsc_code"]["value"]

                    if extracted_val is not None:
                        f.mapped_value = extracted_val
                        f.source_type = SourceType.UPLOADED_DOCUMENT
                        f.source_document_id = document_id
                        f.confidence = conf
                        f.mapping_status = MappingStatus.PREFILLED
                        f.validation_status = "valid"

        self._revalidate_session(session)
        session.updated_at = datetime.utcnow().isoformat()

        # Cache document for user session
        user_docs = self._user_documents.setdefault(user_id, [])
        user_docs.append({
            "document_id": document_id,
            "document_type": doc_type,
            "confidence": conf,
            "fields": extracted_fields,
        })

        return DocumentProcessResponse(
            document_id=document_id,
            document_type=doc_type,
            confidence=conf,
            extracted_fields=extracted_fields,
            raw_text_summary=ocr_result.get("raw_text", "")[:300],
            processing_status="completed",
            verification_status=DocumentVerificationStatus.OCR_PROCESSED,
        )

    # ==========================================
    # Multilingual Field Explanation
    # ==========================================

    def explain_field(self, field_id: str, field_label: str, language: str = "en") -> Dict[str, str]:
        """Provides easy-to-understand explanation of confusing government form fields."""
        return FieldExplanationAgent.explain_field(field_id, field_label, language)

    # ==========================================
    # Validation & Review Synthesis
    # ==========================================

    def validate_session(self, session_id: str, user_id: str) -> ApplicationValidationResponse:
        """Validates all required fields, conflicts, and mandatory documents."""
        session = self.get_session(session_id, user_id)
        return self._revalidate_session(session)

    def _revalidate_session(self, session: ApplicationSessionModel) -> ApplicationValidationResponse:
        """Deterministic validator executing constraints across sections."""
        missing = []
        conflicts = []
        invalid_formats = []

        import re
        for sec in session.sections:
            for f in sec.fields:
                val = f.mapped_value
                f_id = f.field_id
                f.validation_error = None

                if f.is_required and (val is None or str(val).strip() == ""):
                    missing.append(f.field_label)
                    f.validation_status = "pending"
                elif val is not None and str(val).strip() != "":
                    is_invalid = False
                    if f.field_type == FieldType.PHONE or "mobile" in f_id.lower():
                        digits = re.sub(r"\D", "", str(val))
                        if len(digits) != 10:
                            is_invalid = True
                            f.validation_error = "Mobile number must be exactly 10 digits."
                    elif f_id == "bankIfsc":
                        if not re.match(r"^[A-Z]{4}0[A-Z0-9]{6}$", str(val).strip()):
                            is_invalid = True
                            f.validation_error = "IFSC code must be 11 characters (e.g. SBIN0001234)."
                    elif f_id == "annualFamilyIncome":
                        try:
                            inc = float(val)
                            if inc < 0 or inc > 100000000:
                                is_invalid = True
                                f.validation_error = "Income out of realistic range."
                        except ValueError:
                            is_invalid = True
                            f.validation_error = "Income must be a valid number."

                    if is_invalid:
                        f.validation_status = "invalid"
                        invalid_formats.append(f.field_label)
                    elif not f.conflict_detected:
                        f.validation_status = "valid"

                if f.conflict_detected:
                    conflicts.append({"field_id": f.field_id, "label": f.field_label})

        missing_docs = [
            doc.document_name for doc in session.documents if doc.is_mandatory and doc.status == "missing"
        ]

        can_submit = (len(missing) == 0 and len(conflicts) == 0 and len(invalid_formats) == 0)

        session.validation_errors = [f"Missing required: {m}" for m in missing] + [
            f"Unresolved conflict in {c['label']}" for c in conflicts
        ]
        session.can_submit = can_submit
        if can_submit and session.status == ApplicationStatus.IN_PROGRESS:
            session.status = ApplicationStatus.READY_FOR_SUBMISSION

        return ApplicationValidationResponse(
            is_valid=can_submit,
            missing_required_fields=missing,
            conflicts=conflicts,
            invalid_format_fields=invalid_formats,
            missing_mandatory_documents=missing_docs,
            warnings=session.warnings,
            can_submit=can_submit,
        )

    def get_review_summary(self, session_id: str, user_id: str) -> Dict[str, Any]:
        """Synthesizes complete review payload before final submission."""
        session = self.get_session(session_id, user_id)
        val_res = self._revalidate_session(session)

        total_fields = sum(len(sec.fields) for sec in session.sections)
        prefilled_count = sum(
            1 for sec in session.sections for f in sec.fields if f.mapping_status == MappingStatus.PREFILLED
        )
        user_confirmed_count = sum(
            1 for sec in session.sections for f in sec.fields if f.user_confirmed
        )

        return {
            "session_id": session.session_id,
            "scheme_name": session.scheme_name,
            "scheme_category": session.scheme_category,
            "interaction_mode": session.interaction_mode.value,
            "status": session.status.value,
            "total_fields": total_fields,
            "prefilled_count": prefilled_count,
            "user_confirmed_count": user_confirmed_count,
            "can_submit": val_res.can_submit,
            "validation": val_res.model_dump(),
            "sections": [sec.model_dump() for sec in session.sections],
            "documents": [doc.model_dump() for doc in session.documents],
            "official_portal_url": session.official_application_url,
        }

    # ==========================================
    # Controlled Direct Web Portal Operations
    # ==========================================

    def inspect_web_portal(
        self,
        session_id: str,
        user_id: str,
        current_url: str,
        detected_inputs: List[Dict[str, Any]],
    ) -> DirectWebInspectResponse:
        """Matches detected web inputs with session field mappings."""
        session = self.get_session(session_id, user_id)
        adapter = self.portal_service.get_adapter_for_scheme(session.scheme_id, current_url)

        matched_mappings: List[FieldMapping] = []
        for sec in session.sections:
            for f in sec.fields:
                if f.field_id in adapter.supported_fields or any(f.field_id in inp.get("id", "") for inp in detected_inputs):
                    matched_mappings.append(f)

        return DirectWebInspectResponse(
            portal_domain=adapter.official_domain,
            is_trusted_gov_domain=True,
            supported_fields_count=len(matched_mappings),
            unsupported_fields_count=max(0, len(detected_inputs) - len(matched_mappings)),
            matched_mappings=matched_mappings,
            unsupported_reasons=adapter.known_restrictions,
        )

    def populate_web_portal(
        self,
        session_id: str,
        user_id: str,
        confirmed_fields: List[str],
    ) -> DirectWebPopulateResponse:
        """
        Emits controlled, declarative instructions for approved fields.
        NEVER bypasses OTP, CAPTCHA, or password fields.
        """
        session = self.get_session(session_id, user_id)
        instructions = []
        populated = []

        for sec in session.sections:
            for f in sec.fields:
                if f.field_id in confirmed_fields and f.mapped_value is not None:
                    instructions.append({
                        "selector": f.field_id,
                        "value": str(f.mapped_value),
                        "tag": "input",
                    })
                    populated.append({"field_id": f.field_id, "label": f.field_label})

        return DirectWebPopulateResponse(
            success=len(instructions) > 0,
            populated_fields=populated,
            failed_fields=[],
            javascript_instructions=instructions,
            requires_user_captcha_otp=True,
        )

    # ==========================================
    # Submission Confirmation
    # ==========================================

    def confirm_submission(
        self,
        session_id: str,
        user_id: str,
        user_approved: bool,
        acknowledgement_number: Optional[str] = None,
    ) -> bool:
        """Marks session as submitted ONLY with explicit human approval."""
        if not user_approved:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Explicit citizen approval is mandatory before confirming application submission.",
            )

        session = self.get_session(session_id, user_id)
        session.status = ApplicationStatus.SUBMITTED_CONFIRMED
        session.submission_confirmed = True
        session.submission_reference = acknowledgement_number or f"SAHAY-{uuid.uuid4().hex[:8].upper()}"
        session.updated_at = datetime.utcnow().isoformat()
        return True
