"""
Unit and Integration Tests for Cloudinary Document Vault Backend API.
Verifies authenticated uploads, file extension validations, signed URLs,
isolation between users, and 401 rejection for unauthenticated/guest attempts.
"""

import io
import pytest
from httpx import AsyncClient, ASGITransport
from backend.app.main import app


@pytest.mark.asyncio
async def test_upload_document_requires_authentication():
    """Unauthenticated/guest upload attempts must be rejected with 401 Unauthorized."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        file_content = b"%PDF-1.4 sample pdf content"
        files = {"file": ("aadhaar.pdf", io.BytesIO(file_content), "application/pdf")}
        data = {"document_type": "aadhaar_card", "display_name": "My Aadhaar"}

        response = await client.post("/api/documents/upload", files=files, data=data)
        assert response.status_code == 401
        assert "Authentication required" in response.json()["detail"]


@pytest.mark.asyncio
async def test_upload_document_rejects_disallowed_extension():
    """Uploading executable or unsupported file types must be rejected with 400 Bad Request."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        file_content = b"malicious binary content"
        files = {"file": ("virus.exe", io.BytesIO(file_content), "application/octet-stream")}
        data = {"document_type": "aadhaar_card"}
        headers = {"Authorization": "Bearer test_valid_token"}

        response = await client.post("/api/documents/upload", files=files, data=data, headers=headers)
        assert response.status_code == 400
        assert "Unsupported file format" in response.json()["detail"]


@pytest.mark.asyncio
async def test_authenticated_upload_success():
    """Authenticated user successfully uploads private document with signed delivery URL."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        file_content = b"%PDF-1.4 official aadhaar card"
        files = {"file": ("aadhaar.pdf", io.BytesIO(file_content), "application/pdf")}
        data = {"document_type": "aadhaar_card", "display_name": "Aadhaar Card"}
        headers = {"Authorization": "Bearer test_valid_token"}

        response = await client.post("/api/documents/upload", files=files, data=data, headers=headers)
        assert response.status_code == 201
        res_data = response.json()
        assert res_data["document_type"] == "aadhaar_card"
        assert res_data["display_name"] == "Aadhaar Card"
        assert "sahay/document_vault" in res_data["public_id"]
        assert "signed_url" in res_data
        assert res_data["is_private"] is True


@pytest.mark.asyncio
async def test_list_and_delete_user_documents():
    """Listing documents returns authenticated user's records and allows private deletion."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        headers = {"Authorization": "Bearer test_valid_token"}

        # 1. Upload a document
        file_content = b"sample income certificate image bytes"
        files = {"file": ("income.jpg", io.BytesIO(file_content), "image/jpeg")}
        data = {"document_type": "income_certificate", "display_name": "Income Certificate"}

        upload_res = await client.post("/api/documents/upload", files=files, data=data, headers=headers)
        assert upload_res.status_code == 201
        doc_id = upload_res.json()["document_id"]

        # 2. List documents
        list_res = await client.get("/api/documents/my-vault", headers=headers)
        assert list_res.status_code == 200
        docs = list_res.json()
        assert any(d["document_id"] == doc_id for d in docs)

        # 3. Delete document
        del_res = await client.delete(f"/api/documents/{doc_id}", headers=headers)
        assert del_res.status_code == 200
        assert del_res.json()["status"] == "deleted"

        # 4. Verify deleted
        list_res2 = await client.get("/api/documents/my-vault", headers=headers)
        assert not any(d["document_id"] == doc_id for d in list_res2.json())


@pytest.mark.asyncio
async def test_cross_user_deletion_rejected():
    """Attempting to delete another citizen's document must return 403 Forbidden."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        user1_headers = {"Authorization": "Bearer test_valid_token"}
        user2_headers = {"Authorization": "Bearer test_uid_mismatch_token"}

        # User 1 uploads document
        file_content = b"%PDF-1.4 confidential land records"
        files = {"file": ("khasra.pdf", io.BytesIO(file_content), "application/pdf")}
        data = {"document_type": "land_ownership_record", "display_name": "Land Record"}

        upload_res = await client.post("/api/documents/upload", files=files, data=data, headers=user1_headers)
        assert upload_res.status_code == 201
        doc_id = upload_res.json()["document_id"]

        # User 2 attempts to delete User 1's document
        del_res = await client.delete(f"/api/documents/{doc_id}", headers=user2_headers)
        assert del_res.status_code == 403
        assert "Forbidden" in del_res.json()["detail"]


@pytest.mark.asyncio
async def test_upload_additional_document_with_custom_display_name():
    """Uploading an additional document preserves the custom user-entered display name."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        file_content = b"%PDF-1.4 birth certificate document"
        files = {"file": ("birth_cert.pdf", io.BytesIO(file_content), "application/pdf")}
        data = {
            "document_type": "additional_document",
            "display_name": "Birth Certificate",
        }
        headers = {"Authorization": "Bearer test_valid_token"}

        response = await client.post("/api/documents/upload", files=files, data=data, headers=headers)
        assert response.status_code == 201
        res = response.json()
        assert res["document_type"] == "additional_document"
        assert res["display_name"] == "Birth Certificate"

        # Verify in my-vault
        list_res = await client.get("/api/documents/my-vault", headers=headers)
        assert list_res.status_code == 200
        matched = [d for d in list_res.json() if d["document_id"] == res["document_id"]]
        assert len(matched) == 1
        assert matched[0]["display_name"] == "Birth Certificate"
        assert matched[0]["document_type"] == "additional_document"

