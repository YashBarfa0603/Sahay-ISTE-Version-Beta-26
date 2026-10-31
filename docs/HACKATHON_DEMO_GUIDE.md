# SAHAY (सहाय) — Hackathon Demonstration Guide & Script

**Event:** AI for Bharat / Hackathon Demonstration  
**Platform:** SAHAY — Multilingual Citizen Government Scheme Discovery & Assistance  
**Target Audience:** Hackathon Judges, Civic Tech Evaluators, Senior Architects  

---

## 1. Ten Citizen Demonstration Profiles

These profiles represent real Indian citizen personas designed to showcase deterministic screening, transparency, and boundary handling:

| Profile # | Persona Name | Key Attributes | Target Scheme | Expected Screening Outcome |
|:---:|:---|:---|:---|:---|
| **1** | **Ramesh Patel** (Farmer) | Small farmer, owns 1.5 ha cultivable land, has bank account, no income tax, no government job | **PM-KISAN** | **May Qualify** (Demonstrates 2-hectare cap abolition and statutory exclusion clearance) |
| **2** | **Shanti Devi** (Senior Citizen) | Age 72, female, income ₹1,20,000, no BPL ration card | **Ayushman Bharat PM-JAY** | **May Qualify** (Demonstrates **Ayushman Vay Vandana** universal age 70+ entitlement) |
| **3** | **Birju Kol** (Rural Houseless) | Rural resident, living in kutcha hut, daily wage worker, no motorized vehicle | **PMAY-G** | **May Qualify** (Requires Gram Sabha / Awaas+ list verification) |
| **4** | **Sunita Yadav** (Homemaker) | Female, age 25, OBC category, no existing LPG connection in household | **PM Ujjwala 2.0** | **May Qualify** (Demonstrates vulnerable household criteria and no-LPG rule) |
| **5** | **Amit Singh** (Student Ward) | Son of deceased Ex-Serviceman, scored 74% in Class 12, enrolled in B.Tech | **PMSS** | **May Qualify** (Demonstrates ESM dependent status + professional course + $\ge 60\%$ marks) |
| **6** | **Anita Verma** (MP Resident) | Woman, age 30, resident of Bhopal (MP), married, family income ₹1.5L, no 4-wheeler, no tax | **MP Ladli Behna** | **May Qualify** (Demonstrates state filter + marital status + statutory exclusion verification) |
| **7** | **Kalu Ram** (Informal Laborer) | Daily wage laborer, unknown exact annual income, estimated ₹8,000/month | **Assistance Service** | **Needs Verification** (Demonstrates income bounds [₹96,000 – ₹1,20,000] and conservative guidance) |
| **8** | **Vikram Sharma** (Conflicted Profile) | Declares age 14 + married status, or ₹8L income + BPL card | **Question Engine** | **Contradiction Detected** (Halts flow, requests bilingual clarification, prevents false decision) |
| **9** | **Pooja & Rekha** (Shared Device) | Citizen A (Pooja) views results, taps "End Session"; Citizen B (Rekha) opens phone | **Privacy Engine** | **Zero-Retention Reset** (Proves Citizen B cannot see Citizen A's answers or results) |
| **10** | **Mahesh Lodhi** (Unrecorded Lease) | Farmer cultivating unrecorded tenancy land without revenue mutation | **Human Assistance** | **Needs Human Verification** (Generates referral package to local Patwari and CSC) |

---

## 2. Live 17-Step Demonstration Flow (5-Minute Pitch)

```
00:00 - 00:30 | 1. Open SAHAY. Show Namaste greeting. Tap Language Toggle (Switch from English to Hindi).
00:30 - 00:50 | 2. Highlight Problem Statement: 700+ government schemes exist, but citizens don't know what they qualify for or why.
00:50 - 01:10 | 3. Enter as Guest (Show zero-barrier access; no mandatory phone number or signup required).
01:10 - 01:40 | 4. Search via Voice (Tap mic, say: "किसान योजना" / "Farmer scheme").
01:40 - 02:10 | 5. Show Hybrid Discovery (Curated catalogue match displayed instantly).
02:10 - 02:45 | 6. Start Adaptive Questionnaire (Answer: Occupation = Farmer, Land = 1.5 hectares).
02:45 - 03:15 | 7. Show Statutory Exclusion Questions (Income tax paid = No, Government employee = No).
03:15 - 03:45 | 8. View Result: "PM Kisan Samman Nidhi — May Qualify".
03:45 - 04:10 | 9. Tap Scheme Card: Review Exact Operational Rule & Official Source Link (`pmkisan.gov.in`).
04:10 - 04:30 | 10. Generate Document Checklist (Presents Land Record Khatauni, Aadhaar, Bank Passbook).
04:30 - 04:45 | 11. Tap "Download / Share PDF" (Opens native Share Sheet in-memory).
04:45 - 05:00 | 12. Tap "End Session" (Show instant data purge for next user at the CSC).
```

---

## 3. The Five Extra-Credit Demonstration Scenarios

### Scenario 1 — Unknown Household Income
- **Action:** In the questionnaire, when asked about annual income, select "I don't know / Daily wage".
- **Agent Behavior:** The `IncomeAssistanceAgent` and deterministic `IncomeEstimatorService` activate.
- **Display:** Displays a conservative annual estimate (e.g. ₹72,000 – ₹96,000) based on days worked and seasonality.
- **Judge Takeaway:** Never fabricates an exact figure; states explicit assumptions and recommends income certificate from the Tehsildar.

### Scenario 2 — Conflicting Answers & Halting Behavior
- **Action:** Enter Age = 14 and Marital Status = Married, OR Occupation = Government Employee and Government Employee Exclusion = No.
- **Engine Behavior:** `QuestionEngine.detectContradictions()` catches the conflict.
- **Display:** A prominent banner in Hindi/English appears: *"Under statutory welfare guidelines, applicant-head profiles require age 18+. Please review your age or marital status answer."*
- **Judge Takeaway:** Questionnaire halts immediately on blocking conflicts, preventing bogus eligibility decisions.

### Scenario 3 — Shared-Device Safety (CSC / Village Panchayat)
- **Action:** Complete an assessment as Citizen A. View results. Tap "End Session / Clear Data". Hand phone to Judge (acting as Citizen B).
- **Inspection:** Open assessment or profile. Every field is blank. In-memory RAM cache is empty.
- **Judge Takeaway:** Zero-retention architecture protects vulnerable citizens' financial and social privacy on shared phones.

### Scenario 4 — Practical Guidance After "May Qualify"
- **Action:** Open PM-KISAN or Ladli Behna result.
- **Display:**
  1. Complete Document Checklist (Aadhaar, Samagra ID, DBT Bank Passbook).
  2. Direct link to official application portal (`pmkisan.gov.in`).
  3. CSC Jan Seva Kendra Locator with official helpline `1800-121-3468` and `locator.csccloud.in`.
- **Judge Takeaway:** Bridges the gap between eligibility screening and actual administrative benefit delivery.

### Scenario 5 — Adding a Ninth Language
- **Action:** Demonstrate `lib/l10n/` and `app_en.arb`.
- **Explanation to Judges:** Show how adding Telugu or Punjabi requires only dropping a new localized `.arb` file into the localization directory. The engine, widgets, and state management consume keys dynamically without modifying core UI logic.

---

## 4. Live Demo Reliability Safeguards

- **Backend Startup:**
  ```bash
  cd /Users/yash/PROJECTS/MANIT/sahay/backend
  source .venv311/bin/activate
  uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
  ```
- **Local Fallback:** If internet or Tavily drops, `BackendSchemeService` seamlessly falls back to the preloaded local catalogue of verified schemes with 0 errors.
- **Offline Safe Mode:** All 6 schemes and deterministic income models execute completely offline on-device.

