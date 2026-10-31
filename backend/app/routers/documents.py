"""
SAHAY (सहाय) — Document Vault Router.
Provides backend-mediated endpoints for authenticated citizens to securely upload,
list, and delete documents stored privately in Cloudinary.

Security Guarantees:
1. Every endpoint requires a valid Firebase Bearer ID Token (`get_current_user`).
2. Guest and unauthenticated requests are strictly rejected with HTTP 401.
3. Cross-user access is impossible: operations strictly operate on `user.uid`.
4. Cloudinary API secrets are kept server-side only.
"""

import time
import uuid
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import BaseModel, Field

from backend.app.dependencies.auth import AuthenticatedUser, get_current_user
from backend.app.services.cloudinary_service import vault_service

router = APIRouter(prefix="/api/documents", tags=["Document Vault"])

# In-memory document metadata repository (persisting user document entries)
# In production, this syncs with Cloud Firestore collection `users/{uid}/documents/{docId}`
_vault_metadata_db: Dict[str, Dict[str, Any]] = {}

ALLOWED_EXTENSIONS = {".pdf", ".jpg", ".jpeg", ".png"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


class DocumentResponse(BaseModel):
    document_id: str
    user_id: str
    document_type: str
    display_name: str
    filename: str
    public_id: str
    signed_url: str
    format: str
    bytes: int
    created_at: str
    is_private: bool = True


@router.post("/upload", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED)
async def upload_document_to_vault(
    file: UploadFile = File(...),
    document_type: str = Form(...),
    display_name: Optional[str] = Form(None),
    user: AuthenticatedUser = Depends(get_current_user),
):
    """
    Uploads a government document to the private Cloudinary Document Vault.
    Requires a valid Firebase Bearer token.
    """
    filename = file.filename or "document.pdf"
    ext = "." + filename.split(".")[-1].lower() if "." in filename else ""

    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file format '{ext}'. Allowed formats: PDF, JPG, PNG.",
        )

    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File exceeds maximum allowed size of 10MB ({len(content)} bytes).",
        )

    # Clean document type identifier
    clean_doc_type = document_type.strip().lower().replace(" ", "_")
    name = display_name or filename

    # Upload to Cloudinary with private/authenticated access type
    cloudinary_res = vault_service.upload_private_document(
        file_bytes=content,
        filename=filename,
        user_id=user.uid,
        document_type=clean_doc_type,
    )

    doc_id = str(uuid.uuid4())
    doc_record = {
        "document_id": doc_id,
        "user_id": user.uid,
        "document_type": clean_doc_type,
        "display_name": name,
        "filename": filename,
        "public_id": cloudinary_res["public_id"],
        "signed_url": cloudinary_res["signed_url"],
        "resource_type": cloudinary_res["resource_type"],
        "format": cloudinary_res["format"],
        "bytes": cloudinary_res["bytes"],
        "created_at": cloudinary_res["created_at"],
        "is_private": True,
    }

    # Store metadata record
    _vault_metadata_db[doc_id] = doc_record

    return DocumentResponse(**doc_record)


@router.get("/my-vault", response_model=List[DocumentResponse])
async def list_my_documents(
    user: AuthenticatedUser = Depends(get_current_user),
):
    """
    Lists all documents stored in the vault for the authenticated citizen.
    Refreshes time-limited signed delivery URLs for private access.
    """
    user_docs: List[DocumentResponse] = []

    for doc in _vault_metadata_db.values():
        if doc["user_id"] == user.uid:
            # Refresh signed delivery URL
            fresh_url = vault_service.generate_signed_url(
                public_id=doc["public_id"],
                resource_type=doc.get("resource_type", "image"),
                expires_in=3600,
            )
            doc_copy = dict(doc)
            doc_copy["signed_url"] = fresh_url
            user_docs.append(DocumentResponse(**doc_copy))

    return user_docs


@router.delete("/{document_id}", status_code=status.HTTP_200_OK)
async def delete_document_from_vault(
    document_id: str,
    user: AuthenticatedUser = Depends(get_current_user),
):
    """
    Deletes a document from Cloudinary and deletes its vault record.
    Prevents cross-user deletion.
    """
    doc = _vault_metadata_db.get(document_id)
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Document with ID '{document_id}' not found.",
        )

    if doc["user_id"] != user.uid:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You can only delete documents belonging to your own account.",
        )

    # Delete from Cloudinary
    vault_service.delete_document(
        public_id=doc["public_id"],
        resource_type=doc.get("resource_type", "image"),
    )

    del _vault_metadata_db[document_id]

    return {
        "status": "deleted",
        "document_id": document_id,
        "message": "Document successfully deleted from Cloudinary vault.",
    }

