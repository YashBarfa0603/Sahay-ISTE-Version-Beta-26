# SAHAY (सहाय) — Automatic Scheme Document Checklist Implementation

## 1. Overview

The **Automatic Scheme Document Checklist** links a citizen's private document vault directly to government scheme requirements. When a citizen explores any scheme, SAHAY dynamically cross-references the scheme's required certificates with the user's uploaded documents.

---

## 2. Canonical Matching Engine

Government schemes use disparate nomenclature across ministries and languages (e.g., *"Land ownership documents"*, *"Khasra/Khatauni copy"*, *"Record of Rights (RoR)"*). 

`DocumentCatalogueService.matchCanonicalId(String documentName)` implements fuzzy semantic mapping:

| Scheme Requirement Text | Canonical ID | Mapped Display Name |
| :--- | :--- | :--- |
| `"Aadhaar Card of the applicant farmer"` | `aadhaar_card` | Aadhaar Card / आधार कार्ड |
| `"Land ownership documents (Khatauni/RoR)"` | `land_ownership_record` | Land Ownership Record / खतौनी |
| `"Active bank account passbook"` | `bank_passbook` | Bank Account Passbook / बैंक पासबुक |
| `"Samagra Family ID and Member ID"` | `samagra_id` | Samagra ID / समग्र परिवार आईडी |
| `"Ration Card (BPL/NFSA)"` | `ration_card` | Ration Card / राशन कार्ड |
| `"Income Certificate issued by Tehsildar"` | `income_certificate` | Income Certificate / आय प्रमाण पत्र |
| `"Class 12th Marksheet / MEQ Proof"` | `marksheet_12th` | Class 12th Marksheet / 12वीं अंकसूची |
| `"MGNREGA Job Card"` | `mgnrega_job_card` | MGNREGA Job Card / मनरेगा जॉब कार्ड |

---

## 3. Real-Time Status Indication

On both the **Scheme Detail Screen** and the **Document Checklist Screen**:
- **"In Vault" (वॉल्ट में)**: Highlighted with a green badge and check icon when the user has uploaded the corresponding document.
- **"Not in Vault" / "Missing" (वॉल्ट में नहीं है)**: Displayed with a neutral badge, alerting the user to prepare the document.
- **Top Summary Banner**: Displays the exact tally (e.g. `2/3 Documents Ready in Vault`).

---

## 4. Legal & Verification Disclaimer

To prevent citizens from mistakenly believing that uploading a file to SAHAY constitutes official government submission or approval, the UI embeds clear, bilingual disclaimers:

> [!IMPORTANT]
> **Uploaded to Vault — Not Officially Verified**:
> Documents uploaded to SAHAY are stored for the citizen's personal reference and readiness. Official government verification is conducted by competent departmental authorities against physical originals or authorized departmental API portals during application processing.

---

## 5. Native PDF Checklist Generation

The checklist can be exported as a clean, printable PDF via `PdfService` and shared through native platform dialogs (`Printing.sharePdf` / `Printing.layoutPdf`). The generated PDF includes:
- Citizen Name and Date.
- Scheme Title and Ministry.
- Complete list of required certificates with readiness checkboxes.
- Application portal URL and nearest Common Service Centre (CSC) guidance.

