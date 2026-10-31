# SAHAY (सहाय) — Platform Enhancement & Bug Fix Report
## Additional Document Naming, Intelligent Search, Persistent Onboarding & Guest Navigation

**Date:** November 1, 2026  
**System:** SAHAY (सहाय) AI-Powered Citizen Assistance Platform  
**Authors:** Senior Full-Stack & Systems Architecture Engineering Team  

---

## 1. Executive Summary

This engineering sprint addressed critical user experience, search intelligence, session lifecycle, and responsive layout issues across the SAHAY Flutter client and Python FastAPI backend:

1. **63-Pixel RenderFlex Overflow Elimination**: Resolved layout bounds overflows on 360px mobile viewports within `HomeScreen` (Document Vault card & Recommended Schemes title row) and `DocumentSpecimenViewer` (data row truncation).
2. **Phase 1 — Custom Document Naming in Vault**: Implemented dynamic custom document naming for `additional_document` uploads. The generic label is replaced across metadata, Firestore, and the UI with the user's specific document name (e.g., "Birth Certificate", "Medical Fitness Certificate").
3. **Phase 2 — Multi-Tier Intelligent Scheme Search**: Built a resilient, 5-layer search engine supporting colloquial aliases, Hindi/Hinglish queries, acronyms, token overlap, and fuzzy typo matching (Damerau-Levenshtein distance) across both Flutter (`SchemeSearchService`) and FastAPI (`db_interface.py`).
4. **Phase 3 — Persistent User Onboarding**: Resolved the infinite onboarding loop by storing permanent flags (`onboardingCompleted`, `onboardingCompletedAt`) in `UserModel`, eliminating premature unauthenticated stub emissions in `AuthRepository.currentUserProfileStream`, and pre-populating questionnaires from saved user profiles.
5. **Phase 4 — Guest Navigation & Session Clearing**: Restructured navigation routing across `AuthGate`, `HomeScreen`, `WelcomeScreen`, `LoginScreen`, and `SignUpScreen`. Guaranteed clean memory purging on logout/session end (`clearSession()`, `clear()`, `clearAllAnswers()`), preventing cross-user data leakage and enabling frictionless guest access.

---

## 2. Root Cause Analysis & Architectural Fixes

### A. 63-Pixel Overflow & Document View Overflow
* **Root Cause:**
  - `HomeScreen._buildDocumentVaultCard`: Nested an unconstrained `Row` inside an `Expanded` column containing `Text('Document Vault')` (~115px) + `SizedBox(8)` + `Container('Private & Encrypted')` (~90px) = 213px inside a ~150px allocated box on 360px viewports $\rightarrow$ 63px overflow.
  - `DocumentSpecimenViewer._buildDataRow`: Rigid `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)` with unconstrained child labels and values (e.g., `'Category / श्रेणी:'` + `'PHH / BPL (Priority Household)'`) inside a nested card $\rightarrow$ 67px overflow.
* **Resolution:**
  - Replaced rigid `Row` in `_buildDocumentVaultCard` with `Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 4)`.
  - Wrapped `Recommended Schemes for You` title row in `Expanded` with `Flexible` text truncation.
  - In `DocumentSpecimenViewer`, refactored `_buildDataRow` into `Row(children: [Expanded(flex: 5, child: Text(label)), Flexible(flex: 6, child: Text(value, textAlign: TextAlign.end))])` and wrapped masked Aadhaar numbers in `FittedBox(fit: BoxFit.scaleDown)`.

### B. Custom Document Name for Additional Documents
* **Root Cause:**
  - `MyDocumentsScreen._showUploadDialog` had a static dropdown containing predefined documents plus `additional_document`. When `additional_document` was selected, the upload flow passed `'Additional Document'` as `documentName`, permanently labelling any supplementary document with that generic title.
* **Resolution:**
  - Added dynamic `TextFormField` for "Document Name *" (`दस्तावेज़ का नाम *`) when `selectedType == 'additional_document' || selectedType == 'other_document'`.
  - Enforced strict validation preventing empty or whitespace-only names.
  - Added `displayName` persistence to `UserDocumentModel.toMap()` and `.fromMap()`, mapping user-specified names directly to the Cloudinary vault metadata and Firestore.
  - Updated `UserDocumentProvider.uploadDocument` to ensure custom documents do not overwrite existing ones.

### C. Multi-Tier Intelligent Search
* **Root Cause:**
  - Search relied on basic `.contains()` substring matching on English title and ministry fields. Searches with typos (`laadli`, `kisaan`), Hindi Devnagari (`लाडली बहना`), acronyms (`PMUY`, `PM-JAY`), or multi-word user intent (`farmer cash assistance`) returned zero results.
* **Resolution:**
  - Created `lib/services/scheme_search_service.dart` featuring:
    1. **Text Normalization**: Lowercase conversion, punctuation stripping, diacritics removal, whitespace collapse.
    2. **Curated Alias Dictionary**: Indexed ~25 popular schemes with acronyms, colloquial Hindi/Hinglish terms, and scheme IDs.
    3. **Damerau-Levenshtein Fuzzy Metric**: Error tolerance for edit distances $\le 2$ on words $\ge 4$ characters.
    4. **Scoring Hierarchy**: Exact match (1000) $\rightarrow$ Exact alias (850) $\rightarrow$ Title substring (650) $\rightarrow$ Token overlap (520) $\rightarrow$ Fuzzy alias/title (260) $\rightarrow$ Semantic/doc keywords (120-200).
    5. **Python Backend Parity**: Mirror scoring algorithm added to `backend/app/database/db_interface.py`.
    6. **UI Debouncing**: 250ms debouncer added to `SchemesScreen` search input.

### D. Persistent User Onboarding Loop
* **Root Cause:**
  - In `AuthRepository.currentUserProfileStream`, every Firebase auth state change immediately yielded a stub `UserModel` with `profileComplete: false` before Firestore could query the user's document.
  - `AuthProvider` set `_currentUser = stub; _isLoading = false; notifyListeners();`.
  - `AuthGate` rebuilt immediately and saw `isAuthenticated: true` and `isProfileComplete: false`, pushing `ProfileSetupScreen` even for users who had completed onboarding months prior!
* **Resolution:**
  - Added `onboardingCompleted` (bool) and `onboardingCompletedAt` (DateTime) to `UserModel` with backwards-compatible deserialization (`isProfComplete => onboardingCompleted`).
  - Removed premature `yield stub` from `currentUserProfileStream`, awaiting the first snapshot from `_userService.profileStream(user.uid)`.
  - Updated `AuthProvider.isProfileComplete` getter: `(_currentUser?.profileComplete ?? false) || (_currentUser?.onboardingCompleted ?? false)`.
  - In `QuestionnaireScreen`, pre-populated profile using `userProfile.populateFromUser(user)` and persisted questionnaire completions directly to the user's profile with `onboardingCompleted = true`.
  - Added an "Edit Profile & Details" (`प्रोफ़ाइल एवं विवरण संपादित करें`) option inside `HomeScreen` profile sheet for editing without re-triggering an onboarding loop.

### E. Guest Navigation and Multi-User Isolation
* **Root Cause:**
  - On logout, `HomeScreen` called `nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false)`. This removed `AuthGate` from the navigation root.
  - On `WelcomeScreen`, pressing "Continue as Guest" only called `auth.enterGuestMode()`, which notified `AuthProvider`, but because `AuthGate` was no longer in the widget hierarchy, nothing navigated to `HomeScreen`!
  - Previous user documents in `UserDocumentProvider` and application draft sessions in `ApplicationProvider` lingered in memory across account switches.
* **Resolution:**
  - Changed logout navigation in `HomeScreen` and `PrivacyDialog` to push `const AuthGate()`.
  - Updated `WelcomeScreen` "Continue as Guest" to explicitly navigate to `const AuthGate()`.
  - Updated `LoginScreen` and `SignUpScreen` to push `const AuthGate()` on success.
  - Added `clearSession()` to `ApplicationProvider`.
  - On logout, orchestrated complete cache purge: `UserDocumentProvider.clear()`, `ApplicationProvider.clearSession()`, `UserProfileProvider.clearAllAnswers()`, and `PrivacyService.clearSessionData()`.

---

## 3. Verification & Evidence

### Test Execution Results

#### 1. Flutter Unit & Widget Test Suite
Executed command:
```bash
flutter test test/overflow_regression_test.dart test/phase1_custom_document_name_test.dart test/phase2_intelligent_search_test.dart test/phase3_persistent_onboarding_test.dart test/phase4_guest_navigation_test.dart --no-pub
```
**Result:** `00:01 +22: All tests passed!` (22/22 tests passing)

Detailed test breakdown:
- **`overflow_regression_test.dart` (3 tests)**:
  - `Document Vault Card and Recommended Header in 360px width renders without overflow` $\rightarrow$ **PASS**
  - `DocumentSpecimenViewer renders ration_card & samagra_id without overflow in 320px width` $\rightarrow$ **PASS**
  - `ExpandableDocumentCard renders and expands without overflow in narrow 320px constraint` $\rightarrow$ **PASS**
- **`phase1_custom_document_name_test.dart` (4 tests)**:
  - Custom `displayName` serialization & deserialization in `UserDocumentModel` $\rightarrow$ **PASS**
  - Fallback to catalogue name when custom name is absent $\rightarrow$ **PASS**
  - `DocumentCatalogueService` recognition of `additional_document` $\rightarrow$ **PASS**
  - Custom name validation rejecting empty or whitespace-only inputs $\rightarrow$ **PASS**
- **`phase2_intelligent_search_test.dart` (6 tests)**:
  - Empty or blank query handling $\rightarrow$ **PASS**
  - Partial matches (`kisan`, `awas`, `ayushman`, `ujjwala`) $\rightarrow$ **PASS**
  - Colloquial alias & acronym matches (`ladli behena yojna`, `pm kisan`, `sukanya`, `svanidhi`, `pm vishwakarma`) $\rightarrow$ **PASS**
  - Hindi Devnagari queries (`लाडली बहना`, `पीएम किसान`, `आयुष्मान भारत`) $\rightarrow$ **PASS**
  - Typo tolerance with fuzzy matching (`laadli behna`, `kisaan`, `ayusman bharat`, `ujwala yojana`) $\rightarrow$ **PASS**
  - Multi-word intent queries (`farmer cash assistance`, `lpg cylinder`, `scholarship for girls`) $\rightarrow$ **PASS**
- **`phase3_persistent_onboarding_test.dart` (4 tests)**:
  - `UserModel` initialization and serialization of `onboardingCompleted` $\rightarrow$ **PASS**
  - Legacy `UserModel` backwards compatibility mapping $\rightarrow$ **PASS**
  - `AuthProvider.isProfileComplete` truth table verification $\rightarrow$ **PASS**
  - `UserProfileProvider.populateFromUser` demographic answers hydration $\rightarrow$ **PASS**
- **`phase4_guest_navigation_test.dart` (5 tests)**:
  - Guest mode entry and exit flags $\rightarrow$ **PASS**
  - `UserDocumentProvider.clear()` reset verification $\rightarrow$ **PASS**
  - `ApplicationProvider.clearSession()` reset verification $\rightarrow$ **PASS**
  - Profile answers wiping on session end $\rightarrow$ **PASS**
  - Full account switch lifecycle: User A logout $\rightarrow$ cache wipe $\rightarrow$ Guest navigation $\rightarrow$ User B login $\rightarrow$ **PASS**

#### 2. Static Analysis
Executed command:
```bash
flutter analyze --no-pub
```
**Result:** `No issues found! (ran in 2.0s)`

#### 3. Backend Pytest Suite
Executed command:
```bash
PYTHONPATH=. backend/.venv311/bin/pytest backend/tests/
```
**Result:** `87 passed in 18.15s` (87/87 tests passing, 100% test pass rate including Cloudinary vault, application assistant, archetype population, auth security, discovery, and full system integration).

---

## 4. File Modification Index

| File Path | Description of Changes |
| :--- | :--- |
| `lib/models/user_model.dart` | Added `onboardingCompleted` and `onboardingCompletedAt` fields, updated `toMap`, `fromMap`, and `copyWith` with backwards compatibility. |
| `lib/models/user_document_model.dart` | Added `displayName` and `resolvedDisplayName` getters, updated `toMap` and `fromMap`. |
| `lib/repositories/auth_repository.dart` | Fixed race condition in `currentUserProfileStream` by eliminating premature unauthenticated stub emission. |
| `lib/providers/auth_provider.dart` | Updated `isProfileComplete` getter, added onboarding flag preservation in `_initAuthListener` and `updateProfile`. |
| `lib/providers/application_provider.dart` | Added `clearSession()` method to wipe active application session state on logout. |
| `lib/services/scheme_search_service.dart` | Implemented multi-tier search service with normalization, alias mapping, Damerau-Levenshtein fuzzy matching, and ranking. |
| `lib/screens/my_documents_screen.dart` | Added mandatory custom document name input field and validation for `additional_document`. |
| `lib/screens/profile/profile_setup_screen.dart` | Persisted `onboardingCompleted: true` and streamlined routing back to `AuthGate`. |
| `lib/screens/questionnaire_screen.dart` | Hydrated answers from authenticated user profile and marked onboarding complete on questionnaire submission. |
| `lib/screens/welcome_screen.dart` | Updated "Continue as Guest" button to navigate cleanly to `AuthGate`. |
| `lib/screens/home_screen.dart` | Fixed 63px overflow in Document Vault card and Recommended title row; added "Edit Profile & Details" button; routed logout through `AuthGate`. |
| `lib/widgets/document_specimen_viewer.dart` | Fixed 67px overflow in specimen details by making rows flexible and wrapping long data values. |
| `lib/widgets/expandable_document_card.dart` | Added overflow protection for action buttons and description blocks. |
| `lib/widgets/privacy_dialog.dart` | Integrated `UserDocumentProvider.clear()` and `ApplicationProvider.clearSession()` on session clearing. |
| `backend/app/database/db_interface.py` | Added mirror multi-tier search aliases and ranking algorithms to FastAPI backend. |
| `test/overflow_regression_test.dart` | Regression tests verifying 360px and 320px layout constraints without RenderFlex overflow. |
| `test/phase1_custom_document_name_test.dart` | Unit tests for additional document custom naming, validation, and serialization. |
| `test/phase2_intelligent_search_test.dart` | Integration tests verifying partial names, colloquial aliases, Hindi queries, typos, and multi-word intent. |
| `test/phase3_persistent_onboarding_test.dart` | Unit tests for persistent onboarding completion and profile state preservation. |
| `test/phase4_guest_navigation_test.dart` | Unit and lifecycle tests for guest mode navigation, cache clearing, and account switching. |

---

## 5. Security & Compatibility Assurance

1. **Vault Data Isolation:** Every document operation explicitly scopes to the authenticated user's UID (`vault/users/{uid}/documents`). Switching accounts or entering guest mode immediately purges cached documents from memory.
2. **Backward Compatibility:** All existing Firestore user documents lacking the new `onboardingCompleted` key are automatically recognized as complete if `profileComplete == true`, preventing regression for existing users.
3. **No Credential Exposure:** Cloudinary API keys and Firebase admin credentials remain strictly encapsulated within server-side environments; signed URLs with time-limited expiration are used for private access.

