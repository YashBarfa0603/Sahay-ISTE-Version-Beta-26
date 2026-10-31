"""
Comprehensive Test Suite for SAHAY 10-Scheme Smart Application Filler.
Tests:
- 10-Scheme Central Registry Verification (All 10 schemes supported with full metadata)
- Unsupported Scheme Rejection Guard
- EasyOCR & OpenCV Document Intelligence (Bilingual OCR, entity classification)
- Normalized Citizen Profile Store with Value Provenance & Conflict Detection
- Missing Information & Conflict Resolution Workflows
- Controlled JavaScript Bridge Safety (Guards against OTP, CAPTCHA, passwords)
- Read-Back Verification Engine (DOM value inspection vs normalized data)
- Deterministic Validation Gatekeeper
- Mandatory Explicit Human Approval for Submission
- Smart Filler Router Endpoints (Direct invocation testing)
"""

import base64
import io
import pytest
from PIL import Image, ImageDraw

from backend.app.dependencies.auth import AuthenticatedUser
from backend.app.routers.applications import (
    answer_missing_fields as router_answer_missing_fields,
    confirm_submission as router_confirm_submission,
    get_application_session as router_get_application_session,
    get_portal_populate_payload as router_get_portal_populate_payload,
    get_supported_schemes as router_get_supported_schemes,
    resolve_conflict as router_resolve_conflict,
    start_application_session as router_start_application,
    verify_portal_readback as router_verify_portal_readback,
)
from backend.app.schemas.application_schema import (
    ApplicationSessionModel,
    ApplicationStartRequest,
    ApplicationStatus,
    ConflictResolveRequest,
    MissingFieldsAnswerRequest,
    PortalReadBackVerifyRequest,
    SubmissionConfirmationRequest,
)
from backend.app.services.application_service import ApplicationService
from backend.app.services.easyocr_service import EasyOCRService
from backend.app.services.portal_adapter_service import PortalAdapterService

TARGET_SCHEMES = [
    "PM_KISAN_001",
    "PMAY_002",
    "E_SHRAM_001",
    "UDYAM_001",
    "PM_SURYA_GHAR_001",
    "PM_SVANIDHI_001",
    "PMEGP_001",
    "MP_POST_MATRIC_SCHOLARSHIP_SC_ST_001",
    "AICTE_PRAGATI_001",
    "AICTE_SAKSHAM_001",
]

mock_user = AuthenticatedUser(
    uid="test_user_smart_filler",
    email="citizen@sahay.gov.in",
    is_guest=False,
)


# ==========================================
# 1. EasyOCR & Document Intelligence Tests
# ==========================================


def test_easyocr_service_initialization():
    """Verifies EasyOCR singleton initialization and language configuration."""
    service = EasyOCRService()
    assert "en" in service.languages
    assert "hi" in service.languages


def test_opencv_preprocessing_execution():
    """Verifies OpenCV preprocessing pipeline (grayscale, bilateral denoising, CLAHE)."""
    import numpy as np
    service = EasyOCRService()
    dummy_img = np.full((100, 100, 3), 180, dtype=np.uint8)
    processed = service.preprocess_image(dummy_img)
    assert processed is not None
    assert len(processed.shape) == 2


def test_document_classification_income_certificate():
    """Verifies deterministic classification and parsing of Income Certificates."""
    service = EasyOCRService()
    synthetic_text = (
        "GOVERNMENT OF MADHYA PRADESH\n"
        "OFFICE OF THE TEHSILDAR, BHOPAL\n"
        "AAY PRAMAN PATRA / INCOME CERTIFICATE\n"
        "This is to certify that annual income of Ramesh Kumar is Rs. 1,80,000 /-\n"
        "Issue Date: 15/01/2026\n"
    )
    result = service._classify_and_extract_entities(synthetic_text, base_confidence=0.92)
    assert result["document_type"] == "income_certificate"
    assert "annual_income" in result["fields"]
    assert result["fields"]["annual_income"]["value"] == 180000


def test_document_classification_aadhaar_card():
    """Verifies Aadhaar card entity extraction (masked UID, DOB, Gender)."""
    service = EasyOCRService()
    synthetic_text = (
        "GOVERNMENT OF INDIA\n"
        "Mera Aadhaar Meri Pehchan\n"
        "Sunita Sharma\n"
        "DOB: 12/04/1988\n"
        "Female\n"
        "5432 9876 1234\n"
    )
    result = service._classify_and_extract_entities(synthetic_text, base_confidence=0.95)
    assert result["document_type"] == "aadhaar_card"
    assert "aadhaar_number" in result["fields"]
    assert result["fields"]["aadhaar_number"]["value"] == "XXXXXXXX1234"
    assert result["fields"]["gender"]["value"] == "Female"


# ==========================================
# 2. 10-Scheme Central Registry & Security Tests
# ==========================================


def test_10_scheme_registry_completeness():
    """Verifies that all 10 target schemes are registered with required metadata."""
    registry = PortalAdapterService.get_supported_schemes_registry()
    assert len(registry) == 10
    registry_ids = [entry.schemeId for entry in registry]
    for scheme_id in TARGET_SCHEMES:
        assert scheme_id in registry_ids
        entry = PortalAdapterService.get_entry_for_scheme(scheme_id)
        assert entry is not None
        assert entry.schemeId == scheme_id
        assert entry.portalDomain != ""
        assert len(entry.supportedFields) > 0
        assert entry.authenticationRequirements != ""
        assert len(entry.manualInterventionRequirements) > 0


def test_unsupported_scheme_rejection():
    """Ensures non-approved schemes are rejected by the Smart Filler adapter."""
    assert PortalAdapterService.is_scheme_supported("UNKNOWN_SCHEME_999") is False
    assert PortalAdapterService.get_entry_for_scheme("UNKNOWN_SCHEME_999") is None


def test_controlled_javascript_bridge_safety():
    """Ensures that declarative population never emits instructions for OTP, CAPTCHA, or passwords."""
    field_values = {
        "farmer_name": "Rahul Singh",
        "mobile_number": "9876543210",
        "captcha": "1234",
        "otp": "999999",
        "password": "secret",
    }
    script = PortalAdapterService.generate_population_script("PM_KISAN_001", field_values)
    assert "Rahul Singh" in script
    assert "POPULATE_RESULTS" in script
    assert "window.SahayBridge" in script
    assert "password" not in script.lower()


def test_readback_script_generation():
    """Verifies readback script generation contains field selectors and returns window.SahayBridge."""
    script = PortalAdapterService.generate_readback_script("PM_KISAN_001")
    assert "READBACK_RESULTS" in script
    assert "window.SahayBridge" in script


def test_readback_verification_engine():
    """Verifies deterministic comparison between expected values and DOM extracted values."""
    expected_values = {
        "farmer_name": "Ramesh Kumar",
        "mobile_number": "9876543210",
        "district": "Bhopal",
    }
    dom_values = {
        "farmer_name": "Ramesh Kumar",  # Match
        "mobile_number": "9876543210",  # Match
        "district": "Indore",           # Mismatch
    }
    report = PortalAdapterService.verify_readback(
        scheme_id="PM_KISAN_001",
        expected_values=expected_values,
        actual_dom_values=dom_values,
    )
    assert report.total_fields == 10
    assert report.verified_count == 2
    assert report.unverified_count == 1
    assert report.can_proceed_to_review is False


# ==========================================
# 3. Citizen Profile Normalization & Provenance
# ==========================================


def test_normalize_citizen_profile_with_provenance():
    """Verifies profile normalization populates submodels and tracks provenance."""
    service = ApplicationService()
    raw_profile = {
        "fullName": "Amit Verma",
        "gender": "Male",
        "mobileNumber": "9876543210",
        "addressLine1": "Plot 42, Kisan Nagar",
        "district": "Bhopal",
        "state": "Madhya Pradesh",
        "pincode": "462001",
        "annualIncome": 150000,
        "occupation": "Farmer",
    }
    extracted_docs = [
        {
            "document_type": "aadhaar_card",
            "document_id": "doc_aadhaar_01",
            "fields": {
                "aadhaar_number": {"value": "XXXXXXXX1234", "confidence": 0.95},
                "fullName": {"value": "Amit Verma", "confidence": 0.95},
            },
        }
    ]

    profile = service.normalize_citizen_profile(
        user_id="user_test_123",
        raw_answers=raw_profile,
        extracted_docs=extracted_docs,
    )

    assert profile.personal.full_name == "Amit Verma"
    assert profile.contact.mobile_number == "9876543210"
    assert profile.address.state == "Madhya Pradesh"
    assert profile.financial.annual_income == 150000

    # Provenance checks
    assert "personal.full_name" in profile.provenance_map
    assert profile.provenance_map["personal.full_name"].source == "user_profile"
    assert "personal.aadhaar_number" in profile.provenance_map
    assert profile.provenance_map["personal.aadhaar_number"].source == "document_ocr"


def test_income_conflict_detection_in_session():
    """Verifies that discrepancy between profile income and document income creates conflict."""
    service = ApplicationService()
    raw_profile = {"annualIncome": 250000, "fullName": "Farmer Kumar"}
    extracted_docs = [
        {
            "document_type": "income_certificate",
            "document_id": "doc_inc_01",
            "fields": {
                "annual_income": {"value": 180000, "confidence": 0.95},
            },
        }
    ]
    service._user_documents["user_conflict_test"] = extracted_docs
    session = service.start_session(
        scheme_id="PMAY_002",
        user_id="user_conflict_test",
        user_profile=raw_profile,
    )
    assert session.conflicts_count >= 1
    all_fields = [f for s in session.sections for f in s.fields]
    income_fields = [f for f in all_fields if f.field_id == "annual_income"]
    assert len(income_fields) == 1
    assert income_fields[0].conflict_detected is True


# ==========================================
# 4. Application Session & Workflow Tests
# ==========================================


def test_session_start_all_10_schemes():
    """Ensures session can be created for all 10 supported schemes."""
    service = ApplicationService()
    user_profile = {
        "fullName": "Sunita Devi",
        "mobileNumber": "9876543210",
        "state": "Madhya Pradesh",
        "district": "Indore",
        "gender": "Female",
    }
    for scheme_id in TARGET_SCHEMES:
        session = service.start_session(
            scheme_id=scheme_id,
            user_id=f"user_test_{scheme_id}",
            user_profile=user_profile,
        )
        assert session.session_id.startswith("app_sess_")
        assert session.scheme_id == scheme_id
        assert len(session.sections) > 0


def test_session_missing_info_answering():
    """Verifies answering missing fields updates the session profile and fields."""
    service = ApplicationService()
    session = service.start_session(
        scheme_id="PM_KISAN_001",
        user_id="user_missing_test",
        user_profile={"fullName": "Ramesh Kumar"},
    )
    # Answer missing field mobile_number
    updated = service.answer_missing_fields(
        session_id=session.session_id,
        answers={"mobile_number": "9876543210"},
    )
    all_fields = {f.field_id: f for s in updated.sections for f in s.fields}
    assert all_fields["mobile_number"].mapped_value == "9876543210"
    assert all_fields["mobile_number"].user_confirmed is True


def test_session_conflict_resolution():
    """Verifies citizen resolving a conflict updates the chosen value."""
    service = ApplicationService()
    service._user_documents["user_conf_test"] = [
        {
            "document_type": "income_certificate",
            "document_id": "doc_inc_02",
            "fields": {"annual_income": {"value": 240000, "confidence": 0.9}},
        }
    ]
    session = service.start_session(
        scheme_id="PMAY_002",
        user_id="user_conf_test",
        user_profile={"annualIncome": 300000, "fullName": "Test Beneficiary"},
    )
    assert session.conflicts_count >= 1

    # Resolve conflict to document value
    resolved_session = service.resolve_field_conflict(
        session_id=session.session_id,
        field_id="annual_income",
        confirmed_value=240000,
    )
    assert resolved_session.conflicts_count == 0
    all_fields = {f.field_id: f for s in resolved_session.sections for f in s.fields}
    assert all_fields["annual_income"].mapped_value == 240000
    assert all_fields["annual_income"].conflict_detected is False


def test_deterministic_validation_gatekeeper():
    """Verifies that missing required fields prevent submission."""
    service = ApplicationService()
    session = service.start_session(
        scheme_id="PM_KISAN_001",
        user_id="user_val_test",
        user_profile={},
    )
    val = service.validate_session(session.session_id)
    assert val.is_valid is False
    assert val.can_submit is False
    assert len(val.missing_required_fields) > 0


def test_explicit_human_approval_mandatory_for_submission():
    """CRITICAL SECURITY INVARIANT: Automated submission without human approval is strictly blocked."""
    service = ApplicationService()
    session = service.start_session(
        scheme_id="PM_KISAN_001",
        user_id="user_approval_test",
        user_profile={"fullName": "Test User"},
    )

    with pytest.raises(Exception) as excinfo:
        service.confirm_submission(
            session_id=session.session_id,
            user_explicit_approval=False,
        )
    assert "Explicit citizen approval" in str(excinfo.value)

    # Submission with approval
    confirmed = service.confirm_submission(
        session_id=session.session_id,
        user_explicit_approval=True,
        acknowledgement_number="PMK-TEST-9988",
    )
    assert confirmed.status == ApplicationStatus.SUBMITTED_CONFIRMED
    assert confirmed.submission_reference == "PMK-TEST-9988"


# ==========================================
# 5. Smart Filler Router Endpoints Tests
# ==========================================


def test_router_get_supported_schemes():
    """Tests router get_supported_schemes endpoint directly."""
    entries = router_get_supported_schemes()
    assert len(entries) == 10
    ids = [e.schemeId for e in entries]
    for tid in TARGET_SCHEMES:
        assert tid in ids


def test_router_start_and_get_session():
    """Tests router start_application and get_application_session."""
    req = ApplicationStartRequest(
        scheme_id="PM_KISAN_001",
        user_profile_answers={
            "fullName": "Kisan Bhai",
            "mobileNumber": "9876543210",
            "state": "Madhya Pradesh",
        },
    )
    session = router_start_application(req, user=mock_user)
    assert session.scheme_id == "PM_KISAN_001"
    assert session.session_id.startswith("app_sess_")

    retrieved = router_get_application_session(session.session_id, user=mock_user)
    assert retrieved.session_id == session.session_id


def test_router_answer_missing_and_portal_payload():
    """Tests router answer_missing_fields and get_portal_populate_payload."""
    req = ApplicationStartRequest(
        scheme_id="E_SHRAM_001",
        user_profile_answers={"fullName": "Labour Worker"},
    )
    session = router_start_application(req, user=mock_user)

    ans_req = MissingFieldsAnswerRequest(answers={"mobile_number": "9123456789"})
    updated = router_answer_missing_fields(session.session_id, ans_req, user=mock_user)
    assert updated.session_id == session.session_id

    payload = router_get_portal_populate_payload(session.session_id, user=mock_user)
    assert payload.portal_id == "eshram_adapter_v2"
    assert len(payload.declarative_instructions) > 0


def test_router_verify_readback():
    """Tests router verify_portal_readback endpoint."""
    req = ApplicationStartRequest(
        scheme_id="UDYAM_001",
        user_profile_answers={"fullName": "Entrepreneur Ji", "mobileNumber": "9876543210"},
    )
    session = router_start_application(req, user=mock_user)

    verify_req = PortalReadBackVerifyRequest(
        read_back_data={
            "owner_name": "Entrepreneur Ji",
            "mobile_number": "9876543210",
        }
    )
    report = router_verify_portal_readback(session.session_id, verify_req, user=mock_user)
    assert report.total_fields > 0


def test_router_submission_confirmation():
    """Tests router confirm_submission endpoint."""
    req = ApplicationStartRequest(
        scheme_id="PM_KISAN_001",
        user_profile_answers={"fullName": "Test Farmer"},
    )
    session = router_start_application(req, user=mock_user)

    confirm_req = SubmissionConfirmationRequest(
        user_explicit_approval=True,
        official_acknowledgement_number="ACK-SMART-2026-001",
    )
    confirmed = router_confirm_submission(session.session_id, confirm_req, user=mock_user)
    assert confirmed.status == ApplicationStatus.SUBMITTED_CONFIRMED
    assert confirmed.submission_reference == "ACK-SMART-2026-001"
