# SAHAY (सहाय) Scheme Catalogue Seed Audit Report

**Generated Date:** 2026-10-31 02:17:58  
**Schema Version:** 2  
**Total Target Schemes:** 100 (60 Central, 15 Madhya Pradesh, 25 Other States)  
**Validation Status:** Passed Automated Catalogue Validation (0 Errors)  

---

## 1. Summary Statistics & Quota Verification

| Metric | Target | Actual Count | Compliance Status |
|---|---|---|---|
| **Total Curated Schemes** | 100 | 100 | **100% Complete** |
| **Tier 1 Schemes (Full Deep Research)** | 10 | 10 | **Target Met** (Popular Ranks 1–10) |
| **Tier 2 Schemes (Catalogue Level)** | 90 | 90 | **Target Met** (Rank 0) |
| **Central Schemes (`central`)** | 60 | 60 | **Target Met** (60) |
| **Madhya Pradesh Schemes (`MP`)** | 15 | 15 | **Target Met** (15) |
| **Other State Schemes (12 States)** | 25 | 25 | **Target Met** (25) |
| **Schemes with Official Source URL** | 100 | 100 / 100 | **100% Compliant** |
| **Schemes with English + Hindi Names** | 100 | 100 / 100 | **100% Compliant** |
| **Agent Invariant: `rulesVerificationStatus == 'unverified'`** | 100 | 100 / 100 | **100% Compliant (Rule 5)** |
| **Agent Invariant: `eligibilityEnabled == false`** | 100 | 100 / 100 | **100% Compliant (Rule 5)** |

---

## 2. State & Regional Quota Breakdown

| Jurisdiction | Level | Scheme Count | Distribution |
|---|---|---|---|
| Central Government (All India) | `central` | 60 | 60.0% |
| Madhya Pradesh (`MP`) | `state` | 15 | 15.0% |
| State: `AS` | `state` | 1 | 1.0% |
| State: `BR` | `state` | 2 | 2.0% |
| State: `CG` | `state` | 1 | 1.0% |
| State: `GJ` | `state` | 1 | 1.0% |
| State: `JH` | `state` | 1 | 1.0% |
| State: `KA` | `state` | 4 | 4.0% |
| State: `MH` | `state` | 3 | 3.0% |
| State: `OD` | `state` | 1 | 1.0% |
| State: `RJ` | `state` | 1 | 1.0% |
| State: `TN` | `state` | 3 | 3.0% |
| State: `UP` | `state` | 3 | 3.0% |
| State: `WB` | `state` | 4 | 4.0% |

---

## 3. Controlled Category Distribution

| Category ID | Category Name (English / Hindi) | Schemes in Catalogue |
|---|---|---|
| `agriculture` | Agriculture & Farming (कृषि एवं किसान कल्याण) | 13 |
| `health` | Healthcare & Wellness (स्वास्थ्य एवं चिकित्सा) | 4 |
| `social-security` | Social Security & Pension (सामाजिक सुरक्षा एवं पेंशन) | 10 |
| `housing` | Housing & Shelter (आवास एवं आश्रय) | 2 |
| `finance` | Banking & Financial Inclusion (बैंकिंग एवं वित्तीय समावेशन) | 5 |
| `education` | Education & Scholarships (शिक्षा एवं छात्रवृत्ति) | 19 |
| `women-child` | Women & Child Development (महिला एवं बाल विकास) | 23 |
| `employment-skills` | Employment & Skill Development (रोजगार एवं कौशल विकास) | 12 |
| `business` | Business & Entrepreneurship (व्यापार एवं उद्यमिता) | 3 |
| `rural-development` | Rural Development (ग्रामीण विकास) | 3 |
| `utilities` | Energy & Clean Utilities (ऊर्जा एवं जन सुविधाएं) | 4 |
| `food-security` | Food Security & Nutrition (खाद्य सुरक्षा एवं राशन) | 1 |
| `tribal-welfare` | Tribal Affairs & Welfare (जनजातीय कल्याण) | 1 |

---

## 4. Profile Fields Vocabulary Status

All eligibility rules reference the 21 controlled citizen profile fields defined in `_profile_fields.json`:

| Field Key | Type | Question Prompt | Allowed Options / Bounds |
|---|---|---|---|
| `age` | `number` | What is your age in years? | Any valid scalar/boolean |
| `state` | `choice` | Which state or union territory do you reside in? | `AN`, `AP`, `AR`, `AS`, `BR`, `CH` (+31 more) |
| `district` | `choice` | What is your residential district? | Any valid scalar/boolean |
| `occupation` | `choice` | What is your primary occupation? | `farmer`, `agricultural_worker`, `unorganized_worker`, `construction_worker`, `street_vendor`, `artisan_craftsperson` (+7 more) |
| `gender` | `choice` | What is your gender? | `male`, `female`, `transgender` |
| `residenceType` | `choice` | Do you live in a rural or urban area? | `rural`, `urban` |
| `preferredLanguage` | `choice` | What is your preferred language? | `en`, `hi`, `mr`, `kn`, `bn`, `ta` |
| `socialCategory` | `choice` | What is your social category? | `general`, `obc`, `sc`, `st`, `minority` |
| `annualFamilyIncome` | `number` | What is your approximate annual family income (in ₹)? | Any valid scalar/boolean |
| `educationLevel` | `choice` | What is your highest educational qualification? | `none`, `primary`, `middle`, `secondary_10th`, `higher_secondary_12th`, `diploma` (+3 more) |
| `isStudent` | `bool` | Are you currently enrolled as a student? | Any valid scalar/boolean |
| `landholdingAcres` | `number` | How many acres of agricultural land does your family hold? | Any valid scalar/boolean |
| `isFarmer` | `bool` | Are you an agricultural cultivator or farmer? | Any valid scalar/boolean |
| `hasDisability` | `bool` | Do you have a benchmark disability (40% or more)? | Any valid scalar/boolean |
| `maritalStatus` | `choice` | What is your marital status? | `unmarried`, `married`, `widowed`, `divorced_separated` |
| `hasGirlChild` | `bool` | Do you have a daughter/girl child in your family? | Any valid scalar/boolean |
| `isPregnantOrLactating` | `bool` | Are you currently pregnant or a lactating mother? | Any valid scalar/boolean |
| `hasBplOrRationCard` | `bool` | Does your family possess a BPL, Antyodaya (AAY), or Priority Household (PHH) ration card? | Any valid scalar/boolean |
| `isTaxpayer` | `bool` | Did any member of your family pay income tax in the last assessment year? | Any valid scalar/boolean |
| `isGovtEmployee` | `bool` | Is any member of your household currently a regular government employee or pensioner? | Any valid scalar/boolean |
| `familySize` | `number` | How many members are in your family household? | Any valid scalar/boolean |

> **Profile Fields Added During Research:** **0 additions**. All rules map cleanly into the 21 controlled profile fields without extending the citizen schema.

---

## 5. Data Quality Flags & Audit Notes

### Flag Totals:

| Flag Name | Schemes Flagged | Context & Impact |
|---|---|---|
| `catalogue_tier2` | 90 | Catalogue-level tier with core eligibility criteria. Human review recommended before detailed rules expansion. |
| `name_unconfirmed` | 1 | Scheme listed as Rural Livelihoods Mission / SRLM under state verification. Name and guidelines pending official state gazette confirmation. |
| `partial_rules_coverage` | 9 | Complex eligibility guidelines condensed into essential citizen criteria. Additional administrative clauses exist in ministry circulars. |
| `staged_rules_secc_required` | 1 | Data audit review flag. |

### Audit Summary Exceptions:
- **Schemes that look renamed or discontinued:** 0 (None)
- **Schemes with no official URL:** 0 (None — 100% of schemes have official government portals verified)
- **Schemes where sources conflicted:** 0 (None — official .gov.in/.nic.in guidelines were prioritized over state aggregators)
- **Schemes under administrative verification (`name_unconfirmed`):** 1 scheme (`MP_STATE_RURAL_LIVELIHOODS_MISSION_001`, `status: 'underVerification'`, `verificationStatus: 'pending'`).

---

## 6. Per-Scheme Complete Audit Table (100 Schemes)

| # | Scheme ID | Tier | Official URL | Benefits | Docs | Rules | Verification Status | Hindi Reviewed | Flags |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `AGRI_INFRASTRUCTURE_FUND_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 2 | `AICTE_PRAGATI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 3 | `AICTE_SAKSHAM_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 4 | `AS_ORUNODOI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 5 | `ATAL_PENSION_YOJANA_001` | Tier 1 | Y | Y | Y | Y | `verified` | N | partial_rules_coverage |
| 6 | `AYUSHMAN_001` | Tier 1 | Y | Y | Y | Y | `verified` | N | staged_rules_secc_required |
| 7 | `BETI_BACHAO_BETI_PADHAO_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 8 | `BR_KANYA_UTTHAN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 9 | `BR_STUDENT_CREDIT_CARD_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 10 | `CG_MAHTARI_VANDAN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 11 | `CS_SCHOLARSHIP_COLLEGE_UNIVERSITY_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 12 | `DDU_GKY_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 13 | `DIGITAL_INDIA_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 14 | `E_SHRAM_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 15 | `GJ_VAHLI_DIKRI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 16 | `JAL_JEEVAN_MISSION_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 17 | `JH_MAIYA_SAMMAN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 18 | `KA_GRUHA_JYOTHI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 19 | `KA_GRUHA_LAKSHMI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 20 | `KA_SHAKTI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 21 | `KA_YUVA_NIDHI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 22 | `KISAN_CREDIT_CARD_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 23 | `MGNREGA_001` | Tier 1 | Y | Y | Y | Y | `verified` | N | partial_rules_coverage |
| 24 | `MH_LEK_LADKI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 25 | `MH_MAJHI_LADKI_BAHIN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 26 | `MH_NAMO_SHETKARI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 27 | `MISSION_SHAKTI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 28 | `MISSION_VATSALYA_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 29 | `MP_GAON_KI_BETI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 30 | `MP_JAN_KALYAN_SHIKSHA_PROTSAHAN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 31 | `MP_KANYA_VIVAH_NIKAH_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 32 | `MP_KISAN_KALYAN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 33 | `MP_LADLI_BEHNA_001` | Tier 1 | Y | Y | Y | Y | `verified` | N | partial_rules_coverage |
| 34 | `MP_LADLI_LAXMI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 35 | `MP_MEDHAVI_VIDYARTHI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 36 | `MP_POST_MATRIC_SCHOLARSHIP_SC_ST_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 37 | `MP_PRATIBHA_KIRAN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 38 | `MP_SAMBAL_2_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 39 | `MP_SIKHO_KAMAO_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 40 | `MP_STATE_RURAL_LIVELIHOODS_MISSION_001` | Tier 2 | Y | Y | N | N | `pending` | N | name_unconfirmed, catalogue_tier2 |
| 41 | `MP_TIRTH_DARSHAN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 42 | `MP_VIKRAMADITYA_SCHOLARSHIP_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 43 | `MP_YUVA_INTERNSHIP_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 44 | `NAPS_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 45 | `NATIONAL_CAREER_SERVICE_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 46 | `NATIONAL_FOOD_SECURITY_MISSION_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 47 | `NATIONAL_HEALTH_MISSION_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 48 | `NATIONAL_LIVESTOCK_MISSION_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 49 | `NATIONAL_OVERSEAS_SCHOLARSHIP_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 50 | `NATIONAL_SCHOLARSHIP_SC_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 51 | `NMMSS_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 52 | `NRLM_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 53 | `NSAP_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 54 | `NULM_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 55 | `OD_SUBHADRA_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 56 | `ONE_NATION_ONE_RATION_CARD_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 57 | `PM_JAN_AUSHADHI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 58 | `PM_JAN_DHAN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 59 | `PM_JANMAN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 60 | `PM_KISAN_001` | Tier 1 | Y | Y | Y | Y | `verified` | N | partial_rules_coverage |
| 61 | `PM_KISAN_MAANDHAN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 62 | `PM_MATRU_VANDANA_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 63 | `PM_MUDRA_001` | Tier 1 | Y | Y | Y | Y | `verified` | N | partial_rules_coverage |
| 64 | `PM_SURYA_GHAR_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 65 | `PM_SVANIDHI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 66 | `PM_SYM_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 67 | `PM_UJJWALA_001` | Tier 1 | Y | Y | Y | Y | `verified` | N | partial_rules_coverage |
| 68 | `PM_VISHWAKARMA_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 69 | `PM_YASASVI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 70 | `PMAY_001` | Tier 1 | Y | Y | Y | Y | `verified` | N | partial_rules_coverage |
| 71 | `PMAY_002` | Tier 1 | Y | Y | Y | Y | `verified` | N | partial_rules_coverage |
| 72 | `PMEGP_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 73 | `PMFBY_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 74 | `PMFME_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 75 | `PMJJBY_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 76 | `PMKSY_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 77 | `PMKVY_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 78 | `PMMSY_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 79 | `PMSBY_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 80 | `POST_MATRIC_SCHOLARSHIP_SC_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 81 | `POST_MATRIC_SCHOLARSHIP_ST_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 82 | `PRE_MATRIC_SCHOLARSHIP_MINORITIES_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 83 | `RASHTRIYA_VAYOSHRI_YOJANA_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 84 | `RJ_MUKHYAMANTRI_AYUSHMAN_AROGYA_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 85 | `RKVY_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 86 | `SAKSHAM_ANGANWADI_POSHAN_2_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 87 | `SOIL_HEALTH_CARD_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 88 | `STAND_UP_INDIA_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 89 | `STARTUP_INDIA_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 90 | `SUKANYA_SAMRIDDHI_001` | Tier 1 | Y | Y | Y | Y | `verified` | N | partial_rules_coverage |
| 91 | `TN_MAGALIR_URIMAI_THOGAI_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 92 | `TN_NAAN_MUDHALVAN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 93 | `TN_PUDHUMAI_PENN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 94 | `UP_KANYA_SUMANGALA_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 95 | `UP_SAMUHIK_VIVAH_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 96 | `UP_VISHWAKARMA_SHRAM_SAMMAN_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 97 | `WB_KANYASHREE_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 98 | `WB_KRISHAK_BANDHU_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 99 | `WB_LAKSHMIR_BHANDAR_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |
| 100 | `WB_RUPASHREE_001` | Tier 2 | Y | Y | N | N | `verified` | N | catalogue_tier2 |

---

## 7. Human Review & Verification Checklist (Pre-Eligibility Gate)

Before flipping `eligibilityEnabled: true` or upgrading `rulesVerificationStatus` to `verified`, a human policy reviewer should complete the following verification steps:

- [ ] **Check 1: Official Portal URL Validity** — Confirm that portal domain names remain reachable and are not undergoing administrative migration.
- [ ] **Check 2: Benefit Quantum Verification** — Verify benefit numbers (e.g. ₹6,000/year for PM-KISAN, ₹5 Lakh for Ayushman Bharat) against the latest annual budget circulars.
- [ ] **Check 3: Income Threshold Updates** — Check family income ceilings for state schemes (e.g., Mukhyamantri Kanya Sumangala ₹3,00,000, Ladli Behna ₹2,50,000) for recent state amendments.
- [ ] **Check 4: Hindi Terminology & Local Names** — Check local script naming (e.g. Lakshmir Bhandar, Orunodoi, Subhadra, Gruha Lakshmi) for regional app fidelity.
- [ ] **Check 5: Scheme 75 Gazette Confirmation** — Verify `MP_STATE_RURAL_LIVELIHOODS_MISSION_001` against MP Panchayat & Rural Development circulars to finalize state programme title before transitioning from `pending` to `verified`.

---
*Report generated automatically by SAHAY Scheme Catalogue Audit Engine.*
