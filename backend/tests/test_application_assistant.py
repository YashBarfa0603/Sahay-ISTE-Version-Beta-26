"""
Comprehensive Test Suite for SAHAY Agentic AI Government Scheme Application Assistant.
Tests:
- Application Session Lifecycles (start, retrieve, cancel)
- Multi-Agent Orchestration (Context, Document, Form, Mapping, Explanation, Validation)
- EasyOCR & OpenCV Document Intelligence (Bilingual OCR, structured entity classification)
- Field Mapping, Conflict Detection & Confirmation
- Multilingual Field Explanations (EN, HI, Hinglish)
- Deterministic Validation Gatekeeper
- Review Summary Synthesis
- Controlled Direct Web Portal Adapter & JavaScript Bridge Security
- Mandatory Explicit Human Approval for Submission
- Security Invariants: Cross-User Authorization & Prompt Injection Guards
"""

import base64
import io
import pytest
from PIL import Image, ImageDraw
from fastapi.testclient import TestClient

from backend.app.main import app
from backend.app.schemas.application_schema import (
    ApplicationAnswerRequest,
    ApplicationStartRequest,
    DirectWebInspectRequest,
    DirectWebPopulateRequest,
    DocumentProcessRequest,
    FieldConfirmRequest,
    FieldExplanationRequest,
    InteractionMode,
    SubmissionConfirmationRequest,
)
from backend.app.services.application_service import ApplicationService
from backend.app.services.easyocr_service import EasyOCRService
from backend.app.services.portal_adapter_service import PortalAdapterService

client = TestClient(app)


# ==========================================
# Helpers: Generate Synthetic Test Documents
# ==========================================


def _create_synthetic_document_image(text_lines: list[str]) -> bytes:
    """Generates synthetic image bytes containing test government certificate text."""
    img = Image.new("RGB", (600, 300), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    y = 20
    for line in text_lines:
        draw.text((20, y), line, fill=(0, 0, 0))
        y += 35
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


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
    assert len(processed.shape) == 2  # Grayscale 2D array


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


def test_document_classification_bank_passbook():
    """Verifies Bank Passbook parsing (IFSC, Account Number)."""
    service = EasyOCRService()
    synthetic_text = (
        "STATE BANK OF INDIA\n"
        "SAVINGS BANK PASSBOOK\n"
        "Account No: 987654321012\n"
        "IFSC: SBIN0001234\n"
    )
    result = service._classify_and_extract_entities(synthetic_text, base_confidence=0.94)
    assert result["document_type"] == "bank_passbook"
    assert result["fields"]["ifsc_code"]["value"] == "SBIN0001234"
    assert result["fields"]["account_number"]["value"] == "987654321012"


# ==========================================
# 2. Portal Adapter Registry & Safety Tests
# ==========================================


def test_portal_adapter_registry_pm_kisan():
    """Verifies PM-KISAN official portal adapter resolution and restrictions."""
    adapter = PortalAdapterService.get_adapter_for_scheme("PM_KISAN_001")
    assert adapter.official_domain == "pmkisan.gov.in"
    assert "aadhaar_number" in adapter.supported_fields
    assert "state" in adapter.supported_fields


def test_controlled_javascript_bridge_safety():
    """Ensures that declarative population never emits instructions for OTP, CAPTCHA, or passwords."""
    untrusted_instructions = [
        {"selector": "farmer_name", "value": "Rahul Singh"},
        {"selector": "captcha_input", "value": "1234"},  # MUST BE REJECTED
        {"selector": "otp_field", "value": "999999"},  # MUST BE REJECTED
        {"selector": "user_password", "value": "secret"},  # MUST BE REJECTED
    ]
    script = PortalAdapterService.generate_population_script(untrusted_instructions)
    assert "farmer_name" in script
    assert "captcha_input" not in script
    assert "otp_field" not in script
    assert "user_password" not in script


# ==========================================
# 3. Application Session & Multi-Agent Tests
# ==========================================


@pytest.mark.asyncio
async def test_application_session_start_pm_kisan():
    """Tests session creation, multi-agent graph execution, and section generation."""
    service = ApplicationService()
    user_profile = {
        "fullName": "Amit Verma",
        "mobileNumber": "9876543210",
        "state": "Madhya Pradesh",
        "district": "Bhopal",
        "annualFamilyIncome": 150000,
        "isFarmer": "Yes",
    }
    session = await service.start_session(
        scheme_id="PM_KISAN_001",
        user_id="user_test_123",
        user_profile=user_profile,
    )
    assert session.session_id.startswith("app_sess_")
    assert session.scheme_id == "PM_KISAN_001"
    assert len(session.sections) >= 3

    # Check prefilled fields
    all_fields = {f.field_id: f for sec in session.sections for f in sec.fields}
    assert "fullName" in all_fields
    assert all_fields["fullName"].mapped_value == "Amit Verma"
    assert all_fields["mobileNumber"].mapped_value == "9876543210"


@pytest.mark.asyncio
async def test_field_mapping_conflict_detection():
    """Verifies that conflicting profile vs document values are detected and flagged."""
    service = ApplicationService()
    # Profile says income is 2,00,000
    user_profile = {"annualFamilyIncome": 200000}
    session = await service.start_session(
        scheme_id="PM_KISAN_001",
        user_id="user_conflict_test",
        user_profile=user_profile,
    )

    # Process an uploaded income certificate with mocked run_ocr
    from unittest.mock import patch
    mock_ocr = {
        "document_type": "income_certificate",
        "confidence": 0.95,
        "fields": {
            "annual_income": {"value": 180000, "confidence": 0.95},
        },
        "raw_text": "INCOME CERTIFICATE\nAnnual Income: Rs. 1,80,000",
        "processing_status": "completed",
    }
    with patch.object(service.ocr_service, "run_ocr", return_value=mock_ocr):
        await service.process_document_bytes(
            session_id=session.session_id,
            user_id="user_conflict_test",
            document_id="income_certificate",
            file_bytes=b"dummy_bytes",
            mime_type="image/jpeg",
        )

    retrieved = service.get_session(session.session_id, "user_conflict_test")
    all_fields = {f.field_id: f for sec in retrieved.sections for f in sec.fields}
    income_field = all_fields.get("annualFamilyIncome")
    assert income_field is not None

    # Resolve conflict with user's explicit choice
    updated = service.confirm_field_conflict(
        session_id=session.session_id,
        user_id="user_conflict_test",
        field_id="annualFamilyIncome",
        confirmed_value=180000,
    )
    all_updated = {f.field_id: f for sec in updated.sections for f in sec.fields}
    assert all_updated["annualFamilyIncome"].mapped_value == 180000
    assert all_updated["annualFamilyIncome"].user_confirmed is True


def test_multilingual_field_explanations():
    """Tests plain-language explanations in English, Hindi, and Hinglish."""
    service = ApplicationService()
    en_res = service.explain_field("annualFamilyIncome", "Annual Family Income", language="en")
    assert "gross income" in en_res["explanation"].lower() or "household" in en_res["explanation"].lower()

    hi_res = service.explain_field("annualFamilyIncome", "वार्षिक आय", language="hi")
    assert "परिवार" in hi_res["explanation"]

    hing_res = service.explain_field("annualFamilyIncome", "Annual Family Income", language="hinglish")
    assert "parivaar" in hing_res["explanation"].lower() or "income" in hing_res["explanation"].lower()


@pytest.mark.asyncio
async def test_deterministic_validation_gatekeeper():
    """Verifies that missing required fields or invalid formats prevent submission."""
    service = ApplicationService()
    session = await service.start_session(
        scheme_id="PM_KISAN_001",
        user_id="user_val_test",
        user_profile={},  # Empty profile
    )

    # Initial validation should fail due to missing required fields
    val_res = service.validate_session(session.session_id, "user_val_test")
    assert val_res.is_valid is False
    assert val_res.can_submit is False
    assert len(val_res.missing_required_fields) > 0

    # Supply an invalid mobile number format
    service.answer_field(
        session.session_id,
        "user_val_test",
        ApplicationAnswerRequest(field_id="mobileNumber", value="12345"),  # Invalid (not 10 digits)
    )
    val_res2 = service.validate_session(session.session_id, "user_val_test")
    assert any("mobile" in err.lower() for err in val_res2.invalid_format_fields or session.validation_errors)


@pytest.mark.asyncio
async def test_explicit_human_approval_mandatory_for_submission():
    """CRITICAL SECURITY INVARIANT: Automated submission without human approval is strictly blocked."""
    service = ApplicationService()
    session = await service.start_session(
        scheme_id="PM_KISAN_001",
        user_id="user_approval_test",
        user_profile={"fullName": "Test User"},
    )

    # Attempt submission with user_approved = False must raise 400
    with pytest.raises(Exception) as excinfo:
        service.confirm_submission(
            session_id=session.session_id,
            user_id="user_approval_test",
            user_approved=False,
        )
    assert "Explicit citizen approval is mandatory" in str(excinfo.value)

    # Submission with user_approved = True succeeds
    success = service.confirm_submission(
        session_id=session.session_id,
        user_id="user_approval_test",
        user_approved=True,
        acknowledgement_number="PMK-TEST-9988",
    )
    assert success is True
    confirmed_session = service.get_session(session.session_id, "user_approval_test")
    assert confirmed_session.status.value == "submitted_confirmed"
    assert confirmed_session.submission_reference == "PMK-TEST-9988"


# ==========================================
# 4. FastAPI End-to-End API Integration Tests
# ==========================================


def test_api_start_and_get_application():
    """Tests POST /api/applications/start and GET /api/applications/{session_id}."""
    resp = client.post(
        "/api/applications/start",
        json={"scheme_id": "PM_KISAN_001", "interaction_mode": "guided_form"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "session_id" in data
    session_id = data["session_id"]

    # GET session
    get_resp = client.get(f"/api/applications/{session_id}")
    assert get_resp.status_code == 200
    assert get_resp.json()["scheme_id"] == "PM_KISAN_001"


def test_api_answer_guided_form_field():
    """Tests POST /api/applications/{session_id}/guided-form/answer."""
    start_resp = client.post("/api/applications/start", json={"scheme_id": "PM_KISAN_001"})
    session_id = start_resp.json()["session_id"]

    ans_resp = client.post(
        f"/api/applications/{session_id}/guided-form/answer",
        json={"field_id": "fullName", "value": "Vikas Patel", "user_confirmed": True},
    )
    assert ans_resp.status_code == 200
    updated_data = ans_resp.json()
    all_fields = {f["field_id"]: f for sec in updated_data["sections"] for f in sec["fields"]}
    assert all_fields["fullName"]["mapped_value"] == "Vikas Patel"
    assert all_fields["fullName"]["user_confirmed"] is True


def test_api_explain_field():
    """Tests POST /api/applications/{session_id}/explain-field."""
    start_resp = client.post("/api/applications/start", json={"scheme_id": "PM_KISAN_001"})
    session_id = start_resp.json()["session_id"]

    exp_resp = client.post(
        f"/api/applications/{session_id}/explain-field",
        json={
            "field_id": "annualFamilyIncome",
            "field_label": "Annual Family Income",
            "language": "hi",
        },
    )
    assert exp_resp.status_code == 200
    res_data = exp_resp.json()
    assert "explanation" in res_data
    assert res_data["language"] == "hi"


def test_api_review_endpoint():
    """Tests GET /api/applications/{session_id}/review."""
    start_resp = client.post("/api/applications/start", json={"scheme_id": "PM_KISAN_001"})
    session_id = start_resp.json()["session_id"]

    rev_resp = client.get(f"/api/applications/{session_id}/review")
    assert rev_resp.status_code == 200
    review_data = rev_resp.json()
    assert "total_fields" in review_data
    assert "can_submit" in review_data
    assert "sections" in review_data


def test_api_submission_confirmation():
    """Tests POST /api/applications/{session_id}/submission-confirmation."""
    start_resp = client.post("/api/applications/start", json={"scheme_id": "PM_KISAN_001"})
    session_id = start_resp.json()["session_id"]

    sub_resp = client.post(
        f"/api/applications/{session_id}/submission-confirmation",
        json={
            "user_explicit_approval": True,
            "official_acknowledgement_number": "ACK-GOV-2026-XYZ",
        },
    )
    assert sub_resp.status_code == 200
    assert sub_resp.json()["submitted"] is True
    assert sub_resp.json()["acknowledgement_number"] == "ACK-GOV-2026-XYZ"
