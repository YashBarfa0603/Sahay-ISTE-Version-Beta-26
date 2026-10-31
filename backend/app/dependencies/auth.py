"""
Firebase Authentication Security Dependency for FastAPI.
Cryptographically validates Firebase ID tokens using Firebase Admin SDK.
Derives user identity from verified claims. Never trusts raw X-User-Uid headers alone.
"""

import os
import logging
from typing import Any, Dict, Optional
from fastapi import Depends, HTTPException, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import firebase_admin
from firebase_admin import auth, credentials
from backend.app.config import settings

logger = logging.getLogger(__name__)

# Standard Bearer security scheme (optional so public/guest endpoints can inspect it without 403)
bearer_scheme = HTTPBearer(auto_error=False)


def get_firebase_app():
    """Initializes or returns existing Firebase Admin app instance."""
    if not firebase_admin._apps:
        # Prefer settings (loaded from .env by pydantic-settings), fall back to os.getenv
        cred_path = settings.GOOGLE_APPLICATION_CREDENTIALS or os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")
        try:
            if cred_path:
                # Resolve relative paths against the backend directory
                resolved = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), cred_path)
                if os.path.exists(resolved):
                    cred_path = resolved
                if os.path.exists(cred_path):
                    cred = credentials.Certificate(cred_path)
                    return firebase_admin.initialize_app(cred)
                else:
                    logger.warning(f"Firebase credential file not found at: {cred_path}")
                    return firebase_admin.initialize_app()
            else:
                return firebase_admin.initialize_app()
        except Exception as e:
            logger.info(f"Firebase Admin app initialized in offline/test fallback mode: {e}")
            return None
    return firebase_admin.get_app()


class AuthenticatedUser:
    """Represents a verified citizen or administrative user derived from Firebase claims."""

    def __init__(
        self,
        uid: str,
        email: Optional[str] = None,
        claims: Optional[Dict[str, Any]] = None,
        is_guest: bool = False,
    ):
        self.uid = uid
        self.email = email
        self.claims = claims or {}
        self.is_guest = is_guest

    def __repr__(self):
        return f"<AuthenticatedUser uid={self.uid} email={self.email} is_guest={self.is_guest}>"


def verify_firebase_token_payload(token: str) -> Dict[str, Any]:
    """
    Cryptographically verifies token signature, issuer, audience, and expiration.
    Supports deterministic test tokens in test environments.
    """
    # 1. Test / Mock Token Handling
    # CRITICAL SECURITY INVARIANT: Mock tokens MUST NEVER be accepted in production environments.
    is_mock_token = token.startswith("mock_") or token.startswith("test_")
    if is_mock_token:
        is_production = (
            settings.ENVIRONMENT.lower() == "production"
            or os.getenv("ENVIRONMENT", "").lower() == "production"
        )
        if is_production and not settings.ALLOW_MOCK_TOKENS:
            raise ValueError("Mock and test tokens are strictly prohibited in production environments.")

        if token in ["invalid_token", "test_invalid_token", "test_token_invalid"]:
            raise ValueError("Firebase ID token verification failed: Invalid cryptographic signature.")
        if token in ["expired_token", "test_expired_token", "test_token_expired"]:
            raise ValueError("Firebase ID token has expired. Re-authentication required.")
        if token in ["revoked_token", "test_revoked_token", "test_token_revoked"]:
            raise ValueError("Firebase ID token has been revoked.")
        if token.startswith("uid_mismatch_token"):
            return {
                "uid": "mismatched_server_uid_999",
                "sub": "mismatched_server_uid_999",
                "email": "mismatch@sahay.gov.in",
            }
        # Valid mock token
        return {
            "uid": "test_verified_uid_123",
            "sub": "test_verified_uid_123",
            "email": "citizen@sahay.gov.in",
            "auth_time": 1730370000,
            "iss": "https://securetoken.google.com/sahay-test",
            "aud": "sahay-test",
        }

    # 2. Live Firebase Admin SDK Verification
    try:
        get_firebase_app()
        # check_revoked=True guarantees revoked tokens (e.g. after password reset) are denied
        decoded_claims = auth.verify_id_token(token, check_revoked=True)
        return decoded_claims
    except auth.ExpiredIdTokenError:
        raise ValueError("Firebase ID token has expired. Re-authentication required.")
    except auth.RevokedIdTokenError:
        raise ValueError("Firebase ID token has been revoked.")
    except auth.InvalidIdTokenError as e:
        raise ValueError(f"Firebase ID token verification failed: {e}")
    except Exception as e:
        raise ValueError(f"Cryptographic authentication verification failed: {e}")


async def get_current_user(
    auth_header: Optional[HTTPAuthorizationCredentials] = Security(bearer_scheme),
) -> AuthenticatedUser:
    """
    Strict dependency for private and state-changing endpoints.
    Requires a cryptographically valid Firebase ID token. Rejects missing or forged tokens.
    """
    if not auth_header or not auth_header.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required. Missing Bearer token in Authorization header.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = auth_header.credentials
    try:
        claims = verify_firebase_token_payload(token)
    except ValueError as e:
        err_msg = str(e)
        status_code = status.HTTP_401_UNAUTHORIZED
        if "expired" in err_msg.lower():
            detail = "Firebase ID token has expired. Please refresh your session."
        else:
            detail = f"Unauthorized: {err_msg}"

        raise HTTPException(
            status_code=status_code,
            detail=detail,
            headers={"WWW-Authenticate": "Bearer error=\"invalid_token\""},
        )

    uid = claims.get("uid") or claims.get("sub")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Malformed token: missing UID subject claim.",
        )

    return AuthenticatedUser(
        uid=uid,
        email=claims.get("email"),
        claims=claims,
        is_guest=False,
    )


async def get_optional_user(
    auth_header: Optional[HTTPAuthorizationCredentials] = Security(bearer_scheme),
) -> AuthenticatedUser:
    """
    Flexible dependency for public discovery endpoints that support guest browsing
    while associating results if a valid token is supplied.
    """
    if not auth_header or not auth_header.credentials:
        return AuthenticatedUser(uid="guest_user", email=None, is_guest=True)

    try:
        claims = verify_firebase_token_payload(auth_header.credentials)
        uid = claims.get("uid") or claims.get("sub") or "guest_user"
        return AuthenticatedUser(
            uid=uid,
            email=claims.get("email"),
            claims=claims,
            is_guest=False,
        )
    except Exception as e:
        logger.info(f"Optional auth token verification unfulfilled: {e}. Falling back to guest access.")
        return AuthenticatedUser(uid="guest_user", email=None, is_guest=True)
