"""
Pydantic Schemas for SAHAY Agentic AI Application Assistant.
Covers Application Sessions, Document OCR Extraction, Field Mappings,
Guided Forms, Direct Web Portal Integration, and Verification.
"""

from enum import Enum
from typing import Any, Dict, List, Optional, Union
from pydantic import BaseModel, Field


class InteractionMode(str, Enum):
    DIRECT_WEB = "direct_web"
    GUIDED_FORM = "guided_form"


class ApplicationStatus(str, Enum):
    PREPARING = "preparing"
    READY = "ready"
    IN_PROGRESS = "in_progress"
    AWAITING_USER_INPUT = "awaiting_user_input"
    AWAITING_CONFIRMATION = "awaiting_confirmation"
    VALIDATION_REQUIRED = "validation_required"
    READY_FOR_SUBMISSION = "ready_for_submission"
    SUBMITTED_CONFIRMED = "submitted_confirmed"
    CANCELLED = "cancelled"
    FAILED = "failed"


class FieldType(str, Enum):
    TEXT = "text"
    NUMBER = "number"
    DATE = "date"
    RADIO = "radio"
    CHECKBOX = "checkbox"
    DROPDOWN = "dropdown"
    ADDRESS = "address"
    PHONE = "phone"
    EMAIL = "email"
    DOCUMENT = "document"


class MappingStatus(str, Enum):
    PREFILLED = "prefilled"
    USER_CONFIRMED = "user_confirmed"
    MISSING = "missing"
    CONFLICT = "conflict"
    INVALID = "invalid"
    READY = "ready"


class SourceType(str, Enum):
    USER_PROFILE = "user_profile"
    UPLOADED_DOCUMENT = "uploaded_document"
    USER_INPUT = "user_input"
    OFFICIAL_PORTAL = "official_portal"


class PortalCompatibilityStatus(str, Enum):
    TESTED_SUPPORTED = "tested_supported"
    PARTIALLY_SUPPORTED = "partially_supported"
    GUIDED_ONLY = "guided_only"
    UNSUPPORTED = "unsupported"
    NOT_TESTED = "not_tested"


class DocumentVerificationStatus(str, Enum):
    UPLOADED = "uploaded"
    OCR_PROCESSED = "ocr_processed"
    EXTRACTED = "extracted"
    USER_CONFIRMED = "user_confirmed"
    OFFICIALLY_VERIFIED = "officially_verified"
    UNVERIFIED = "unverified"


class FieldMapping(BaseModel):
    """Represents a single application field with intelligent mapping and validation."""

    field_id: str
    field_label: str
    field_label_hi: Optional[str] = None
    field_type: FieldType = FieldType.TEXT
    is_required: bool = True
    options: Optional[List[str]] = None
    mapped_value: Optional[Any] = None
    source_type: Optional[SourceType] = None
    source_document_id: Optional[str] = None
    confidence: float = 1.0
    mapping_status: MappingStatus = MappingStatus.MISSING
    user_confirmed: bool = False
    validation_status: str = "pending"  # valid, invalid, pending
    validation_error: Optional[str] = None
    explanation: Optional[str] = None
    explanation_hi: Optional[str] = None
    explanation_hinglish: Optional[str] = None
    conditional_on: Optional[Dict[str, Any]] = None  # e.g. {"field_id": "hasDisability", "value": True}
    conflict_detected: bool = False
    conflict_details: Optional[Dict[str, Any]] = None  # profile_val, doc_val, description


class ApplicationSection(BaseModel):
    """Logical section of the application form."""

    section_id: str
    title: str
    title_hi: Optional[str] = None
    description: Optional[str] = None
    fields: List[FieldMapping] = []


class DocumentRequirement(BaseModel):
    """Document requirement matching and attachment metadata."""

    document_id: str  # canonical id, e.g. aadhaar_card
    document_name: str
    document_name_hi: Optional[str] = None
    is_mandatory: bool = True
    status: str = "missing"  # missing, uploaded, ocr_processed, attached
    source_document_id: Optional[str] = None
    verification_status: DocumentVerificationStatus = DocumentVerificationStatus.UNVERIFIED
    extracted_info: Optional[Dict[str, Any]] = None
    storage_path: Optional[str] = None


class PortalAdapterInfo(BaseModel):
    """Metadata regarding official government portal integration."""

    portal_id: str
    official_domain: str
    official_application_url: str
    scheme_ids: List[str] = []
    interaction_mode: InteractionMode = InteractionMode.GUIDED_FORM
    adapter_id: str
    supported_fields: List[str] = []
    document_upload_supported: bool = False
    authentication_requirements: str = "none"
    known_restrictions: List[str] = []
    compatibility_status: PortalCompatibilityStatus = PortalCompatibilityStatus.GUIDED_ONLY
    last_tested_at: str = "2026-10-31"


class ApplicationSessionModel(BaseModel):
    """Master application assistance session."""

    session_id: str
    user_id: str
    scheme_id: str
    scheme_name: str
    scheme_category: str
    official_application_url: Optional[str] = None
    interaction_mode: InteractionMode
    portal_adapter_id: Optional[str] = None
    status: ApplicationStatus = ApplicationStatus.PREPARING
    sections: List[ApplicationSection] = []
    documents: List[DocumentRequirement] = []
    validation_errors: List[str] = []
    warnings: List[str] = []
    can_submit: bool = False
    submission_confirmed: bool = False
    submission_reference: Optional[str] = None
    created_at: str
    updated_at: str


# ==========================================
# API Request / Response Schemas
# ==========================================


class ApplicationStartRequest(BaseModel):
    scheme_id: str
    interaction_mode: Optional[InteractionMode] = None
    language: Optional[str] = "en"


class ApplicationAnswerRequest(BaseModel):
    field_id: str
    value: Any
    user_confirmed: bool = True


class FieldConfirmRequest(BaseModel):
    field_id: str
    confirmed_value: Any
    source_type: Optional[SourceType] = SourceType.USER_INPUT


class FieldExplanationRequest(BaseModel):
    field_id: str
    field_label: str
    language: Optional[str] = "en"  # en, hi, hinglish


class FieldExplanationResponse(BaseModel):
    field_id: str
    field_label: str
    explanation: str
    example: Optional[str] = None
    language: str


class DocumentProcessRequest(BaseModel):
    document_id: str  # canonical ID, e.g. aadhaar_card
    file_bytes_base64: Optional[str] = None
    file_path: Optional[str] = None
    mime_type: Optional[str] = "image/jpeg"  # image/jpeg, image/png, application/pdf


class DocumentProcessResponse(BaseModel):
    document_id: str
    document_type: str
    confidence: float
    extracted_fields: Dict[str, Any]
    raw_text_summary: Optional[str] = None
    processing_status: str  # completed, partial, failed
    verification_status: DocumentVerificationStatus = DocumentVerificationStatus.OCR_PROCESSED


class DirectWebInspectRequest(BaseModel):
    current_url: str
    detected_inputs: List[Dict[str, Any]] = []


class DirectWebInspectResponse(BaseModel):
    portal_domain: str
    is_trusted_gov_domain: bool
    supported_fields_count: int
    unsupported_fields_count: int
    matched_mappings: List[FieldMapping] = []
    unsupported_reasons: List[str] = []


class DirectWebPopulateRequest(BaseModel):
    confirmed_fields: List[str] = []  # field_ids to populate


class DirectWebPopulateResponse(BaseModel):
    success: bool
    populated_fields: List[Dict[str, Any]] = []
    failed_fields: List[Dict[str, Any]] = []
    javascript_instructions: List[Dict[str, str]] = []  # controlled instructions, NOT arbitrary eval
    requires_user_captcha_otp: bool = True


class ApplicationValidationResponse(BaseModel):
    is_valid: bool
    missing_required_fields: List[str] = []
    conflicts: List[Dict[str, Any]] = []
    invalid_format_fields: List[str] = []
    missing_mandatory_documents: List[str] = []
    warnings: List[str] = []
    can_submit: bool = False


class SubmissionConfirmationRequest(BaseModel):
    user_explicit_approval: bool
    official_acknowledgement_number: Optional[str] = None
    portal_submission_timestamp: Optional[str] = None

