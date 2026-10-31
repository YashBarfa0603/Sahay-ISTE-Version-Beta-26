# SAHAY (सहाय) — Comprehensive Platform Enhancement Report
**Date:** November 1, 2026  
**Status:** Successfully Implemented & Verified (132/132 Flutter Tests Passing, 86/86 Pytest Tests Passing, 0 Analyzer Warnings)

---

## 1. Executive Summary

This engineering implementation delivers five core enhancements to the SAHAY (सहाय) platform, elevating the scheme discovery, application guidance, and document management capabilities while preserving full backward compatibility with existing services, models, and UI workflows:

1. **Category-Based Scheme Discovery**: Full relational matching against the complete scheme catalogue across 13 canonical categories, accessible seamlessly to both guest and authenticated users.
2. **Personalized Scheme Recommendations**: Pure deterministic criteria evaluation matching profile attributes against scheme eligibility rules with explainable badges and zero reliance on stochastic LLM decisions.
3. **Official Document References & Zoom Viewer**: Authentic visual specimen layouts for primary Indian documents (including UIDAI Aadhaar Card and MP Samagra SSSM ID) with direct official portal URLs and full-screen `InteractiveViewer` zoom previews.
4. **Verified YouTube Application Tutorials**: Curated official/verified video walkthroughs in *How to Apply* with thumbnail previews, channel attribution, and clear fallback notices when no verified tutorial exists.
5. **Secure Cloudinary Document Vault**: Multi-tenant backend-mediated storage architecture verifying Firebase ID tokens, generating signed time-expiring URLs (1-hour TTL), and blocking unauthenticated or cross-tenant document access.

---

## 2. Feature Details & Architecture

### Feature 1: Explore by Category (Guest & Authenticated)
- **Service**: `lib/services/category_service.dart`
- **Canonical Categories (13)**:
  - `agriculture`: Agriculture, Rural & Farming
  - `education`: Education & Learning
  - `health`: Healthcare & Wellness
  - `social-security`: Social Welfare & Security
  - `women-child`: Women & Child Development
  - `employment-skills`: Employment, Skills & Livelihood
  - `housing`: Housing & Urban Development
  - `finance`: Banking, Financial Services & Insurance
  - `business`: Business & Entrepreneurship
  - `energy`: Energy & Environment
  - `transport`: Transport & Infrastructure
  - `digital-services`: Digital Services & IT
  - `sports-culture`: Sports & Culture
- **Bidirectional Alias Normalization**: Maps legacy identifiers (e.g. `women` $\rightarrow$ `women-child`, `financial` $\rightarrow$ `finance`, `employment` $\rightarrow$ `employment-skills`, `socialWelfare` $\rightarrow$ `social-security`).
- **Relational Matching**: Normalizes category strings, removes special characters, and matches against both `category` and `subcategory` fields without losing curated state schemes.
- **UI Integration**:
  - `HomeScreen`: Dynamically maps 8 prominent categories in the "Explore by Category" carousel with interactive navigation.
  - `SchemesScreen`: Displays category banner card with matching scheme counts and localized descriptions when filtered by category.

### Feature 2: Personalized Relevant Schemes (Authenticated Dashboard)
- **Service**: `lib/services/recommendation_service.dart`
- **Relevance Taxonomy**:
  - `Likely Relevant` (Green): Profile fulfills explicit core criteria (age range, gender, occupation, location/state).
  - `May Be Relevant` (Amber): Core profile matches, but secondary criteria (income limit, land holding, community) require verification.
  - `More Information Required` (Blue): Key attributes missing in user profile to evaluate eligibility.
- **Deterministic Evaluation**: Pure client-side/database-grounded rule engine ensuring consistent, transparent, and auditable outcomes without LLM hallucinations or bias.
- **Explainability**: Every recommendation includes concise bullet points detailing exact matching criteria (e.g., *"Matched for Farmer in Madhya Pradesh (Age 35)"*).
- **Guest Protection**: Completely hidden for guest sessions (`isGuest == true`), prompting guests to sign in or complete their profile.

### Feature 3: Official Document Reference Layouts & Full-Screen Zoom
- **Model & Widget**: `lib/models/document_info_model.dart`, `lib/widgets/document_specimen_viewer.dart`
- **Primary Documents**:
  - **Aadhaar Card**: UIDAI format layout with 3-block 12-digit masked layout (`XXXX XXXX 1234`), father/husband guardian line, DOB format (`DD/MM/YYYY`), secure QR code placeholder, and link to [uidai.gov.in](https://uidai.gov.in).
  - **Samagra ID**: Madhya Pradesh SSSM format with 9-digit Member ID, 8-digit Family ID, e-KYC status indicator, and link to [samagra.gov.in](https://samagra.gov.in).
- **Interactive Full-Screen Zoom**: Built-in modal dialog featuring `InteractiveViewer` with `minScale: 0.8` and `maxScale: 4.0`, double-tap reset, and smooth pinch-to-zoom for checking sample document parameters.
- **Educational Compliance**: Clearly disclaimed educational specimens without fabricating official state emblems or seals.

### Feature 4: Verified YouTube Application Tutorials
- **Model & Service**: `lib/models/youtube_tutorial_model.dart`, `lib/services/youtube_tutorial_service.dart`
- **Verified Mappings**: Pre-mapped verified application walkthroughs for flagship schemes:
  - PM-KISAN Samman Nidhi
  - PM Jan Arogya Yojana (Ayushman Bharat)
  - PM Awas Yojana - Gramin
  - PM Ujjwala Yojana
  - MP Ladli Behna Yojana
  - PM SVANidhi (Street Vendors)
  - PM Vishwakarma Yojana
  - Sukanya Samriddhi Yojana
- **UI Integration**: `lib/screens/scheme_detail_screen.dart` renders high-res thumbnail card with play button, channel attribution, duration, and one-click launch via `url_launcher`.
- **Fallback Notice**: Schemes without verified tutorials render a clean informational banner: *"No verified application tutorial is currently available for this scheme."* with an icon rather than breaking layout.

### Feature 5: Secure Cloudinary Document Vault
- **Backend Service & Router**: `backend/app/services/cloudinary_service.py`, `backend/app/routers/documents.py`
- **Security & Authorization**:
  - Authenticated via Firebase ID Bearer tokens (`get_current_user`).
  - Guests and unauthenticated requests are blocked with HTTP 401 Unauthorized.
  - Documents stored with `type="private"` or `type="authenticated"` in Cloudinary.
  - Zero exposure of Cloudinary API secrets in client code.
- **Signed URL Delivery**:
  - Generates time-bounded HMAC-SHA1 signed delivery URLs (`sign_url=True`) with 1-hour expiration TTL.
  - Prevents permanent direct asset leakage.
- **Multi-Tenant Isolation**:
  - Enforces Firestore ownership checks (`doc.user_id == current_user.uid`).
  - Cross-tenant retrieval and deletion attempts return HTTP 403 Forbidden.
- **Frontend Lifecycle**: `HomeScreen` clears document cache and active session on logout.

---

## 3. Verification & Test Matrix

| Component | Test File | Tests Passed | Status |
|---|---|---|---|
| Explore by Category | `test/category_exploration_test.dart` | 6 / 6 | Passed |
| Personalized Recommendations | `test/personalized_recommendations_test.dart` | 3 / 3 | Passed |
| Document Specimen & Zoom | `test/official_document_references_test.dart` | 3 / 3 | Passed |
| YouTube Tutorials | `test/youtube_tutorials_test.dart` | 5 / 5 | Passed |
| Backend Cloudinary Vault | `backend/tests/test_cloudinary_vault.py` | 5 / 5 | Passed |
| Entire Flutter Suite | `flutter test --no-pub` | 132 / 132 | Passed |
| Entire Pytest Suite | `pytest backend/tests/` | 86 / 86 | Passed |
| Static Code Analysis | `flutter analyze --no-pub` | 0 Issues | Passed |

---

## 4. Modified & Created Artifacts

### Frontend (Flutter)
- `lib/services/category_service.dart` *(New)*: Canonical categories, normalization, and relational matching.
- `lib/services/recommendation_service.dart` *(New)*: Deterministic scheme recommendation engine.
- `lib/models/youtube_tutorial_model.dart` *(New)*: Data model for application tutorials.
- `lib/services/youtube_tutorial_service.dart` *(New)*: Curated registry of verified tutorials.
- `lib/models/document_info_model.dart`: Added official portal URLs and reference asset paths.
- `lib/models/user_document_model.dart`: Added `publicId` and `signedUrl` fields.
- `lib/providers/scheme_provider.dart`: Integrated category service matching.
- `lib/services/scheme_data_service.dart`: Enhanced category filtering supporting catalogue exploration.
- `lib/widgets/document_specimen_viewer.dart`: Aadhaar and Samagra authentic specimen cards + full-screen zoom dialog.
- `lib/screens/home_screen.dart`: Category exploration carousel and personalized recommendations carousel.
- `lib/screens/schemes_screen.dart`: Category banner and filtered catalogue view.
- `lib/screens/scheme_detail_screen.dart`: Video tutorial integration in How to Apply tab.

### Backend (FastAPI / Python)
- `backend/app/config.py`: Added Cloudinary configuration settings.
- `backend/app/services/cloudinary_service.py` *(New)*: Private asset upload, signed URL delivery, and asset deletion.
- `backend/app/routers/documents.py` *(New)*: Secure REST endpoints (`/api/documents/upload`, `/api/documents/my-vault`, `/api/documents/{id}`).
- `backend/app/main.py`: Registered documents router with application.
- `backend/requirements.txt`: Added `cloudinary` and `python-multipart`.

