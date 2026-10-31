"""
Archetype End-to-End Simulation Tests for the 10 Verified Government Schemes.
Tests that each of the 10 applicant archetypes from data/smart_filler_test_profiles.json
runs through the full 7-stage Smart Application Filler lifecycle.
"""

import json
from pathlib import Path
import pytest

from backend.app.schemas.application_schema import (
    ApplicationStatus,
    ReadBackFieldStatus,
)
from backend.app.services.application_service import ApplicationService
from backend.app.services.portal_adapter_service import PortalAdapterService


def _load_archetypes():
    fixture_path = Path(__file__).resolve().parent.parent.parent / "data" / "smart_filler_test_profiles.json"
    data = json.loads(fixture_path.read_text(encoding="utf-8"))
    return data["archetypes"]


def test_10_archetypes_fixture_validity():
    """Verifies that all 10 archetypes exist in the test fixture."""
    archetypes = _load_archetypes()
    assert len(archetypes) == 10
    scheme_ids = [a["targetSchemeId"] for a in archetypes]
    assert len(set(scheme_ids)) == 10


@pytest.mark.parametrize("archetype", _load_archetypes(), ids=lambda a: a["id"])
def test_archetype_smart_filler_lifecycle(archetype):
    """
    Executes the end-to-end Smart Filler lifecycle for an applicant archetype:
    Stage 1: Preparation & Scheme Resolution
    Stage 2: Profile Normalization & Provenance Assignment
    Stage 3: Missing Fields Check & Answering
    Stage 4: Sandboxed Declarative Portal Script Generation
    Stage 5: Read-Back Verification
    Stage 6: Pre-Submission Validation Gate
    Stage 7: Mandatory Explicit Citizen Submission
    """
    scheme_id = archetype["targetSchemeId"]
    profile_data = archetype["profile"]
    user_id = f"user_{archetype['id']}"

    service = ApplicationService()

    # Stage 1: Verify registry entry
    entry = PortalAdapterService.get_entry_for_scheme(scheme_id)
    assert entry is not None
    assert entry.schemeId == scheme_id

    # Stage 2: Start session and review normalized data
    session = service.start_session(
        scheme_id=scheme_id,
        user_id=user_id,
        user_profile=profile_data,
    )
    assert session.session_id.startswith("app_sess_")
    assert session.scheme_id == scheme_id
    assert len(session.sections) > 0

    # Stage 3: Answer any scheme-specific missing fields
    missing_fields = [
        f for s in session.sections for f in s.fields
        if f.is_required and (f.mapped_value is None or str(f.mapped_value).strip() == "")
    ]
    if missing_fields:
        answers = {f.field_id: "Sample Answer" for f in missing_fields}
        session = service.answer_missing_fields(session.session_id, answers)
        assert session.missing_fields_count == 0

    # Stage 4: Generate sandboxed declarative population payload
    payload = service.get_portal_population_payload(session.session_id)
    assert payload.portal_id != ""
    assert len(payload.declarative_instructions) > 0
    # Safety invariant: population script must not contain password inputs
    script_str = json.dumps(payload.declarative_instructions)
    assert "password" not in script_str.lower()

    # Stage 5: Run Read-Back DOM Verification
    dom_values = {
        f.field_id: f.mappedValue if hasattr(f, 'mappedValue') else f.mapped_value
        for s in session.sections for f in s.fields
        if f.mapped_value is not None
    }
    report = service.verify_portal_readback(session.session_id, dom_values)
    assert report.total_fields > 0
    assert report.verified_count > 0

    # Stage 6: Deterministic Pre-Submission Validation
    val_res = service.validate_session(session.session_id)
    assert val_res.can_submit is True
    assert val_res.is_valid is True

    # Stage 7: Citizen Submission Gatekeeper
    # Security test: must fail if user_explicit_approval is False
    with pytest.raises(Exception):
        service.confirm_submission(session.session_id, user_explicit_approval=False)

    # Success when explicitly approved by citizen
    confirmed = service.confirm_submission(
        session.session_id,
        user_explicit_approval=True,
        acknowledgement_number=f"ACK-ARCHETYPE-{archetype['id'][:8].upper()}",
    )
    assert confirmed.status == ApplicationStatus.SUBMITTED_CONFIRMED
    assert confirmed.submission_confirmed is True
    assert confirmed.submission_reference.startswith("ACK-ARCHETYPE-")

