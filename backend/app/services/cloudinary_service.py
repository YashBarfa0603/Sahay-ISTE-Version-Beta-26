"""
Cloudinary Document Vault Service for SAHAY (सहाय).
Handles authenticated / private document storage, signed delivery URL generation,
and private file deletion.

Architecture:
- The Flutter client NEVER connects directly to Cloudinary or accesses API keys.
- Uploads and signed URLs are strictly backend-mediated.
- Documents are tagged and stored under a private/authenticated type, ensuring
  they cannot be accessed by guessing public URLs without a valid cryptographic signature.
"""

import time
import uuid
import logging
from typing import Optional, Dict, Any
from backend.app.config import settings

logger = logging.getLogger(__name__)

# Attempt to configure Cloudinary if credentials are provided
_cloudinary_configured = False
try:
    import cloudinary
    import cloudinary.uploader
    import cloudinary.utils

    if settings.CLOUDINARY_CLOUD_NAME and settings.CLOUDINARY_API_KEY and settings.CLOUDINARY_API_SECRET:
        cloudinary.config(
            cloud_name=settings.CLOUDINARY_CLOUD_NAME,
            api_key=settings.CLOUDINARY_API_KEY,
            api_secret=settings.CLOUDINARY_API_SECRET,
            secure=True,
        )
        _cloudinary_configured = True
        logger.info("Cloudinary service initialized successfully with credentials.")
    else:
        logger.info("Cloudinary credentials not set in environment; running in simulated vault mode.")
except ImportError:
    logger.warning("Cloudinary SDK not installed; running in simulated vault mode.")


class CloudinaryVaultService:
    def __init__(self):
        self.is_live = _cloudinary_configured

    def upload_private_document(
        self,
        file_bytes: bytes,
        filename: str,
        user_id: str,
        document_type: str,
    ) -> Dict[str, Any]:
        """
        Uploads a citizen document to Cloudinary with authenticated/private delivery type.
        Returns a dict containing public_id, signed_url, and file metadata.
        """
        clean_doc_type = document_type.strip().lower().replace(" ", "_")
        public_id = f"{settings.CLOUDINARY_SECURE_VAULT_FOLDER}/{user_id}/{clean_doc_type}_{uuid.uuid4().hex[:8]}"

        if self.is_live:
            try:
                import cloudinary.uploader
                import cloudinary.utils

                # Determine resource type (raw for pdf, image for jpg/png)
                resource_type = "raw" if filename.lower().endswith(".pdf") else "image"

                response = cloudinary.uploader.upload(
                    file_bytes,
                    public_id=public_id,
                    type="authenticated",
                    resource_type=resource_type,
                    tags=["sahay", "vault", user_id, clean_doc_type],
                    overwrite=True,
                )

                # Generate a signed URL with 1-hour expiration
                signed_url = self.generate_signed_url(
                    public_id=response.get("public_id", public_id),
                    resource_type=resource_type,
                    expires_in=3600,
                )

                return {
                    "public_id": response.get("public_id", public_id),
                    "secure_url": response.get("secure_url", signed_url),
                    "signed_url": signed_url,
                    "format": response.get("format", filename.split(".")[-1]),
                    "bytes": response.get("bytes", len(file_bytes)),
                    "resource_type": resource_type,
                    "created_at": response.get("created_at", time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())),
                    "is_simulated": False,
                }
            except Exception as e:
                logger.error(f"Live Cloudinary upload failed: {e}. Falling back to simulated response.")

        # Fallback / Simulated mode (for unit testing, development, and offline mode)
        resource_type = "raw" if filename.lower().endswith(".pdf") else "image"
        simulated_signed_url = f"https://res.cloudinary.com/sahay-simulated/authenticated/s--signed--/{public_id}"

        return {
            "public_id": public_id,
            "secure_url": simulated_signed_url,
            "signed_url": simulated_signed_url,
            "format": filename.split(".")[-1] if "." in filename else "dat",
            "bytes": len(file_bytes),
            "resource_type": resource_type,
            "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "is_simulated": True,
        }

    def generate_signed_url(
        self,
        public_id: str,
        resource_type: str = "image",
        expires_in: int = 3600,
    ) -> str:
        """
        Generates a time-limited signed delivery URL for a private/authenticated asset.
        """
        if self.is_live:
            try:
                import cloudinary.utils

                expires_at = int(time.time()) + expires_in
                url, _ = cloudinary.utils.cloudinary_url(
                    public_id,
                    type="authenticated",
                    resource_type=resource_type,
                    sign_url=True,
                    expires_at=expires_at,
                )
                return url
            except Exception as e:
                logger.error(f"Failed to generate live Cloudinary signed URL: {e}")

        # Simulated signed URL with expires timestamp parameter
        expires_at = int(time.time()) + expires_in
        return f"https://res.cloudinary.com/sahay-simulated/authenticated/s--signed--/{public_id}?exp={expires_at}"

    def delete_document(
        self,
        public_id: str,
        resource_type: str = "image",
    ) -> bool:
        """
        Deletes a document from Cloudinary.
        """
        if self.is_live:
            try:
                import cloudinary.uploader

                response = cloudinary.uploader.destroy(
                    public_id,
                    type="authenticated",
                    resource_type=resource_type,
                    invalidate=True,
                )
                return response.get("result") in ["ok", "not found"]
            except Exception as e:
                logger.error(f"Failed to delete Cloudinary asset {public_id}: {e}")
                return False

        return True


vault_service = CloudinaryVaultService()

