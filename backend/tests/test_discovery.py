"""
Test Suite for SAHAY Backend Scheme Discovery and Verification Services.
"""

import pytest
from backend.app.database.db_interface import InMemorySchemeDatabase
from backend.app.models.scheme_schemas import (
    SchemeModelSchema,
    GovernmentLevel,
    VerificationStatus,
    SchemeSourceType,
    SchemeSearchQuery,
)
from backend.app.services.verification_service import VerificationService
from backend.app.services.tavily_service import TavilyService
from backend.app.services.scraper_service import ScraperService
from backend.app.services.ollama_service import OllamaService
from backend.app.services.discovery_pipeline import DiscoveryPipeline


@pytest.fixture
def db():
    return InMemorySchemeDatabase()


@pytest.fixture
def verifier():
    return VerificationService()


@pytest.mark.asyncio
async def test_database_preload_and_search(db):
    # Verify preloaded baseline count
    schemes = await db.list_all_schemes()
    assert len(schemes) >= 6

    # Verify search by keyword (farmer / PM-KISAN)
    results = await db.search_schemes("farmer")
    assert len(results) >= 1
    assert any("pm-kisan" in s.schemeId.lower() for s in results)

    # Verify search by state filter (Ladli Behna in MP)
    mp_results = await db.search_schemes("", state="Madhya Pradesh")
    assert len(mp_results) >= 1
    assert any("ladli" in s.schemeId.lower() for s in mp_results)


def test_verification_credibility_gov_domains(verifier):
    candidate = SchemeModelSchema(
        schemeId="test-001",
        name="Test Welfare Scheme",
        description="A comprehensive scheme description providing benefits to eligible citizens.",
        category="agriculture",
        ministry="Ministry of Agriculture",
        governmentLevel=GovernmentLevel.central,
        benefits="Financial assistance of Rs 5000 per year directly transferred.",
        requiredDocuments=["Aadhaar Card", "Bank Account"],
        applicationProcess="Apply online at the official portal.",
        officialSourceUrl="https://myscheme.gov.in/schemes/test",
    )

    audited, report = verifier.audit_scheme(candidate, [])
    assert report.is_credible is True
    assert audited.verificationStatus == VerificationStatus.pending
    # Discovered schemes must NEVER be automatically verified
    assert audited.verificationStatus != VerificationStatus.verified


def test_verification_rejects_untrusted_domain(verifier):
    candidate = SchemeModelSchema(
        schemeId="fake-001",
        name="Suspicious Financial Scheme",
        description="Get free money by registering your details on this third-party blog.",
        category="financial",
        ministry="Unknown",
        governmentLevel=GovernmentLevel.central,
        benefits="Immediate cash prize.",
        requiredDocuments=["Aadhaar Card"],
        applicationProcess="Click link.",
        officialSourceUrl="https://free-loans-instant-cash.xyz/apply",
    )

    audited, report = verifier.audit_scheme(candidate, [])
    assert report.is_credible is False
    assert audited.verificationStatus == VerificationStatus.rejected
    assert report.audit_passed is False


def test_verification_detects_duplicates(verifier, db):
    candidate = SchemeModelSchema(
        schemeId="dup-001",
        name="PM Kisan Samman Nidhi",
        description="Duplicates PM Kisan scheme already in catalogue.",
        category="agriculture",
        ministry="Ministry of Agriculture",
        governmentLevel=GovernmentLevel.central,
        benefits="Rs 6000 per year.",
        requiredDocuments=["Aadhaar"],
        applicationProcess="Apply online.",
        officialSourceUrl="https://pmkisan.gov.in/",
    )

    import asyncio
    catalog = asyncio.run(db.list_all_schemes())
    audited, report = verifier.audit_scheme(candidate, catalog)
    assert report.is_duplicate is True


@pytest.mark.asyncio
async def test_discovery_pipeline_trusted_hit(db):
    pipeline = DiscoveryPipeline(
        db=db,
        tavily=TavilyService(),
        scraper=ScraperService(),
        ollama=OllamaService(),
        verifier=VerificationService(),
    )

    # Search with empty query and limit 3 hits trusted catalogue
    response = await pipeline.execute_search(
        SchemeSearchQuery(query="Kisan", forceDynamicDiscovery=False)
    )
    assert response.total >= 1
    assert any("pm-kisan" in s.schemeId.lower() for s in response.results)


@pytest.mark.asyncio
async def test_discovery_pipeline_fallback_tavily(db):
    pipeline = DiscoveryPipeline(
        db=db,
        tavily=TavilyService(),
        scraper=ScraperService(),
        ollama=OllamaService(),
        verifier=VerificationService(),
    )

    # Query for scheme not in 6 baseline schemes with forced discovery
    response = await pipeline.execute_search(
        SchemeSearchQuery(query="Namo Drone Didi", forceDynamicDiscovery=True)
    )
    assert response.total >= 1
    assert response.isDynamicDiscovery is True
    # Discovered results must have pending verification
    discovered = [s for s in response.results if s.sourceType == SchemeSourceType.discovered]
    for s in discovered:
        assert s.verificationStatus == VerificationStatus.pending

