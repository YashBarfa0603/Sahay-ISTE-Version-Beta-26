"""
Pydantic Schemas for SAHAY Smart Application Filler.
Covers 10-Scheme Unified Application Sessions, Citizen Normalized Store,
Data Provenance, Document OCR, Form Configurations, Portal Adapters,
and Read-Back Verification.
"""

from enum import Enum
from typing import Any, Dict, List, Optional, Union
from pydantic import BaseModel, Field


class ApplicationStatus(str, Enum):
    PREPARING = "preparing"
    READY = "ready"
    IN_PROGRESS = "in_progress"
    AWAITING_USER_INPUT = "awaiting_user_input"
    AWAITING_PORTAL_AUTH = "awaiting_portal_auth"
    FILLING_PORTAL = "filling_portal"
    READBACK_VERIFYING = "readback_verifying"
    READY_FOR_REVIEW = "ready_for_review"
    AWAITING_FINAL_APPROVAL = "awaiting_final_approval"
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
    USER_CONFIRMED_ANSWER = "user_confirmed_answer"
    DOCUMENT_OCR = "document_ocr"
    DOCUMENT_METADATA = "document_metadata"
    PREVIOUSLY_CONFIRMED_APPLICATION_DATA = "previously_confirmed_application_data"
    OFFICIAL_PORTAL = "official_portal"


class PortalCompatibilityStatus(str, Enum):
    FULLY_SUPPORTED = "fully_supported"
    PARTIALLY_SUPPORTED = "partially_supported"
    BLOCKED = "blocked"


class DocumentVerificationStatus(str, Enum):
    UPLOADED = "uploaded"
    OCR_PROCESSED = "ocr_processed"
    EXTRACTED = "extracted"
    USER_CONFIRMED = "user_confirmed"
    OFFICIALLY_VERIFIED = "officially_verified"
    UNVERIFIED = "unverified"


class ReadBackFieldStatus(str, Enum):
    FILLED_VERIFIED = "filled_verified"
    FILLED_UNVERIFIED = "filled_unverified"
    NEEDS_USER_CONFIRMATION = "needs_user_confirmation"
    MANUAL_ACTION_REQUIRED = "manual_action_required"
    MISSING = "missing"
    FAILED = "failed"
    UNSUPPORTED = "unsupported"


# ==========================================
# Provenance & Citizen Profile Schemas
# ==========================================


class ValueProvenance(BaseModel):
    """Detailed provenance tracking for every field in SAHAY."""

    field: str
    value: Any
    source: str = "user_profile"  # user_profile, document_ocr, user_confirmed_answer, etc.
    verification_status: str = "self_reported"  # self_reported, ocr_extracted, user_confirmed, verified
    source_document_id: Optional[str] = None
    confidence: float = 1.0
    last_updated_at: str


class PersonalInformation(BaseModel):
    full_name: Optional[str] = None
    dob: Optional[str] = None
    gender: Optional[str] = None
    age: Optional[int] = None
    father_name: Optional[str] = None


class ContactInformation(BaseModel):
    mobile_number: Optional[str] = None
    email: Optional[str] = None


class AddressInformation(BaseModel):
    state: Optional[str] = None
    district: Optional[str] = None
    sub_district: Optional[str] = None
    block: Optional[str] = None
    village: Optional[str] = None
    city: Optional[str] = None
    pincode: Optional[str] = None
    full_address: Optional[str] = None


class SocialInformation(BaseModel):
    caste_category: Optional[str] = None  # General, OBC, SC, ST
    marital_status: Optional[str] = None
    is_disabled: bool = False
    disability_type: Optional[str] = None
    disability_percentage: Optional[int] = None


class FinancialInformation(BaseModel):
    annual_income: Optional[int] = None
    household_income: Optional[int] = None
    bank_account_holder: Optional[str] = None
    bank_name: Optional[str] = None
    bank_account_number: Optional[str] = None
    ifsc_code: Optional[str] = None


class OccupationInformation(BaseModel):
    employment_type: Optional[str] = None
    occupation_name: Optional[str] = None
    business_name: Optional[str] = None
    is_farmer: bool = False
    land_area_hectares: Optional[float] = None
    khasra_number: Optional[str] = None
    vending_activity: Optional[str] = None


class EducationInformation(BaseModel):
    institution_name: Optional[str] = None
    course_name: Optional[str] = None
    qualification: Optional[str] = None
    admission_year: Optional[int] = None
    marks_percentage: Optional[float] = None


class NormalizedCitizenProfile(BaseModel):
    """Normalized citizen profile collation from SAHAY profile and Document Vault."""

    user_id: str
    personal: PersonalInformation = PersonalInformation()
    contact: ContactInformation = ContactInformation()
    address: AddressInformation = AddressInformation()
    social: SocialInformation = SocialInformation()
    financial: FinancialInformation = FinancialInformation()
    occupation: OccupationInformation = OccupationInformation()
    education: EducationInformation = EducationInformation()
    provenance_map: Dict[str, ValueProvenance] = {}


# ==========================================
# Field Mapping & Section Schemas
# ==========================================


class FieldMapping(BaseModel):
    """Represents a single application field with provenance, mapping and validation."""

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
    conditional_on: Optional[Dict[str, Any]] = None
    conflict_detected: bool = False
    conflict_details: Optional[Dict[str, Any]] = None
    provenance: Optional[ValueProvenance] = None
    portal_selector: Optional[str] = None
    read_back_status: Optional[ReadBackFieldStatus] = None


class ApplicationSection(BaseModel):
    """Logical section of the unified application form."""

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
    portal_upload_supported: bool = False
    portal_upload_selector: Optional[str] = None
    max_size_kb: int = 500


# ==========================================
# Central 10-Scheme Registry Schema
# ==========================================


class SchemeRegistryEntry(BaseModel):
    """Central registry model for the 10 supported government scheme workflows."""

    schemeId: str
    schemeName: str
    alternateNames: List[str] = []
    category: str
    stateOrCentral: str  # central, state
    officialSchemeUrl: str
    officialApplicationUrl: str
    applicationMode: str = "smart_filler"  # unified assistant mode
    portalDomain: str
    adapterId: str
    supportedFields: List[str] = []
    requiredDocuments: List[str] = []
    authenticationRequirements: str  # aadhaar_otp, mobile_otp, etc.
    manualInterventionRequirements: List[str] = []
    portalCompatibilityStatus: PortalCompatibilityStatus = PortalCompatibilityStatus.FULLY_SUPPORTED
    lastTestedAt: str
    lastVerifiedAt: str
    applicationAvailabilityStatus: str  # active_accepting_applications, seasonal, portal_maintenance
    knownLimitations: List[str] = []


# ==========================================
# Read-Back Verification Schemas
# ==========================================


class ReadBackFieldItem(BaseModel):
    field_id: str
    selector: str
    expected_value: Any
    read_value: Optional[Any] = None
    status: ReadBackFieldStatus
    message: Optional[str] = None


class ReadBackVerificationReport(BaseModel):
    total_fields: int
    verified_count: int
    unverified_count: int
    manual_action_count: int
    failed_count: int
    items: List[ReadBackFieldItem] = []
    can_proceed_to_review: bool = False


# ==========================================
# Master Application Session
# ==========================================


class ApplicationSessionModel(BaseModel):
    """Master application assistance session with resumable state."""

    session_id: str
    user_id: str
    scheme_id: str
    scheme_name: str
    scheme_category: str
    official_application_url: Optional[str] = None
    portal_adapter_id: Optional[str] = None
    status: ApplicationStatus = ApplicationStatus.PREPARING
    sections: List[ApplicationSection] = []
    documents: List[DocumentRequirement] = []
    missing_fields_count: int = 0
    conflicts_count: int = 0
    validation_errors: List[str] = []
    warnings: List[str] = []
    read_back_report: Optional[ReadBackVerificationReport] = None
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
    language: Optional[str] = "en"
    user_profile_answers: Optional[Dict[str, Any]] = None


class MissingFieldsAnswerRequest(BaseModel):
    answers: Dict[str, Any]  # field_id -> value


class ConflictResolveRequest(BaseModel):
    field_id: str
    confirmed_value: Any
    chosen_source: str = "user_confirmed_answer"


class FieldExplanationRequest(BaseModel):
    field_id: str
    field_label: str
    language: Optional[str] = "en"


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
    mime_type: Optional[str] = "image/jpeg"


class DocumentProcessResponse(BaseModel):
    document_id: str
    document_type: str
    confidence: float
    extracted_fields: Dict[str, Any]
    raw_text_summary: Optional[str] = None
    processing_status: str
    verification_status: DocumentVerificationStatus = DocumentVerificationStatus.OCR_PROCESSED


class PortalPopulationPayload(BaseModel):
    portal_id: str
    portal_domain: str
    declarative_instructions: List[Dict[str, Any]] = []
    read_back_selectors: List[Dict[str, str]] = []
    manual_intervention_required: List[str] = []


class PortalReadBackVerifyRequest(BaseModel):
    read_back_data: Dict[str, Any]  # selector or field_id -> actualDOMValue


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
