"""
Comprehensive Test Suite for the 10 Official Government Portal Adapters,
Sandboxed JavaScript Script Generator, DOM Fixture Execution, and Read-Back Verification.
"""

import json
import pytest
from backend.app.schemas.application_schema import (
    PortalCompatibilityStatus,
    ReadBackFieldStatus,
)
from backend.app.services.application_service import ApplicationService
from backend.app.services.portal_adapter_service import PortalAdapterService


@pytest.fixture
def portal_service():
    return PortalAdapterService()


@pytest.fixture
def app_service():
    return ApplicationService()


ALL_10_SCHEMES = [
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


# ==============================================================================
# 1. Backend Configuration & Adapter Tests
# ==============================================================================


@pytest.mark.parametrize("scheme_id", ALL_10_SCHEMES)
def test_scheme_adapter_configuration_completeness(portal_service, scheme_id):
    """Verifies that all 10 schemes have full metadata, valid URLs, and configs."""
    entry = portal_service.get_entry_for_scheme(scheme_id)
    assert entry is not None, f"Scheme {scheme_id} missing in registry"
    assert entry.officialSchemeUrl.startswith("https://")
    assert entry.officialApplicationUrl.startswith("https://")
    assert len(entry.portalDomain) > 0
    assert len(entry.adapterId) > 0
    assert len(entry.supportedFields) >= 7
    assert len(entry.requiredDocuments) >= 2
    assert len(entry.manualInterventionRequirements) >= 1
    assert entry.portalCompatibilityStatus in [
        PortalCompatibilityStatus.FULLY_SUPPORTED,
        PortalCompatibilityStatus.PARTIALLY_SUPPORTED,
    ]


@pytest.mark.parametrize("scheme_id", ALL_10_SCHEMES)
def test_scheme_form_field_selectors_validity(portal_service, scheme_id):
    """Verifies that each scheme has form field configurations with non-empty selectors."""
    configs = portal_service.get_fields_config(scheme_id)
    assert len(configs) >= 7, f"Scheme {scheme_id} has fewer than 7 form configs"
    for field in configs:
        assert "field_id" in field
        assert "label" in field
        assert "selector" in field and len(field["selector"]) > 0
        assert "type" in field and field["type"] in ["text", "phone", "email", "dropdown", "number", "date", "checkbox", "radio"]
        assert "required" in field


# ==============================================================================
# 2. Declarative Population Script Generation & Protection Invariant Tests
# ==============================================================================


@pytest.mark.parametrize("scheme_id", ALL_10_SCHEMES)
def test_generate_population_script_excludes_sensitive_invariants(portal_service, scheme_id):
    """
    Verifies that the generated JS script never targets OTP, CAPTCHA, or password fields,
    even if an attacker attempts to inject malicious field values into the payload.
    """
    configs = portal_service.get_fields_config(scheme_id)
    sample_values = {c["field_id"]: f"test_val_{c['field_id']}" for c in configs}
    # Attempt prompt injection with sensitive field IDs
    sample_values["captcha_code"] = "1234"
    sample_values["otp_token"] = "999999"
    sample_values["user_password"] = "secret"

    script = portal_service.generate_population_script(scheme_id, sample_values)

    assert "function()" in script
    assert "SahayBridge" in script
    assert "dispatchEvent(new Event('input'" in script
    assert "dispatchEvent(new Event('change'" in script
    # Assert protection invariants
    assert "captcha_code" not in script
    assert "otp_token" not in script
    assert "user_password" not in script


# ==============================================================================
# 3. Local DOM Fixture Population & Read-Back Verification Tests
# ==============================================================================


@pytest.mark.parametrize("scheme_id", ALL_10_SCHEMES)
def test_scheme_dom_fixture_readback_exact_match(portal_service, scheme_id):
    """
    Simulates a live web portal DOM fixture where all fields were populated accurately.
    Verifies verify_readback produces FILLED_VERIFIED for all configured fields.
    """
    configs = portal_service.get_fields_config(scheme_id)
    expected_values = {c["field_id"]: f"valid_{c['field_id']}" for c in configs}
    # Simulate matching DOM values
    actual_dom_values = {c["field_id"]: f"valid_{c['field_id']}" for c in configs}

    report = portal_service.verify_readback(scheme_id, expected_values, actual_dom_values)

    assert report.total_fields == len(configs)
    assert report.verified_count == len(configs)
    assert report.unverified_count == 0
    assert report.failed_count == 0
    assert report.can_proceed_to_review is True
    for item in report.items:
        assert item.status == ReadBackFieldStatus.FILLED_VERIFIED


def test_readback_field_status_mismatch_and_missing(portal_service):
    """
    Tests detection of value mismatches, missing DOM elements, and optional fields.
    Verifies FILLED_UNVERIFIED and FAILED statuses are assigned appropriately.
    """
    scheme_id = "PM_KISAN_001"
    configs = portal_service.get_fields_config(scheme_id)

    expected = {c["field_id"]: "expected_123" for c in configs}
    # Simulate:
    # - aadhaar_number matches
    # - mobile_number has mismatch
    # - state is None (selector not found)
    # - other fields match
    actual = {c["field_id"]: "expected_123" for c in configs}
    actual["mobile_number"] = "wrong_number_999"
    actual["state"] = None

    report = portal_service.verify_readback(scheme_id, expected, actual)

    assert report.can_proceed_to_review is False
    assert report.unverified_count == 1
    assert report.failed_count == 1

    item_map = {i.field_id: i for i in report.items}
    assert item_map["aadhaar_number"].status == ReadBackFieldStatus.FILLED_VERIFIED
    assert item_map["mobile_number"].status == ReadBackFieldStatus.FILLED_UNVERIFIED
    assert "mismatch" in item_map["mobile_number"].message.lower()
    assert item_map["state"].status == ReadBackFieldStatus.FAILED
    assert "not found" in item_map["state"].message.lower()


# ==============================================================================
# 4. End-to-End Application Service Integration Tests
# ==============================================================================


@pytest.mark.parametrize("scheme_id", ALL_10_SCHEMES)
def test_full_portal_payload_and_readback_service_lifecycle(app_service, scheme_id):
    """
    Runs the complete cycle through ApplicationService:
    1. start_session
    2. get_portal_population_payload
    3. verify_portal_readback
    4. validate_session
    5. confirm_submission
    """
    user_id = f"test_citizen_{scheme_id.lower()}"
    profile = {
        "fullName": "Test Citizen",
        "gender": "Male",
        "dob": "1990-01-01",
        "mobileNumber": "9876543210",
        "state": "Madhya Pradesh",
        "district": "Bhopal",
        "annualIncome": 150000,
        "bankAccountNumber": "1234567890",
        "ifscCode": "SBIN0001234",
        "aadhaarNumber": "XXXXXXXX1234",
        "panNumber": "ABCDE1234F",
    }

    session = app_service.start_session(scheme_id, user_id, profile)
    assert session.session_id is not None
    assert session.scheme_id == scheme_id

    # 2. Get portal payload
    payload = app_service.get_portal_population_payload(session.session_id)
    assert payload.portal_domain is not None
    assert len(payload.declarative_instructions) == 1
    assert len(payload.read_back_selectors) >= 7

    # 3. Simulate DOM readback with mapped values
    dom_data = {f.field_id: f.mapped_value for sec in session.sections for f in sec.fields if f.mapped_value}
    readback_report = app_service.verify_portal_readback(session.session_id, dom_data)
    assert readback_report.total_fields >= 7

    # 4. Validate session
    val = app_service.validate_session(session.session_id)
    assert isinstance(val.is_valid, bool)

    # 5. Confirm submission requires explicit approval
    with pytest.raises(Exception):
        app_service.confirm_submission(session.session_id, user_explicit_approval=False)

    confirmed = app_service.confirm_submission(session.session_id, user_explicit_approval=True)
    assert confirmed.submission_confirmed is True
    assert confirmed.submission_reference.startswith("SAHAY-")
