# SAHAY (सहाय) — Firebase Document Security Architecture

## 1. Overview

The SAHAY document vault architecture enforces strict security boundaries designed to protect citizen privacy, adhere to Indian data protection principles (DPDP Act), and ensure zero retention of unauthorized sensitive identifiers.

---

## 2. Cloud Firestore Rules Analysis

In `firestore.rules`, user document metadata is stored under:
`/users/{uid}/documents/{documentId}`

### Security Enforcement
```rules
match /documents/{documentId} {
  allow read, delete: if isOwner();
  allow create, update: if isOwner()
    && request.resource.data.userId == uid
    && hasNoForbiddenFields(request.resource.data);
}
```

1. **Owner Isolation (`isOwner()`)**:
   - Evaluates `request.auth != null && request.auth.uid == uid`.
   - Prevents any citizen from reading or enumerating documents belonging to another user.
2. **Path / UID Integrity**:
   - `request.resource.data.userId == uid` prevents writing documents with spoofed user identifiers.
3. **Anti-PII & Forbidden Fields Protection (`hasNoForbiddenFields`)**:
   - Rejects writes containing forbidden plaintext identifiers:
     - `aadhaar`, `aadhaarNumber`
     - `pan`, `panNumber`
     - `bank`, `bankAccount`, `accountNumber`, `ifsc`
     - `salary`, `annualIncome`
   - Only document type classification (e.g. `'aadhaar_card'`), user-facing label, formatted file size, and storage paths are stored in metadata.

---

## 3. Firebase Cloud Storage Rules (`storage.rules`)

The companion Cloud Storage security rules protect the binary document assets:
`/users/{userId}/documents/{fileName}`

### Security Enforcement
```rules
match /users/{userId}/documents/{fileName} {
  function isOwner() {
    return request.auth != null && request.auth.uid == userId;
  }
  function isValidSize() {
    return request.resource.size <= 5 * 1024 * 1024; // 5 MB maximum
  }
  function isValidType() {
    return request.resource.contentType.matches('application/pdf')
      || request.resource.contentType.matches('image/jpeg')
      || request.resource.contentType.matches('image/png');
  }

  allow read, delete: if isOwner();
  allow create, update: if isOwner()
    && isValidSize()
    && isValidType();
}
```

1. **Strict File Size Ceiling**:
   - Enforces an absolute maximum file size of 5 MB (`5 * 1024 * 1024` bytes).
   - Prevents storage exhaustion attacks and accidental oversized video/media uploads.
2. **MIME Type Whitelist**:
   - Restricted to `application/pdf`, `image/jpeg`, and `image/png`.
   - Executable binaries, scripts, and macro-enabled documents are blocked at the storage layer.
3. **Default Deny**:
   - Any access outside the authenticated user's dedicated path is denied by default.

---

## 4. Shared Phone & Offline Data Purge

SAHAY is explicitly designed for the Indian rural context where multiple family members or village citizens may share a single smartphone.
- **End Session & Clear Data**:
  When a citizen completes an assisted session, triggering "End Session" invokes `DocumentService.deleteAllUserDocuments(userId)`, purging all session answers, cached document metadata, and temporary files from the device.
- **In-Memory Fallback Store**:
  In offline or demonstration modes without active Firebase connectivity, documents are maintained in a localized in-memory structure that is cleared upon app close or user logout.

