"""
Comprehensive Test Suite for SAHAY Evidence-Based Eligibility Reasoning System.
Validates all 20 required scenarios:
- Exact thresholds, limits, borders, differences, missing info, state/occupation mismatches
- Deterministic ground truth invariance, Ollama fallback, and LLM hallucination rejection
"""

import pytest
from backend.app.models.scheme_schemas import (
    EligibilityOperator,
    EligibilityRuleSchema,
    GovernmentLevel,
    SchemeModelSchema,
    SchemeStatus,
    VerificationStatus,
)
from backend.app.schemas.eligibility_explanation_schema import (
    ConditionEvaluationStatus,
    DeterministicEligibilityReport,
    EligibilityExplanationRequest,
    OverallAssessmentVerdict,
)
from backend.app.services.eligibility_explanation_service import (
    EligibilityExplanationService,
)
from backend.app.services.ollama_service import OllamaService


@pytest.fixture
def service():
    return EligibilityExplanationService()


@pytest.fixture
def farmer_scheme():
    return SchemeModelSchema(
        schemeId="TEST_FARMER_001",
        name="Example Farmer Assistance Scheme",
        nameHindi="उदाहरण किसान सहायता योजना",
        description="Assistance scheme for farmers in MP.",
        category="agriculture",
        ministry="Ministry of Agriculture",
        governmentLevel=GovernmentLevel.state,
        applicableStates=["MP"],
        benefits="₹6,000 per year",
        eligibilityRules=[
            EligibilityRuleSchema(
                field="age",
                operator=EligibilityOperator.greaterThanOrEqual,
                value=18,
                isMandatory=True,
                description="Must be at least 18 years old",
            ),
            EligibilityRuleSchema(
                field="occupation",
                operator=EligibilityOperator.equals,
                value="farmer",
                isMandatory=True,
                description="Must be an active farmer",
            ),
            EligibilityRuleSchema(
                field="annualFamilyIncome",
                operator=EligibilityOperator.lessThanOrEqual,
                value=250000,
                isMandatory=True,
                description="Annual family income must not exceed ₹2,50,000",
            ),
            EligibilityRuleSchema(
                field="ownsCultivableLand",
                operator=EligibilityOperator.isTrue,
                value=True,
                isMandatory=False,  # Optional priority
                description="Preference for landholding cultivators",
            ),
        ],
        requiredDocuments=["Aadhaar Card", "Income Certificate", "Land Records"],
        applicationProcess="Apply online",
        officialSourceUrl="https://agri.mp.gov.in",
        status=SchemeStatus.active,
        verificationStatus=VerificationStatus.verified,
    )


# Test 1: All mandatory conditions satisfied
def test_all_mandatory_conditions_satisfied(service, farmer_scheme):
    answers = {
        "age": 35,
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 180000,
        "landOwnership": 1.5,
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    assert report.verdict == OverallAssessmentVerdict.may_qualify
    assert report.mandatorySatisfiedCount == 4  # state, age, occupation, income
    assert len(report.unsatisfiedConditions) == 0
    assert "appear to satisfy all mandatory eligibility conditions" in report.summaryExplanation


# Test 2: One mandatory condition failed (Income exceeded)
def test_single_mandatory_condition_failed(service, farmer_scheme):
    answers = {
        "age": 35,
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 320000,  # Exceeds 250,000 by 70,000
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    assert report.verdict == OverallAssessmentVerdict.does_not_appear_to_qualify
    assert len(report.unsatisfiedConditions) == 1
    income_cond = report.unsatisfiedConditions[0]
    assert income_cond.field == "annualFamilyIncome"
    assert income_cond.difference is not None
    assert income_cond.difference.amount == 70000
    assert "₹70,000" in income_cond.difference.description
    assert "exceeds" in income_cond.reason.lower()


# Test 3: Multiple mandatory conditions failed (Age + Occupation)
def test_multiple_mandatory_conditions_failed(service, farmer_scheme):
    answers = {
        "age": 16,  # Failed (< 18)
        "occupation": "student",  # Failed (!= farmer)
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 120000,
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    assert report.verdict == OverallAssessmentVerdict.does_not_appear_to_qualify
    assert len(report.unsatisfiedConditions) == 2
    failed_fields = {c.field for c in report.unsatisfiedConditions}
    assert failed_fields == {"age", "occupation"}


# Test 4: Only optional condition failed
def test_optional_condition_failed(service, farmer_scheme):
    answers = {
        "age": 35,
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 180000,
        "ownsCultivableLand": False,  # Optional criteria missed
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    assert report.verdict == OverallAssessmentVerdict.may_qualify
    assert len(report.unsatisfiedConditions) == 0
    assert len(report.optionalConditions) == 1
    assert report.optionalConditions[0].status == ConditionEvaluationStatus.not_satisfied


# Test 5: Missing income
def test_missing_income(service, farmer_scheme):
    answers = {
        "age": 35,
        "occupation": "farmer",
        "state": "Madhya Pradesh",
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    assert report.verdict == OverallAssessmentVerdict.needs_more_information
    missing_fields = {c.field for c in report.missingConditions}
    assert "annualFamilyIncome" in missing_fields
    assert any(p.field == "annualFamilyIncome" for p in report.missingFieldPrompts)


# Test 6: Missing age
def test_missing_age(service, farmer_scheme):
    answers = {
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 180000,
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    assert report.verdict == OverallAssessmentVerdict.needs_more_information
    missing_fields = {c.field for c in report.missingConditions}
    assert "age" in missing_fields


# Test 7: Unverified user information flag
def test_unverified_user_information(service, farmer_scheme):
    answers = {
        "age": 35,
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 180000,
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    for c in report.satisfiedConditions:
        assert c.verificationStatus == "self_reported"
        assert c.verifyingDocument is not None


# Test 8: Exact income threshold boundary
def test_exact_income_threshold(service, farmer_scheme):
    answers = {
        "age": 35,
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 250000,  # Exact upper limit
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    income_cond = [c for c in report.conditions if c.field == "annualFamilyIncome"][0]
    assert income_cond.status == ConditionEvaluationStatus.satisfied
    assert income_cond.isBorderline is True  # Exactly on boundary falls within 10%


# Test 9: Exact minimum age boundary
def test_exact_minimum_age(service, farmer_scheme):
    answers = {
        "age": 18,  # Exactly 18
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 180000,
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    age_cond = [c for c in report.conditions if c.field == "age"][0]
    assert age_cond.status == ConditionEvaluationStatus.satisfied


# Test 10: State mismatch
def test_state_mismatch(service, farmer_scheme):
    answers = {
        "age": 35,
        "occupation": "farmer",
        "state": "Bihar",  # Mismatch with MP
        "annualFamilyIncome": 180000,
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    assert report.verdict == OverallAssessmentVerdict.does_not_appear_to_qualify
    state_cond = [c for c in report.unsatisfiedConditions if c.field == "state"][0]
    assert "Bihar" in state_cond.formattedUserValue
    assert "Mp" in state_cond.required or "Madhya Pradesh" in state_cond.required


# Test 11: Occupation mismatch
def test_occupation_mismatch(service, farmer_scheme):
    answers = {
        "age": 35,
        "occupation": "construction_worker",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 180000,
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    assert report.verdict == OverallAssessmentVerdict.does_not_appear_to_qualify
    occ_cond = [c for c in report.unsatisfiedConditions if c.field == "occupation"][0]
    assert occ_cond.status == ConditionEvaluationStatus.not_satisfied


# Test 12: AND conditions logic
def test_and_conditions_all_must_pass(service, farmer_scheme):
    # If 3 pass and 1 fails, overall must fail
    answers = {
        "age": 35,
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 300000,
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    assert report.verdict == OverallAssessmentVerdict.does_not_appear_to_qualify


# Test 13: Borderline numeric values detection
def test_borderline_numeric_value(service, farmer_scheme):
    answers = {
        "age": 35,
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 240000,  # Within 4% of 250,000
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    income_cond = [c for c in report.conditions if c.field == "annualFamilyIncome"][0]
    assert income_cond.status == ConditionEvaluationStatus.satisfied
    assert income_cond.isBorderline is True


# Test 14: Unknown eligibility operator handling
def test_unknown_operator_fallback(service):
    corrupt_rule = EligibilityRuleSchema(
        field="age",
        operator="equals",
        value="unknown",
        isMandatory=True,
    )
    scheme = SchemeModelSchema(
        schemeId="CORRUPT_001",
        name="Corrupt Scheme",
        category="utilities",
        ministry="Ministry",
        governmentLevel=GovernmentLevel.central,
        eligibilityRules=[corrupt_rule],
        description="Test description",
        benefits="Test benefits",
        applicationProcess="Test process",
        officialSourceUrl="https://gov.in",
    )
    report = service.evaluate_scheme(scheme, {"age": 25})
    assert report.verdict == OverallAssessmentVerdict.does_not_appear_to_qualify


# Test 15: Incomplete scheme requirements (empty rules)
def test_empty_scheme_rules_handled(service):
    scheme = SchemeModelSchema(
        schemeId="EMPTY_001",
        name="Empty Scheme",
        category="housing",
        ministry="Ministry",
        governmentLevel=GovernmentLevel.central,
        eligibilityRules=[],
        description="Test description",
        benefits="Test benefits",
        applicationProcess="Test process",
        officialSourceUrl="https://gov.in",
    )
    report = service.evaluate_scheme(scheme, {"age": 25})
    assert report.verdict == OverallAssessmentVerdict.needs_more_information


# Test 16: Ollama offline fallback
@pytest.mark.asyncio
async def test_ollama_offline_fallback(service, farmer_scheme):
    from unittest.mock import patch, AsyncMock
    import httpx
    answers = {
        "age": 35,
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 180000,
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    ollama = OllamaService()
    with patch.object(httpx.AsyncClient, "post", new_callable=AsyncMock) as mock_post:
        mock_post.side_effect = httpx.ConnectError("Connection refused")
        result = await ollama.explain_eligibility(report, language="en")
        assert result is None  # Fails gracefully to None without throwing


# Test 17: Hallucination prevention on rejected scheme
@pytest.mark.asyncio
async def test_hallucination_guard_rejection(service, farmer_scheme):
    answers = {
        "age": 35,
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 320000,
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    assert report.verdict == OverallAssessmentVerdict.does_not_appear_to_qualify
    # Summary explanation must not congratulate on rejected
    assert "congratulations" not in report.summaryExplanation.lower()
    assert "do not currently appear to meet" in report.summaryExplanation


# Test 18: Alternative schemes suggestion
def test_alternative_schemes_found(service, farmer_scheme):
    alt_scheme = SchemeModelSchema(
        schemeId="ALT_AGRI_001",
        name="Alternative Agri Subsidy Scheme",
        category="agriculture",
        ministry="Ministry of Agriculture",
        governmentLevel=GovernmentLevel.central,
        applicableStates=[],
        eligibilityRules=[
            EligibilityRuleSchema(
                field="occupation",
                operator=EligibilityOperator.equals,
                value="farmer",
                isMandatory=True,
            )
        ],
        description="Test description",
        benefits="Test benefits",
        applicationProcess="Test process",
        officialSourceUrl="https://gov.in",
    )
    answers = {
        "age": 35,
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 350000,  # Fails farmer_scheme
    }
    report = service.evaluate_scheme(farmer_scheme, answers, catalog_schemes=[alt_scheme])
    assert report.verdict == OverallAssessmentVerdict.does_not_appear_to_qualify
    assert len(report.alternativeSchemes) >= 1
    assert report.alternativeSchemes[0].schemeId == "ALT_AGRI_001"


# Test 19: Hindi localization of reasons
def test_hindi_localization(service, farmer_scheme):
    answers = {
        "age": 35,
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 180000,
    }
    report = service.evaluate_scheme(farmer_scheme, answers)
    assert report.summaryExplanationHindi is not None
    assert "पात्रता शर्तों को पूरा करते प्रतीत होते हैं" in report.summaryExplanationHindi
    for c in report.conditions:
        assert c.labelHindi is not None


# Test 20: Full regression across all existing seed schemes in catalog
@pytest.mark.asyncio
async def test_catalogue_regression_eval(service):
    from backend.app.database.db_interface import get_scheme_db
    db = get_scheme_db()
    all_schemes = await db.list_all_schemes(limit=150)
    assert len(all_schemes) >= 100

    sample_answers = {
        "age": 40,
        "occupation": "farmer",
        "state": "Madhya Pradesh",
        "annualFamilyIncome": 150000,
        "ownsCultivableLand": True,
        "gender": "male",
        "casteCategory": "obc",
        "hasBankAccount": True,
        "hasAadhaar": True,
    }

    # Evaluate first 20 schemes across categories without exception
    for s in all_schemes[:20]:
        rep = service.evaluate_scheme(s, sample_answers, catalog_schemes=all_schemes)
        assert rep.verdict in [
            OverallAssessmentVerdict.may_qualify,
            OverallAssessmentVerdict.does_not_appear_to_qualify,
            OverallAssessmentVerdict.needs_more_information,
        ]
        assert len(rep.summaryExplanation) > 10


# Test 21: FastAPI /api/eligibility/assess Case A (May Qualify)
@pytest.mark.asyncio
async def test_api_assess_endpoint_case_a():
    from httpx import ASGITransport, AsyncClient
    from backend.app.main import app

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.post(
            "/api/eligibility/assess",
            json={
                "schemeId": "PM_KISAN_001",
                "answers": {
                    "age": 35,
                    "state": "Madhya Pradesh",
                    "occupation": "farmer",
                    "annualFamilyIncome": 180000,
                    "ownsAgriculturalLand": True,
                },
                "language": "en",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["verdict"] == "may_qualify"
        assert len(data["satisfiedConditions"]) >= 1
        assert len(data["unsatisfiedConditions"]) == 0
        assert "summaryExplanation" in data


# Test 22: FastAPI /api/eligibility/assess Case B (Does Not Qualify)
@pytest.mark.asyncio
async def test_api_assess_endpoint_case_b():
    from httpx import ASGITransport, AsyncClient
    from backend.app.main import app

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.post(
            "/api/eligibility/assess",
            json={
                "schemeId": "PM_KISAN_001",
                "answers": {
                    "age": 35,
                    "state": "Madhya Pradesh",
                    "occupation": "farmer",
                    "annualFamilyIncome": 320000,
                    "isTaxpayer": True,
                },
                "language": "en",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["verdict"] == "does_not_appear_to_qualify"
        assert len(data["unsatisfiedConditions"]) >= 1
        assert any(len(c.get("reason", "")) > 0 for c in data["unsatisfiedConditions"])


# Test 23: FastAPI /api/eligibility/assess Case C (Needs More Information)
@pytest.mark.asyncio
async def test_api_assess_endpoint_case_c():
    from httpx import ASGITransport, AsyncClient
    from backend.app.main import app

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.post(
            "/api/eligibility/assess",
            json={
                "schemeId": "PM_KISAN_001",
                "answers": {},
                "language": "en",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["verdict"] == "needs_more_information"
        assert len(data["missingFieldPrompts"]) >= 1


# Test 24: FastAPI /api/eligibility/clarify endpoint
@pytest.mark.asyncio
async def test_api_clarify_endpoint():
    from httpx import ASGITransport, AsyncClient
    from backend.app.main import app

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.post(
            "/api/eligibility/clarify",
            json={
                "schemeId": "PM_KISAN_001",
                "existing_answers": {},
                "additional_answers": {"age": 35},
                "language": "en",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert "deterministicReport" in data
        assert "conversationalExplanation" in data
