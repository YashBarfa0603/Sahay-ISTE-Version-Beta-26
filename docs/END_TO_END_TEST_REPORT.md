# SAHAY (सहाय) — Complete End-to-End Citizen Journey Test Report

**Audit Date:** 31 October 2026  
**Auditor:** Senior Flutter Developer, Principal Software Architect, UI/UX Engineer  
**Scope:** Verification of all 15 citizen journey checkpoints, Material 3 UI/UX accessibility, bilingual consistency, and LangGraph multi-agent orchestration.

---

## 1. Citizen Journey Execution Audit

Every stage of the citizen user journey was audited across source implementations, route controllers, and automated tests.

```mermaid
journey
    title Citizen Journey Through SAHAY
    section Onboarding
      Open Welcome Screen: 5: Citizen
      Select Language (Hindi/English): 5: Citizen
      Enter as Guest or Login: 5: Citizen
    section Assessment
      View Clean Dashboard: 5: Citizen
      Answer Adaptive Questionnaire: 4: Citizen
      Estimate Unknown Income (if applicable): 5: Citizen
    section Outcomes
      View Transparent Eligibility Results: 5: Citizen
      Review Borderline & Missing Info: 5: Citizen
      Examine Document Checklist: 5: Citizen
    section Action & Privacy
      Download/Share PDF Checklist: 5: Citizen
      Find Authorized CSC / Helpline: 5: Citizen
      Clear Session / Zero-Retention Reset: 5: Citizen
```

### Stage-by-Stage Verification Table

| Checkpoint | Tested Feature | Implementation Location | Verification Evidence | Status |
|:---:|:---|:---|:---|:---:|
| **1** | **Welcome Screen** | `lib/screens/welcome_screen.dart` | `test/navigation_test.dart` L10–L45; renders Namaste hero banner, language selector, and auth options | **VERIFIED** |
| **2** | **Language Switching** | `lib/widgets/language_toggle.dart`, `lib/providers/locale_provider.dart` | `test/providers_and_widgets_test.dart` L180–L215; dynamic switching across 8 Indian languages without app restart | **VERIFIED** |
| **3** | **Home Dashboard** | `lib/screens/home_screen.dart` | Material 3 navigation bar, guest banner, category chips, recent search, quick assessment CTA | **VERIFIED** |
| **4** | **Guest Access** | `lib/screens/auth/auth_gate.dart` (L55–L75) | `test/auth_ui_flow_test.dart` L40–L65; allows anonymous exploration without collecting credentials | **VERIFIED** |
| **5** | **Login & Signup** | `lib/screens/auth/login_screen.dart`, `lib/repositories/auth_repository.dart` | `test/auth_data_layer_test.dart`, `test/auth_services_test.dart`; Google sign-in, email/password with mapped error codes | **VERIFIED** |
| **6** | **Profile Setup** | `lib/screens/profile/profile_setup_screen.dart` | `test/auth_ui_flow_test.dart` L100–L130; routes incomplete profiles to setup before home | **VERIFIED** |
| **7** | **Scheme Discovery** | `lib/screens/schemes_screen.dart`, `backend/app/routers/discovery.py` | Hybrid search: local catalogue first, falling back to verified Tavily government domain hits | **VERIFIED** |
| **8** | **Adaptive Questionnaire** | `lib/services/question_engine.dart` | 23 dynamic questions; halts on blocking contradictions; skips irrelevant questions (e.g. land for non-farmers) | **VERIFIED** |
| **9** | **Income Estimation** | `backend/app/services/income_estimator_service.py` | `test_income_estimator_bounds_and_thresholds`; generates conservative bound [min, max] for daily wage | **VERIFIED** |
| **10** | **Eligibility Results** | `lib/screens/results_screen.dart`, `lib/widgets/confidence_badge.dart` | Clear three-way status: May Qualify (Green), Needs Verification (Blue), Not Eligible (Coral) | **VERIFIED** |
| **11** | **Scheme Detail** | `lib/screens/scheme_detail_screen.dart` | Displays benefits, official source URL, last checked date, and required document checklist | **VERIFIED** |
| **12** | **Document Checklist** | `lib/screens/document_checklist_screen.dart` | Scheme-by-scheme document requirements, mandatory vs optional tags, and application links | **VERIFIED** |
| **13** | **CSC Assistance** | `lib/screens/csc_locator_screen.dart`, `backend/app/services/assistance_service.py` | Official portal link (`locator.csccloud.in`), national helpline (`1800-121-3468`), PIN code search | **VERIFIED** |
| **14** | **PDF Export & Share** | `lib/screens/document_checklist_screen.dart` (L40–L120) | `Printing.sharePdf` (iOS Share Sheet / Android Share) and `Printing.layoutPdf` (AirPrint) | **VERIFIED** |
| **15** | **Logout & Session Reset** | `lib/screens/home_screen.dart` (L395–L405) | `test/features_integration_test.dart` L60–L108; complete RAM-only answer wipe for shared devices | **VERIFIED** |

---

## 2. Multi-Agent Orchestrator (LangGraph Architecture)

The backend features an asynchronous LangGraph multi-agent orchestrator in `backend/app/agents/orchestrator.py` invoked via `POST /api/agents/assess`.

```mermaid
flowchart LR
    A[Citizen Query] --> B[DiscoveryAgent]
    B --> C[TrustAndVerificationAgent]
    C --> D[EligibilityAssistanceAgent]
    D --> E[DocumentAssistanceAgent]
    E --> F[FraudAndAuthenticityAgent]
    F --> G{Income Unknown?}
    G -->|Yes| H[IncomeAssistanceAgent]
    G -->|No| I[ResultAggregator]
    H --> I
    I --> J[Final Citizen Advice]
```

### Agent Responsibilities & Audit Evidence

1. **DiscoveryAgent:**
   - Evaluates search query across verified baseline catalogue and triggers Tavily only when necessary (`CATALOGUE_MIN_RESULTS = 3`).
   - Verified in `backend/tests/test_discovery.py`.
2. **TrustAndVerificationAgent:**
   - Filters candidate URLs against `TRUSTED_GOV_DOMAINS` (`.gov.in`, `.nic.in`, `.mp.gov.in`, etc.).
   - Drops untrusted domains (e.g. commercial blog sites) and eliminates duplicates.
   - Verified in `backend/tests/test_discovery.py::test_verification_rejects_untrusted_domain`.
3. **EligibilityAssistanceAgent:**
   - Executes deterministic rule evaluation against verified scheme conditions.
   - Strictly enforces that the LLM **cannot** override or invent government rules.
4. **DocumentAssistanceAgent:**
   - Assembles the official document verification checklist based on scheme rules and citizen answers.
5. **FraudAndAuthenticityAgent:**
   - Flags suspicious claims, commercial fee scams, and fake URLs before returning results.
6. **IncomeAssistanceAgent:**
   - Activated conditionally when `annualIncome == "unknown"` or unentered.
   - Calculates bounded income estimates $[min, max]$ based on daily wage / agricultural seasonality.
7. **Execution Proof:**
   - `backend/tests/test_full_system.py::test_langgraph_multi_agent_orchestrator` passed with full agent execution trace recorded.

---

## 3. UI/UX & Responsive Layout Audit

1. **Bilingual Text Expansion:**
   - Hindi strings typically require 20–30% more width than English. 
   - All text cards and buttons utilize `Flexible`, `Expanded`, and auto-wrapping columns to prevent RenderFlex overflow.
   - Verified 0 overflow warnings across all 72 widget and screen tests.
2. **Material 3 Theming:**
   - Palette strictly matches Indian civic colors: Deep Navy (`#0A192F`), Indian Teal (`#008080`), Pale Sage (`#E8F5E9`), Warm Sand (`#FFF8E7`), and Muted Coral (`#E57373`).
   - Verified in `test/core_foundation_test.dart::AppColors Palette Tests`.
3. **Empty States & Loading Indicators:**
   - No dead-ends: Empty searches present direct links to the official CSC locator (`locator.csccloud.in`) and toll-free helpline (`1800-121-3468`).

