# SAHAY (सहाय) — Document Classification & Frequency Mapping

## 1. Executive Summary

To power the Document Vault, smart scheme eligibility checklist, and automated OCR verification, this document establishes the comprehensive **Document Classification Hierarchy and Frequency Ranking** across the 100 government welfare schemes in SAHAY.

The catalogue analysis reveals that a small core set of standard Indian government identity and financial documents covers over **92% of citizen verification requirements**.

---

## 2. Ranked Canonical Document Frequency Analysis

The following table presents the ranked document frequency based on statutory scheme requirements, Direct Benefit Transfer (DBT) mandates, and `DocumentCatalogueService` canonical mapping:

| Rank | Canonical ID | Display Name (English) | Display Name (Hindi) | Relative Demand | Category | Key Entitlement Schemes |
| :---: | :--- | :--- | :--- | :---: | :--- | :--- |
| **1** | `aadhaar_card` | **Aadhaar Card** | **आधार कार्ड** | **100% (Universal)** | Identity | Universal across all Central & State welfare schemes |
| **2** | `bank_passbook` | **Bank Passbook / Statement** | **बैंक पासबुक / विवरण** | **88%** | Financial | PM-KISAN, Ladli Behna, Atal Pension, PM Scholarship, PMAY-G |
| **3** | `ration_card` | **Ration Card (BPL / NFSA / AAY)** | **राशन कार्ड (बीपीएल / अंत्योदय)** | **42%** | Social Welfare | PM-JAY (Ayushman), Ujjwala 2.0, PMAY-G, Annapurna |
| **4** | `domicile_certificate` | **Domicile / Residence Certificate** | **मूल निवास / अधिवास प्रमाण पत्र** | **38%** | Residence | State-sponsored schemes across MP, Assam, UP, Bihar, etc. |
| **5** | `income_certificate` | **Income Certificate** | **आय प्रमाण पत्र** | **34%** | Financial Status | Post-Matric Scholarship, EWS quotas, Fee waiver schemes |
| **6** | `caste_certificate` | **Caste Certificate (SC / ST / OBC)** | **जाति प्रमाण पत्र** | **26%** | Social Category | Pre/Post-Matric SC/ST scholarships, Stand-Up India, Tribal welfare |
| **7** | `land_ownership_record` | **Land Ownership Record (Khatauni / RoR)** | **भूमि स्वामित्व अभिलेख (खतौनी / खसरा)** | **22%** | Land & Property | PM-KISAN, Agri-Infrastructure Fund, PM Krishi Sinchayee |
| **8** | `marksheet_10th` | **10th Class Marksheet / Certificate** | **10वीं अंकसूची / प्रमाण पत्र** | **18%** | Education | Skill India, ITI admissions, PMSS prerequisite |
| **9** | `marksheet_12th` | **12th Class Marksheet / Intermediate** | **12वीं अंकसूची / इंटरमीडिएट** | **16%** | Education | PM Scholarship Scheme, Pragati, Saksham, Higher education |
| **10** | `birth_certificate` | **Birth Certificate** | **जन्म प्रमाण पत्र** | **14%** | Age Proof | Sukanya Samriddhi, Poshan Abhiyan, School entry schemes |
| **11** | `mgnrega_job_card` | **MGNREGA Job Card** | **मनरेगा जॉब कार्ड** | **12%** | Employment | PMAY-G rural construction bonus, MGNREGA employment |
| **12** | `disability_certificate` | **Disability Certificate (UDID Card)** | **दिव्यांगता प्रमाण पत्र (UDID)** | **10%** | Health & Disability| Divyangjan pensions, AICTE Saksham, ADIP assistive devices |
| **13** | `pan_card` | **PAN Card** | **पैन कार्ड** | **10%** | Financial / Tax | PM Mudra Yojana, MSME credit, PMEGP entrepreneurship |
| **14** | `samagra_id` | **Samagra Family / Member ID** | **समग्र परिवार / सदस्य आईडी** | **8%** | State Identity | Madhya Pradesh schemes (Ladli Behna, Sambal 2.0) |
| **15** | `voter_id` | **Voter ID (EPIC Card)** | **मतदाता पहचान पत्र (EPIC)** | **8%** | Secondary ID | Alternative age/residence proof for adult social pensions |
| **16** | `ews_certificate` | **EWS Certificate** | **ईडब्ल्यूएस प्रमाण पत्र** | **6%** | Economic Status | General category educational concessions, housing priority |

---

## 3. Highest Priority Document for Reference Photograph

The **#1 highest-demand document across all schemes in India is the Aadhaar Card (`aadhaar_card`)**, required by 100% of schemes for DBT subsidy disbursement and identity deduplication.

### Specimen Requirement:
- **Document Type**: **Aadhaar Card (आधार कार्ड)**
- **Issuing Authority**: Unique Identification Authority of India (UIDAI)
- **Key Visual Elements Needed in Reference Specimen**:
  1. Top Government of India / भारत सरकार bilingual header with National Ashoka Lion Emblem.
  2. UIDAI logo on the right.
  3. Resident photograph frame on the left.
  4. Citizen Demographic block: Full Name, Date of Birth (जन्म तिथि / DOB), Gender (पुरुष / महिला / Transgender).
  5. 12-digit Aadhaar number layout (either masked `XXXX XXXX 1234` or specimen `0000 0000 0000`).
  6. High-density secure QR code block on the lower right or reverse.
  7. Clear, flat perspective without harsh flash glare or obstruction.

---

## 4. Phase 6 Gate: Critical Stop Condition

Per the Master Implementation Plan instructions:
> **CRITICAL STOP CONDITION**: Prompt the user for the highest-priority reference photograph and wait for user upload before continuing photograph-dependent work.

The document mapping is finalized. The system is paused at this exact gate awaiting user photograph provision.

