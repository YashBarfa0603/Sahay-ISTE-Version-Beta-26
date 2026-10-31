# SAHAY (सहाय) — Known Limitations & Future Scope

**Audit Date:** 31 October 2026  
**Auditor:** Principal Software Architect & QA Lead  
**Transparency Principle:** *"Honest reporting of operational boundaries build trust with citizens and evaluators."*  

---

## 1. Known Architectural & Operational Limitations

### 1.1 Inaccessibility of Live Central & State Beneficiary Registries
- **Boundary:** Direct querying of official government beneficiary databases (e.g. SECC 2011 Deprivation List, Awaas+ Rural Housing Register, PM-JAY NHA Beneficiary Database, or Madhya Pradesh Samagra e-KYC Register) requires official government API gateway accreditation, departmental memoranda of understanding (MoUs), and Aadhaar OTP/Biometric consent infrastructure.
- **Mitigation & Posture:** SAHAY acts as a **pre-screening and discovery assistant**, not an issuing authority. When external list verification is required, the application explicitly reports:
  - Verdict: `needsMoreInformation` ("Verification Needed").
  - Explanation: Informs the citizen that formal Gram Sabha or Panchayat verification is required, and directs them to the designated portal or local Common Service Centre (CSC).

### 1.2 Nationwide CSC Directory Completeness
- **Boundary:** India possesses over 550,000 active Common Service Centres (Jan Seva Kendras). Bundling a complete, daily-updating nationwide database inside a mobile client is impractical and would bloat the app binary.
- **Mitigation & Posture:** The local backend includes a verified curated demonstration seed. For live real-world lookups, the UI directly integrates the official Ministry of Electronics & IT portal (`https://locator.csccloud.in/`) and the national toll-free helpline (`1800-121-3468`).

### 1.3 Voice Input & Accent Nuance
- **Boundary:** Mobile speech-to-text accuracy (`speech_to_text`) can degrade in noisy rural environments (e.g. busy village markets, tractor operations) or across deep regional dialectal variants of Hindi (e.g. Bundelkhandi, Malwi, Bagheli).
- **Mitigation & Posture:** All voice inputs populate editable text fields, allowing the citizen or an assisting VLE (Village Level Entrepreneur) to inspect and correct transcribed text before running evaluation.

### 1.4 Dynamic Scheme Discovery vs. Offline Operation
- **Boundary:** The 6 core central and state schemes execute 100% deterministically and offline without internet. However, dynamic AI discovery of newly announced state circulars requires an active internet connection to query the Tavily search engine and Ollama/Qwen LLM extraction pipeline.
- **Mitigation & Posture:** If network connectivity fails, the app automatically falls back to the curated offline catalogue with zero crashes or error dialogs.

### 1.5 Physical iOS Hardware Code Signing
- **Boundary:** Deploying and running on a physical iPhone requires an interactive Apple Developer Team provisioning profile (`DEVELOPMENT_TEAM = 2TKWZMR8ZD`). 
- **Mitigation & Posture:** Headless ARM64 release compilation has been verified (`flutter build ios --no-codesign` passed, 55.9MB Runner.app).

---

## 2. Future Scope & Roadmap

1. **DigiLocker Integration:**
   - Allow citizens to fetch authentic Aadhaar, Land Mutation, and Income Certificates directly from DigiLocker via National API Gateway.
2. **State e-District & UMANG APIs:**
   - Partner with state service delivery gateways (e.g. MP e-District, UP eSathi) to enable one-click scheme application submission directly from SAHAY.
3. **Multimodal Document OCR:**
   - Enable citizens to photograph their physical ration card or land passbook; use on-device OCR (Google ML Kit) to extract eligibility data without typing.
4. **Expansion to 22 Scheduled Languages:**
   - Scale localization beyond the current 8 languages to cover all 22 official Eighth Schedule Indian languages.

