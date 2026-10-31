"""
Comprehensive Full System Test Suite for SAHAY Backend Services:
Multi-Agent Orchestrator, Unknown Income Estimator, Rule Versioning, Conflict Resolution, and CSC Locator.
"""

import pytest
from httpx import ASGITransport, AsyncClient
from backend.app.database.db_interface import InMemorySchemeDatabase
from backend.app.main import app
from backend.app.models.scheme_schemas import (
    EligibilityOperator,
    EligibilityRuleSchema,
    GovernmentLevel,
    SchemeModelSchema,
    VerificationStatus,
)
from backend.app.services.assistance_service import AssistanceService
from backend.app.services.eligibility_service import EligibilityEvaluationService, EvaluationVerdict
from backend.app.services.income_estimator_service import IncomeEstimationInput, IncomeEstimatorService
from backend.app.services.versioning_service import CandidateRuleProposal, SchemeVersioningService


@pytest.fixture
def db():
    return InMemorySchemeDatabase()


@pytest.fixture
def eligibility_service():
    return EligibilityEvaluationService()


@pytest.fixture
def income_service():
    return IncomeEstimatorService()


@pytest.fixture
def assistance_service():
    return AssistanceService()


@pytest.fixture
def versioning_service():
    return SchemeVersioningService()


# 1. Deterministic Eligibility Evaluation Tests
@pytest.mark.asyncio
async def test_deterministic_eligibility_pm_kisan(db, eligibility_service):
    scheme = await db.get_scheme("pm-kisan-001")
    assert scheme is not None

    # Qualified farmer (even with > 2ha land, verifying 2-hectare cap abolition per June 2019 Cabinet decision)
    rep_qualified = eligibility_service.evaluate_scheme(
        scheme,
        {
            "occupation": "farmer",
            "landOwnership": 3.5,
            "ownsCultivableLand": True,
            "isInstitutionalLandholder": False,
            "isGovernmentEmployee": False,
            "isIncomeTaxPayer": False,
            "hasBankAccount": True,
        },
    )
    assert rep_qualified.verdict == EvaluationVerdict.mayQualify

    # Disqualified farmer (income tax payer exclusion per official operational guidelines)
    rep_disqualified = eligibility_service.evaluate_scheme(
        scheme,
        {
            "occupation": "farmer",
            "ownsCultivableLand": True,
            "isInstitutionalLandholder": False,
            "isGovernmentEmployee": False,
            "isIncomeTaxPayer": True,
            "hasBankAccount": True,
        },
    )
    assert rep_disqualified.verdict == EvaluationVerdict.doesNotQualify

    # Disqualified farmer (institutional landholder)
    rep_inst = eligibility_service.evaluate_scheme(
        scheme,
        {
            "occupation": "farmer",
            "ownsCultivableLand": True,
            "isInstitutionalLandholder": True,
            "isGovernmentEmployee": False,
            "isIncomeTaxPayer": False,
            "hasBankAccount": True,
        },
    )
    assert rep_inst.verdict == EvaluationVerdict.doesNotQualify

    # Missing information (missing exclusion details and land ownership)
    rep_missing = eligibility_service.evaluate_scheme(scheme, {"occupation": "farmer"})
    assert rep_missing.verdict == EvaluationVerdict.needsMoreInformation
    assert "ownsCultivableLand" in rep_missing.missingFields or "isIncomeTaxPayer" in rep_missing.missingFields


@pytest.mark.asyncio
async def test_borderline_condition_evaluation(db, eligibility_service):
    # Test borderline condition on Ladli Behna (age upper limit is 60; 59 is within 10%)
    lb_scheme = await db.get_scheme("ladli-behna-006")
    assert lb_scheme is not None

    rep_borderline = eligibility_service.evaluate_scheme(
        lb_scheme,
        {
            "gender": "female",
            "age": 59,
            "state": "Madhya Pradesh",
            "maritalStatus": "married",
            "annualIncome": 150000.0,
            "isIncomeTaxPayer": False,
            "hasFourWheeler": False,
            "isGovernmentEmployee": False,
            "hasBankAccount": True,
        },
    )
    assert rep_borderline.verdict == EvaluationVerdict.mayQualify
    assert len(rep_borderline.borderlineWarnings) >= 1


# 2. Unknown Household Income Estimation Tests
def test_income_estimator_bounds_and_thresholds(income_service):
    # Citizen with informal daily wage earning approx ₹8,000 monthly, 1 earner
    input_data = IncomeEstimationInput(
        primary_source="daily_wage",
        monthly_estimated_income=8000.0,
        household_earners=1,
        has_agricultural_income=False,
    )
    thresholds = {
        "scheme_low_income": 50000.0,  # Below income range
        "scheme_high_threshold": 250000.0,  # Above income range
        "scheme_crossing": 95000.0,  # Crosses range
    }

    res = income_service.estimate_income(input_data, thresholds)
    assert res.min_annual_income < res.median_estimate < res.max_annual_income
    assert res.requires_official_verification is True
    assert len(res.assumptions) >= 2

    eval_map = {e.schemeId: e.status for e in res.threshold_evaluations}
    assert eval_map["scheme_high_threshold"] == "satisfies_condition"
    assert eval_map["scheme_low_income"] == "fails_condition"
    assert eval_map["scheme_crossing"] == "crosses_threshold"


# 3. Rule Versioning, Provenance & Rollback Tests
def test_scheme_rule_versioning_and_rollback(versioning_service):
    scheme = SchemeModelSchema(
        schemeId="test-scheme-001",
        name="Test Welfare Scheme",
        description="Description",
        category="health",
        ministry="Ministry of Health",
        governmentLevel=GovernmentLevel.central,
        benefits="Health coverage",
        eligibilityRules=[
            EligibilityRuleSchema(
                field="age",
                operator=EligibilityOperator.greaterThanOrEqual,
                value=60,
                isMandatory=True,
            )
        ],
        requiredDocuments=["Aadhaar"],
        applicationProcess="Online",
        officialSourceUrl="https://health.gov.in/",
    )

    # Initialize v1
    versioning_service.initialize_scheme_version(scheme, verified_by="senior_curator")
    v1 = versioning_service.get_active_version("test-scheme-001")
    assert v1 is not None
    assert v1.version == 1

    # Propose candidate rules (e.g. lowering age limit to 55)
    proposal = CandidateRuleProposal(
        proposalId="prop-001",
        schemeId="test-scheme-001",
        proposedRules=[
            EligibilityRuleSchema(
                field="age",
                operator=EligibilityOperator.greaterThanOrEqual,
                value=55,
                isMandatory=True,
            )
        ],
        sourceUrl="https://health.gov.in/gazette-2026",
        sourceName="Ministry Gazette Notification",
        department="Ministry of Health",
        justification="Age criterion expanded in FY26 Union Budget",
    )
    versioning_service.submit_candidate_proposal(proposal)

    # Pending proposals check
    pending = versioning_service.list_pending_proposals("test-scheme-001")
    assert len(pending) == 1

    # Human approval creates v2
    v2 = versioning_service.approve_proposal(
        proposal_id="prop-001",
        reviewer_id="lead_verifier",
        notes="Verified against official Gazette publication.",
    )
    assert v2 is not None
    assert v2.version == 2
    assert v2.isActive is True

    # Active version is now v2
    active = versioning_service.get_active_version("test-scheme-001")
    assert active.version == 2
    assert active.rules[0].value == 55

    # Rollback to v1
    v3 = versioning_service.rollback_to_version(
        scheme_id="test-scheme-001",
        target_version=1,
        operator_id="admin_auditor",
        reason="Gazette notification stayed by court order.",
    )
    assert v3 is not None
    assert v3.version == 3
    assert v3.rules[0].value == 60


# 4. Conflict Diagnostics and CSC Directory Tests
def test_conflict_diagnostics_and_csc_search(assistance_service):
    # Search CSCs in Madhya Pradesh Bhopal
    mp_cscs = assistance_service.search_csc(state="Madhya Pradesh", district="Bhopal")
    assert len(mp_cscs) >= 1
    assert mp_cscs[0].state == "Madhya Pradesh"
    assert mp_cscs[0].pin_code == "462011"

    # Search by PIN code
    pin_cscs = assistance_service.search_csc(pin_code="452002")
    assert len(pin_cscs) >= 1
    assert pin_cscs[0].district == "Indore"

    # Generate human referral package
    mock_scheme = SchemeModelSchema(
        schemeId="pm-kisan-001",
        name="PM Kisan Samman Nidhi",
        description="Description",
        category="agriculture",
        ministry="Ministry of Agriculture",
        governmentLevel=GovernmentLevel.central,
        benefits="Income support",
        eligibilityRules=[],
        requiredDocuments=["Aadhaar", "Land Record"],
        applicationProcess="Online",
        officialSourceUrl="https://pmkisan.gov.in/",
    )
    referral = assistance_service.generate_human_referral(
        scheme=mock_scheme,
        reason="Citizen holds unrecorded leasehold land requiring Patwari verification.",
        user_state="Madhya Pradesh",
        user_district="Bhopal",
    )
    assert referral.scheme_id == "pm-kisan-001"
    assert referral.suggested_csc_centre is not None
    assert "Patwari" in referral.reason_for_referral


# 5. FastAPI Integration Endpoint Tests
@pytest.mark.asyncio
async def test_fastapi_endpoints():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Health check
        res_health = await client.get("/api/health")
        assert res_health.status_code == 200
        data_health = res_health.json()
        assert data_health["status"] == "healthy"

        # List schemes
        res_schemes = await client.get("/api/schemes")
        assert res_schemes.status_code == 200
        assert len(res_schemes.json()) >= 6

        # Categories
        res_cats = await client.get("/api/schemes/categories/all")
        assert res_cats.status_code == 200
        assert len(res_cats.json()) == 8

        # CSC locator
        res_csc = await client.get("/api/assistance/csc?state=Madhya%20Pradesh")
        assert res_csc.status_code == 200
        assert len(res_csc.json()) >= 1

        # Income estimation
        res_income = await client.post(
            "/api/assistance/estimate-income",
            json={
                "primary_source": "farming",
                "monthly_estimated_income": 7000.0,
                "household_earners": 1,
                "has_agricultural_income": True,
                "seasonal_agricultural_income": 30000.0,
            },
        )
        assert res_income.status_code == 200
        data_inc = res_income.json()
        assert data_inc["min_annual_income"] > 0
        assert data_inc["max_annual_income"] > data_inc["min_annual_income"]


# 6. Multi-Agent Orchestrator Execution Test
@pytest.mark.asyncio
async def test_langgraph_multi_agent_orchestrator():
    from backend.app.agents.orchestrator import SahayMultiAgentOrchestrator

    orchestrator = SahayMultiAgentOrchestrator()
    result = await orchestrator.execute(
        query="farmer financial assistance scheme",
        user_answers={
            "occupation": "farmer",
            "state": "Madhya Pradesh",
            "annualIncome": "unknown",  # triggers income assistance branch
            "monthlyEstimatedIncome": 8000,
        },
        language="hi",
    )

    assert result["systemStatus"] == "completed_successfully"
    assert result["totalSchemesEvaluated"] >= 1
    assert "agentExecutionPath" in result
    path = result["agentExecutionPath"]
    assert "DiscoveryAgent" in path
    assert "TrustAndVerificationAgent" in path
    assert "EligibilityAssistanceAgent" in path
    assert "DocumentAssistanceAgent" in path
    assert "FraudAndAuthenticityAgent" in path
    assert "IncomeAssistanceAgent" in path
    assert "ResultAggregator" in path

