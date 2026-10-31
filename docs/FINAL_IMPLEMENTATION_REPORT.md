# SAHAY (सहाय) — Final Master Implementation Audit & Execution Report

## Phase 0: Complete Repository Audit & Implementation Map

Date: October 31, 2026
Auditor: Senior Engineering Coordination Team (Architect, Flutter, Backend, Security, AI/ML, QA)

---

### 1. Executive Summary

This audit assesses the current state of the SAHAY codebase across all components: Flutter frontend, FastAPI backend, LangGraph multi-agent orchestration, Firestore/Firebase Storage, and security rules. 

Overall State:
- Core Foundation, Localization (8 languages), Design System (AppColors, Material 3): STABLE
- Flutter Test Suite: 101/101 Passing
- Backend Pytest Suite: 66/66 Passing
- Static Analysis: 0 warnings, 0 errors

---

### 2. File-by-File Feature Classification Matrix

| Module / Screen / Service | File Path | Status | Identified Defect / Gap |
|---|---|---|---|
| **Auth Navigation & Gate** | `lib/screens/auth/auth_gate.dart` | PARTIALLY IMPLEMENTED | Correctly determines root screen based on auth/guest state, but does not intercept manual Navigator pushes from child routes. |
| **Welcome Screen** | `lib/screens/welcome_screen.dart` | IMPLEMENTED | Provides Login, Sign Up, and Guest navigation cleanly with 8-language localization. |
| **Login / Signup Screens** | `lib/screens/auth/login_screen.dart`, `signup_screen.dart` | IMPLEMENTED | Firebase Auth integration with email/password and Google Sign-In. |
| **End Session & Clear** | `lib/widgets/privacy_dialog.dart:118` | **DEFECTIVE** | `PrivacyDialog` explicitly navigates to `HomeScreen` instead of `WelcomeScreen`. Does not clear navigation stack. |
| **Log Out Flow** | `lib/screens/home_screen.dart:331` | **DEFECTIVE** | Signs out via `auth.signOut()`, but leaves `HomeScreen` mounted without clearing stack or routing to `WelcomeScreen`. |
| **Home Screen Layout** | `lib/screens/home_screen.dart` | PARTIALLY IMPLEMENTED | Check Eligibility block is placed in the upper/middle section instead of bottom; Document Vault card is inside modal instead of prominent card below Search. |
| **Scheme Catalog Retrieval** | `lib/services/scheme_data_service.dart`, `home_screen.dart:43` | **DEFECTIVE** | `SchemeDataService` hardcodes only 6 curated schemes. `HomeScreen` calls `loadSchemes(SchemeDataService())`, ignoring the 100 schemes in `data/schemes_seed/`. |
| **Document Vault UI** | `lib/screens/my_documents_screen.dart` | PARTIALLY IMPLEMENTED | Full UI and categories present, but uses simulated sliders for file sizes instead of real device file selection and storage uploads. |
| **Document Vault Service** | `lib/services/document_service.dart` | PARTIALLY IMPLEMENTED | Handles Firestore metadata and memory cache; lacks direct integration with private Firebase Storage file upload/deletion. |
| **Document State Integration** | `lib/screens/scheme_detail_screen.dart` | PARTIALLY IMPLEMENTED | Matches vault documents against scheme requirements, but needs explicit 3-state distinction (`uploaded` vs `user_confirmed` vs `verified`). |
| **Edge Cases & Precautions** | `lib/screens/scheme_detail_screen.dart` | **NOT IMPLEMENTED** | Overview tab contains description and benefits, but lacks the dedicated "Edge Cases & Important Precautions" section. |
| **YouTube Video Guide** | `lib/screens/scheme_detail_screen.dart` | **NOT IMPLEMENTED** | How to Apply tab contains text and "Apply with SAHAY", but lacks "Video Guide – How to Apply" with verified tutorial discovery and fallback. |
| **AI Scheme Discovery** | `backend/app/routers/discovery.py`, `agents/discovery_agent.py` | IMPLEMENTED | Hybrid discovery using Tavily, LangGraph, Ollama, and trust scoring. |
| **Application Assistant** | `lib/screens/application/*`, `backend/app/routers/applications.py` | IMPLEMENTED | Multi-agent application filling, OCR parsing, and guided review. |
| **Firestore Security Rules** | `firestore.rules` | IMPLEMENTED | Default-deny, owner-only read/write on `users/{userId}/**`, read-only on `schemes/{schemeId}`. |
| **Storage Security Rules** | `storage.rules` | IMPLEMENTED | Owner-only read/write on `users/{userId}/**`. |

---

### 3. Root Cause Analysis of Primary Defects

1. **End Session & Clear Bug**:
   - Location: `lib/widgets/privacy_dialog.dart:118`
   - Code: `Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);`
   - Cause: Explicit route target was mistakenly coded as `HomeScreen()` instead of `WelcomeScreen()`. In-memory state was wiped, but the user was dropped right back into a fresh `HomeScreen` rather than the public onboarding/welcome screen.
2. **Log Out Bug**:
   - Location: `lib/screens/home_screen.dart:329-332`
   - Code: `Navigator.of(ctx).pop(); await auth.signOut();`
   - Cause: Popping the bottom sheet modal closed the sheet, leaving `HomeScreen` displayed. No route transition or `pushAndRemoveUntil` was executed to return to `WelcomeScreen()`.
3. **Guest Mode Scheme Limit (6 schemes instead of 100)**:
   - Location: `lib/screens/home_screen.dart:43` & `lib/services/scheme_data_service.dart:70`
   - Cause: `home_screen.dart` loads schemes using `SchemeDataService()`, which only contained 6 hardcoded schemes (`pm-kisan`, `pm-jay`, `pmay-g`, `pmuy`, `pmss`, `ladli-behna`). The 100 seed schemes stored in `data/schemes_seed/*.json` and backend database are never loaded into Flutter's `SchemeDataService`.

---

### 4. Implementation Plan & Phases

- **Phase 1**: Fix Authentication & Session clearing bugs (End Session & Clear, Log Out).
- **Phase 2**: Document Vault: Implement native file picking, private Firebase Storage upload, deletion, and lifecycle handling.
- **Phase 3**: Home Screen restructuring (Check Eligibility to bottom, Document Vault card below search for auth users, hide for guests) & full 100-scheme catalogue loading in guest mode.
- **Phase 4**: Intelligent AI Scheme Discovery refinements (status badges: VERIFIED, PARTIALLY VERIFIED, UNVERIFIED).
- **Phase 5**: Add "Edge Cases & Important Precautions" section to Scheme Detail Overview tab.
- **Phase 6**: Document Classification & Frequency Analysis across all 100 schemes (checkpoint before photograph requests).
- **Phase 7**: YouTube Video Guide in How to Apply tab with verified channels and fallback.
- **Phase 8**: Document State and Checklist Integration (`uploaded`, `user_confirmed`, `verified`).
- **Phase 9**: UI/UX & Localization verification across 8 languages.
- **Phase 10**: Firebase Security & Data Integrity audit.
- **Phase 11**: Full Regression Testing across Flutter and Backend.
- **Phase 12**: Complete final documentation in `docs/`.

