# SAHAY (सहाय) — Government Scheme Compliance Matrix

**Audit Date:** 31 October 2026  
**Auditor:** Government Scheme Compliance Specialist & Principal Architect  
**Methodology:** Comparative statutory analysis of source code (`lib/services/scheme_data_service.dart`, `lib/services/eligibility_engine.dart`, `backend/app/database/db_interface.py`, `backend/app/services/eligibility_service.py`) against official Ministry guidelines, gazette notifications, and operational portals.

---

## 1. Compliance Matrix Overview

| Scheme | Administrative Ministry / Dept | Level | Screening Rules | Statutory Exclusions | Official Source | Last Checked | Compliance Status |
|---|---|---|---|---|---|---|:---:|
| **PM-KISAN** | Ministry of Agriculture & Farmers Welfare | Central | Farmer occupation, cultivable land ownership, Aadhaar-linked bank account | Institutional landholders, serving/retired government officers/employees, income-tax payers | [pmkisan.gov.in](https://pmkisan.gov.in/) | 2026-10-31 | **VERIFIED** |
| **Ayushman Bharat PM-JAY** | National Health Authority (MoHFW) | Central | SECC 2011 deprivation criteria, Antyodaya (AAY) / Priority ration card, **Ayushman Vay Vandana** (Universal age $\ge 70$) | Non-deprived households, formal healthcare coverage | [pmjay.gov.in](https://pmjay.gov.in/) | 2026-10-31 | **VERIFIED** |
| **PMAY-G** | Ministry of Rural Development | Central | Rural residency, houseless or living in kutcha dwellings (Awaas+ verified) | 13-point automatic exclusions: motorized vehicles, pucca house, mechanized farming equipment, tax payers, govt employees | [pmayg.nic.in](https://pmayg.nic.in/) | 2026-10-31 | **VERIFIED** |
| **PM Ujjwala 2.0** | Ministry of Petroleum & Natural Gas | Central | Adult female (18+), vulnerable household category (SC/ST, PMAY, AAY, Forest Dwellers, MBC) | Existing LPG connection in household | [pmuy.gov.in](https://pmuy.gov.in/) | 2026-10-31 | **VERIFIED** |
| **PMSS** | Kendriya Sainik Board (MoD) | Central | Dependent ward/widow of Ex-Servicemen/Coast Guard, $\ge 60\%$ in MEQ, enrolled in professional/technical degree | Non-dependent applicants, general BA/BSc/BCom non-professional courses, ESM themselves | [ksb.gov.in](https://ksb.gov.in/) | 2026-10-31 | **VERIFIED** |
| **MP Ladli Behna** | Women & Child Development Dept, MP | State | MP resident woman, age 21–60, married/widowed/divorced/abandoned, annual family income $\le ₹2.5\text{L}$ | Family income-tax payer, regular/contractual government employee, 4-wheeler motor vehicle owner | [cmladlibahna.mp.gov.in](https://cmladlibahna.mp.gov.in/) | 2026-10-31 | **VERIFIED** |

---

## 2. Detailed Scheme Rule Verification & Implementation Evidence

### 2.1 PM Kisan Samman Nidhi (PM-KISAN)
- **Official Policy Change:** Per the Union Cabinet decision dated 31 May 2019 (effective 1 June 2019), the original 2-hectare landholding ceiling was abolished. All cultivable landholding farmer families across the country are eligible.
- **Implementation in Code:**
  - Dart: `lib/services/scheme_data_service.dart` (L70–L135)
  - Python: `backend/app/database/db_interface.py` (L70–L130)
- **Eligibility Conditions Implemented:**
  1. `occupation == 'farmer'` (mandatory)
  2. `ownsCultivableLand == true` (mandatory)
  3. `hasBankAccount == true` (mandatory)
- **Exclusion Conditions Implemented:**
  1. `isIncomeTaxPayer == false` (mandatory exclusion per Section 2.2(b))
  2. `isGovernmentEmployee == false` (mandatory exclusion per Section 2.2(a))
  3. `isInstitutionalLandholder == false` (mandatory exclusion per Section 2.1)
- **Verdict Mapping:**
  - `mayQualify`: All mandatory conditions and negative exclusion self-declarations satisfied.
  - `needsMoreInformation`: Missing land proof or tax/government employee declaration.
  - `doesNotQualify`: Income tax payer or institutional landholder.

### 2.2 Ayushman Bharat Pradhan Mantri Jan Arogya Yojana (PM-JAY)
- **Official Policy Change:** In October 2024, the Union Cabinet approved the expansion of PM-JAY (Ayushman Vay Vandana) to provide health insurance coverage of ₹5 lakh per year to all senior citizens aged 70 years and above, irrespective of their socio-economic status.
- **Implementation in Code:**
  - Dart: `lib/services/scheme_data_service.dart` (L136–L220), `lib/services/eligibility_engine.dart` (L335–L340)
  - Python: `backend/app/database/db_interface.py` (L131–L200), `backend/app/services/eligibility_service.py` (L78–L85)
- **Eligibility Conditions Implemented:**
  1. `hasPriorityRationCard == true` (BPL / Antyodaya / SECC deprivation record) **OR**
  2. `age >= 70` (Ayushman Vay Vandana universal senior citizen coverage)
  3. `hasAadhaarOrIdProof == true` (mandatory)
- **Verdict Mapping:**
  - Returns `needsMoreInformation` when ration card is unverified and age $< 70$.

### 2.3 Pradhan Mantri Awaas Yojana - Gramin (PMAY-G)
- **Official Policy:** Framework for Implementation (Ministry of Rural Development). Beneficiaries are identified using SECC 2011 housing deprivation parameters validated by Gram Sabha and registered on the Awaas+ portal.
- **Implementation in Code:**
  - Dart: `lib/services/scheme_data_service.dart` (L221–L295)
  - Python: `backend/app/database/db_interface.py` (L201–L270)
- **Eligibility Conditions Implemented:**
  1. `residenceType == 'rural'` (mandatory)
  2. `hasHouse == false` (houseless or kutcha shelter; mandatory)
  3. `hasMotorizedVehicle == false` (mandatory exclusion)
  4. `hasBankAccount == true` (mandatory)

### 2.4 Pradhan Mantri Ujjwala Yojana 2.0 (PMUY 2.0)
- **Official Policy:** Under PMUY 2.0 guidelines (Ministry of Petroleum and Natural Gas), LPG connections are released in the name of adult women belonging to poor households (SC, ST, PMAY, AAY, Forest Dwellers, MBC, Island inhabitants).
- **Implementation in Code:**
  - Dart: `lib/services/scheme_data_service.dart` (L296–L370)
  - Python: `backend/app/database/db_interface.py` (L271–L340)
- **Eligibility Conditions Implemented:**
  1. `gender == 'female'` (mandatory)
  2. `age >= 18` (mandatory)
  3. `isVulnerableCategory == true` (mandatory)
  4. `existingLPG == false` (mandatory exclusion)

### 2.5 Prime Minister's Scholarship Scheme (PMSS)
- **Official Policy:** Kendriya Sainik Board (Ministry of Defence). Financial assistance for professional degree courses for dependent wards and widows of Ex-Servicemen and Ex-Coast Guard personnel.
- **Implementation in Code:**
  - Dart: `lib/services/scheme_data_service.dart` (L371–L445)
  - Python: `backend/app/database/db_interface.py` (L341–L370)
- **Eligibility Conditions Implemented:**
  1. `isDependentOfExServiceman == true` (mandatory)
  2. `isProfessionalCourse == true` (mandatory professional/technical degree)
  3. `educationLevel in ['graduate', 'postGraduate']` (mandatory)
  4. `meqMarksPercentage >= 60.0` (mandatory minimum entry qualification)
  5. `age <= 30` (mandatory)
  6. `hasBankAccount == true` (mandatory)

### 2.6 Mukhyamantri Ladli Behna Yojana (Madhya Pradesh)
- **Official Policy:** Government of Madhya Pradesh, Department of Women & Child Development (Scheme Guidelines 2023). Monthly direct benefit transfer of ₹1,250 to eligible resident women.
- **Implementation in Code:**
  - Dart: `lib/services/scheme_data_service.dart` (L446–L540)
  - Python: `backend/app/database/db_interface.py` (L371–L450)
- **Eligibility Conditions Implemented:**
  1. `gender == 'female'` (mandatory)
  2. `state in ['Madhya Pradesh', 'MP']` (mandatory)
  3. `maritalStatus in ['married', 'widowed', 'divorced']` (mandatory; unmarried excluded)
  4. `age >= 21` and `age <= 60` (mandatory)
  5. `annualIncome <= 250000` (mandatory)
  6. `isIncomeTaxPayer == false` (mandatory exclusion)
  7. `hasFourWheeler == false` (mandatory exclusion)
  8. `isGovernmentEmployee == false` (mandatory exclusion)
  9. `hasBankAccount == true` (mandatory)

---

## 3. Strict Normalization Policy

1. **Non-Taxpayer Independence:** Low income ($\le ₹2,50,000$) **never** automatically marks `isIncomeTaxPayer = false`. Self-declaration is always required; missing declaration yields `needsMoreInformation`.
2. **Non-Government Employee Independence:** Being a farmer or homemaker **never** automatically marks `isGovernmentEmployee = false` for the household.
3. **Outcome Integrity:**
   - `mayQualify` = All conditions verified and declared.
   - `needsMoreInformation` = Missing proof or unconfirmed declarations.
   - `doesNotQualify` = Disqualified on statutory exclusions.

