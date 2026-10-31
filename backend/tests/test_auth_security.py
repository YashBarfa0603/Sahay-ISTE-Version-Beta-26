"""
Unit Test Suite for FastAPI Firebase Authentication Security.
Verifies cryptographic validation of Firebase ID tokens, token expiration,
tampering rejection, public guest access, and protected route enforcement.
"""

import pytest
from httpx import ASGITransport, AsyncClient
from backend.app.main import app
from backend.app.dependencies.auth import verify_firebase_token_payload


def test_verify_valid_token():
    """Confirms valid token signature and claim extraction."""
    claims = verify_firebase_token_payload("test_token_valid_citizen")
    assert claims["uid"] == "test_verified_uid_123"
    assert "email" in claims


def test_verify_invalid_token():
    """Confirms invalid or forged token is rejected."""
    with pytest.raises(ValueError, match="Invalid cryptographic signature"):
        verify_firebase_token_payload("test_invalid_token")


def test_verify_expired_token():
    """Confirms expired token is rejected with explicit expiration error."""
    with pytest.raises(ValueError, match="token has expired"):
        verify_firebase_token_payload("test_expired_token")


@pytest.mark.asyncio
async def test_public_guest_endpoint_allows_unauthenticated_access():
    """Confirms public scheme catalogue is accessible to guests without Authorization header."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Public health check
        res_health = await client.get("/api/health")
        assert res_health.status_code == 200

        # Public scheme discovery
        res_schemes = await client.get("/api/schemes")
        assert res_schemes.status_code == 200
        assert len(res_schemes.json()) >= 6


@pytest.mark.asyncio
async def test_protected_versioning_endpoint_denies_missing_token():
    """Confirms state-changing proposal endpoint returns 401 when Authorization header is absent."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.post(
            "/api/versioning/proposals",
            json={
                "proposalId": "prop-unauth-001",
                "schemeId": "pm-kisan-001",
                "proposedRules": [],
                "sourceUrl": "https://gov.in",
                "sourceName": "Test Source",
                "department": "Agriculture",
                "justification": "Test unauthenticated modification",
            },
        )
        assert res.status_code == 401
        assert "Authentication required" in res.json()["detail"]


@pytest.mark.asyncio
async def test_protected_versioning_endpoint_denies_invalid_token():
    """Confirms state-changing endpoint returns 401 when token is invalid."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.post(
            "/api/versioning/proposals",
            headers={"Authorization": "Bearer test_invalid_token"},
            json={
                "proposalId": "prop-invalid-002",
                "schemeId": "pm-kisan-001",
                "proposedRules": [],
                "sourceUrl": "https://gov.in",
                "sourceName": "Test Source",
                "department": "Agriculture",
                "justification": "Test invalid token modification",
            },
        )
        assert res.status_code == 401
        assert "Unauthorized" in res.json()["detail"]


@pytest.mark.asyncio
async def test_protected_versioning_endpoint_denies_expired_token():
    """Confirms state-changing endpoint returns 401 when token is expired."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.post(
            "/api/versioning/proposals",
            headers={"Authorization": "Bearer test_expired_token"},
            json={
                "proposalId": "prop-expired-003",
                "schemeId": "pm-kisan-001",
                "proposedRules": [],
                "sourceUrl": "https://gov.in",
                "sourceName": "Test Source",
                "department": "Agriculture",
                "justification": "Test expired token modification",
            },
        )
        assert res.status_code == 401
        assert "expired" in res.json()["detail"].lower()


@pytest.mark.asyncio
async def test_protected_versioning_endpoint_accepts_valid_token():
    """Confirms state-changing endpoint accepts valid authenticated token and derives UID."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.post(
            "/api/versioning/proposals",
            headers={"Authorization": "Bearer test_token_valid_auth"},
            json={
                "proposalId": "prop-valid-004",
                "schemeId": "pm-kisan-001",
                "proposedRules": [],
                "sourceUrl": "https://pmkisan.gov.in/gazette-2026",
                "sourceName": "Official Gazette",
                "department": "Ministry of Agriculture",
                "justification": "Valid authenticated proposal submission",
            },
        )
        assert res.status_code == 200
        proposal_id = res.json()
        assert proposal_id == "prop-valid-004"


def test_verify_revoked_token():
    """Confirms revoked token is rejected with explicit revocation error."""
    with pytest.raises(ValueError, match="token has been revoked"):
        verify_firebase_token_payload("test_revoked_token")


def test_mock_token_strictly_prohibited_in_production(monkeypatch):
    """Confirms mock/test tokens are strictly rejected when running in production."""
    from backend.app.config import settings

    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    monkeypatch.delenv("TESTING", raising=False)

    with pytest.raises(ValueError, match="strictly prohibited in production"):
        verify_firebase_token_payload("test_token_valid_citizen")


@pytest.mark.asyncio
async def test_protected_endpoint_denies_mock_token_in_production(monkeypatch):
    """Confirms state-changing endpoint returns 401 when mock token is submitted in production."""
    from backend.app.config import settings

    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    monkeypatch.delenv("TESTING", raising=False)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.post(
            "/api/versioning/proposals",
            headers={"Authorization": "Bearer test_token_valid_auth"},
            json={
                "proposalId": "prop-prod-block-005",
                "schemeId": "pm-kisan-001",
                "proposedRules": [],
                "sourceUrl": "https://gov.in",
                "sourceName": "Test Source",
                "department": "Agriculture",
                "justification": "Should be blocked in production",
            },
        )
        assert res.status_code == 401
        assert "strictly prohibited in production" in res.json()["detail"]


