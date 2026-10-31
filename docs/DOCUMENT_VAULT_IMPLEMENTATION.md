# SAHAY — Document Vault Implementation Report (Phase 2)

## Executive Summary
This report outlines the complete production implementation of the **My Documents / Personal Document Vault** in SAHAY (सहाय). All previous simulated slider and format controls have been upgraded to real device file selection, private Firebase Storage integration with local offline resilience, full document lifecycle management (Upload, View/Preview, Replace, Delete), and deep scheme checklist integration.

---

## 1. Architectural Design & Storage Layout

### Private Storage Hierarchy
All document files are stored privately under user-scoped paths:
```
users/{userId}/documents/{documentType}/{fileName}
```
- `{userId}`: Firebase Authentication UID of the verified citizen.
- `{documentType}`: Canonical identifier (e.g. `aadhaar_card`, `income_certificate`, `caste_certificate`, `ration_card`).
- `{fileName}`: Sanitized file name preventing path traversal or special character injection.

### Firestore Metadata Schema
Metadata is persisted under the user's private subcollection:
`users/{userId}/documents/{documentId}`
- `documentId`: Unique identifier (`{userId}_{documentType}_{timestamp}`).
- `userId`: Owner citizen's UID.
- `documentType`: Canonical document string.
- `documentName`: User-facing localized title.
- `storagePath`: Private storage reference.
- `downloadUrl`: Optional signed or authenticated download URL.
- `fileType`: Extracted extension (`pdf`, `jpg`, `png`).
- `fileSize`: Raw file size in bytes.
- `uploadedAt`: Timestamp of initial upload.
- `updatedAt`: Timestamp of last replacement.
- `verificationStatus`: `uploaded`, `user_confirmed`, or `verified`.
- `notes`: Optional citizen annotation (e.g., year of issuance).

---

## 2. File Selection & Validation Rules

1. **File Selection**:
   - Integrated `FilePicker.platform.pickFiles` with custom file type restrictions (`allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']`).
   - Supports native iOS and Android file system pickers.
2. **Validation Safeguards**:
   - Supported extensions strictly enforced: PDF, JPG, JPEG, PNG.
   - Max file size: **5.0 MB** (`5 * 1024 * 1024` bytes).
   - Empty files (0 bytes) rejected with clear error feedback.
   - Informative error banners displayed immediately if an invalid file is selected.

---

## 3. Document Lifecycle Implementation

1. **Upload**:
   - User picks file -> format and size are validated.
   - Uploads binary data with `SettableMetadata` containing MIME type and custom owner tags.
   - `LinearProgressIndicator` displays real-time transfer progress.
   - Graceful fallback: If Firebase Storage is unreachable or uninitialized, file bytes and metadata are preserved in local encrypted memory/cache without crashing.
2. **View / Preview**:
   - Images (`jpg`, `jpeg`, `png`): Rendered directly in-app via cached bytes or secure URL.
   - PDFs: Displays document metadata card with size, upload date, status, and official specimen reference.
3. **Safe Replacement**:
   - User is presented with a confirmation dialog: "Uploading a new version will replace the current file in your vault once the new upload succeeds."
   - New file is uploaded and Firestore record is updated first.
   - Only upon confirmed success of the new upload is the old storage object deleted.
4. **Delete**:
   - Prompts citizen confirmation dialog.
   - Removes both the Firebase Storage object and the Firestore document metadata.
   - Updates `UserDocumentProvider` state reactively.

---

## 4. Scheme Checklist Integration

- The scheme details screen (`lib/screens/scheme_detail_screen.dart`) checks `UserDocumentProvider.hasDocument(canonicalId)`.
- If present in the vault:
  - Marked with green "In Vault" badge and automatically ready for application preparation.
- If missing from the vault:
  - Displays an "Upload Now" action button.
  - Tapping "Upload Now" navigates to `MyDocumentsScreen(preselectedType: canonicalId)`, automatically opening the upload modal for that required document.

---

## 5. Automated Verification & Test Coverage

All functionality is tested in `test/document_vault_lifecycle_test.dart` and `test/document_vault_test.dart`:
- Path hierarchy verification (`users/{userId}/documents/{documentType}/{fileName}`).
- Format validation (rejects unsupported extensions like `.exe`).
- Size limit validation (rejects files exceeding 5MB).
- Safe replacement and cleanup of outdated storage files.
- Atomic deletion of storage objects and Firestore metadata.
- Automated widget opening of preselected document types.

