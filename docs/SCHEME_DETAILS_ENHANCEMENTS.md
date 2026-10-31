# SAHAY (सहाय) — Scheme Details Screen Enhancements & Grounded Notes

## 1. Overview

The Scheme Detail Screen (`lib/screens/scheme_detail_screen.dart`) has been enhanced with two major architectural improvements:
1. **Interactive Expandable Document Cards** with specimen previews and issuing authority guidance.
2. **Important Notes & Eligibility Conditions Section** containing grounded, official operational rules for all six supported schemes.

---

## 2. Interactive Expandable Document Cards

Each document required by a scheme is rendered via `ExpandableDocumentCard` (`lib/widgets/expandable_document_card.dart`):

### Collapsed State
- Readiness checkbox for user self-preparation.
- Localized document title (English / Hindi).
- Category pill (Identity, Land, Income, Banking, etc.).
- Personal vault status badge: **"In Vault"** vs **"Not in Vault"**.
- Expand / collapse chevron.

### Expanded State
- **Why Required (Purpose)**: Scheme-specific rationale for requiring the document.
- **What it Proves**: Bulleted list of facts certified by the document.
- **Issuing Authority**: Department or magistrate with jurisdiction to issue the certificate.
- **How to Obtain**: Step-by-step instructions on acquiring the document online or via CSC/Panchayat.
- **Important Checks Before Applying**: Common pitfalls that cause rejection (name mismatches, expired income certificates, dormant bank accounts).
- **Specimen Sample View (`DocumentSpecimenViewer`)**: An illustrative mockup with government header, diagonal watermark (`SPECIMEN / नमूना`), and statutory disclaimer.
- **Action Buttons**: Direct shortcuts to "Upload to Vault (Optional)", "Replace", or "View in Vault".

---

## 3. Important Notes & Eligibility Conditions (Phase 5)

The new section features 4 grounded subsections across all six schemes:

### Scheme 1: PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)
- **Critical Eligibility Conditions**: Cultivable landholding in revenue records before cutoff date (01-02-2019); defined family unit (husband, wife, minor children); mandatory Aadhaar DBT linkage; mandatory e-KYC.
- **Reasons Leading to Disqualification**: Institutional landholders; former/present constitutional post holders; serving/retired govt employees (except Group D/MTS); pensioners >= ₹10,000/mo; income-tax payers in previous assessment year; registered professionals (doctors, engineers, lawyers, CAs).
- **Document Requirements**: Updated Khasra/Khatauni in applicant's name before 01-02-2019; Aadhaar Card; NPCI-mapped active bank passbook; non-exclusion self-declaration.
- **Application Precautions**: Ensure Land Seeding = YES on portal; verify letter-for-letter spelling between Aadhaar, land record, and bank account; only one payment per family unit.

### Scheme 2: PM-JAY (Ayushman Bharat)
- **Critical Eligibility Conditions**: Automatic entitlement from SECC 2011 deprivation criteria (D1–D7 rural, 11 urban groups); NFSA ration card holders; Senior Citizens aged 70+ under Ayushman Vaya Vandana; ₹5 Lakhs cashless secondary/tertiary hospital coverage; pre-existing conditions covered day one.
- **Reasons Leading to Disqualification**: Ownership of motorized vehicles, mechanized boats, tractors; KCC limit >= ₹50,000; government employee in family; registered non-agri enterprise; income-tax/professional-tax payers; pucca house >= 3 rooms; >= 5 acres irrigated land.
- **Document Requirements**: Aadhaar Card of every member; Ration Card (NFSA/BPL/AAY) or HH ID letter; active mobile number for OTP; Ayushman PVC card.
- **Application Precautions**: Hospital admission must be in empaneled network hospitals; minimum 24-hour hospitalization required (except daycare packages); present Ayushman Card at Ayushman Mitra desk immediately upon admission.

### Scheme 3: PMAY-G (Pradhan Mantri Awaas Yojana - Gramin)
- **Critical Eligibility Conditions**: Rural homeless or households living in 0, 1, or 2 kutcha rooms per SECC 2011 / Awaas+ list; financial aid ₹1.2L (plain) / ₹1.3L (hilly); 90/95 days MGNREGA labor wages (~₹20,000+); ₹12,000 toilet grant under Swachh Bharat.
- **Reasons Leading to Disqualification (13 Automatic Exclusions)**: Motorized vehicles/boats; KCC limit >= ₹50,000; government employees; registered non-agri enterprise; income/professional tax payers; refrigerator or landline ownership; >= 2.5 acres irrigated land; prior ownership of pucca house anywhere in India.
- **Document Requirements**: Aadhaar Card of applicant and spouse; active MGNREGA Job Card; Aadhaar-seeded bank passbook; land possession certificate / patta; geo-tagged photos of existing kutcha structure.
- **Application Precautions**: Tranches released strictly after geo-tagged inspection via AwaasApp; 25 sq. m. minimum carpet area; must be completed within 12 months; never pay middleman fees.

### Scheme 4: PMUY 2.0 (Ujjwala 2.0)
- **Critical Eligibility Conditions**: Applicant MUST be an adult woman (aged 18+); NO existing domestic LPG connection in the same household from any OMC; eligible categories: SC/ST, PMAY-G, Antyodaya, Most Backward Classes, or 14-Point Poor Declaration; deposit-free connection + free first refill + stove.
- **Reasons Leading to Disqualification**: Male applicants; age under 18; existing LPG connection in household; non-eligible category.
- **Document Requirements**: Woman's Aadhaar (e-KYC); adult family members' Aadhaars; Ration Card / Family Roster (or Annexure-I for migrants); bank passbook; proof of address.
- **Application Precautions**: Migrants do NOT require local ration cards; Annexure-I self-declaration is legally valid; apply only through authorized Indane/Bharat/HP distributors or pmuy.gov.in.

### Scheme 5: PMSS (Prime Minister's Scholarship Scheme)
- **Critical Eligibility Conditions**: Dependent wards/widows of Ex-Servicemen (ESM) / Coast Guard / CAPF personnel; minimum 60% aggregate in Class 12 / MEQ; enrolled in recognized professional degree (BE/BTech, MBBS, BDS, B.Pharm, etc.); scholarship ₹3,000/mo (girls), ₹2,500/mo (boys).
- **Reasons Leading to Disqualification**: Distance learning/correspondence courses; non-professional degrees (BA, B.Sc, B.Com); Class 12 < 60%; civilian students without defense record; duplicate government scholarship; scoring < 50% in subsequent years.
- **Document Requirements**: Class 10 & 12 marksheets; ESM Discharge Book / PPO / CAPF Service Certificate; College Bonafide Certificate (Annexure-1); MEQ Percentage Certificate (Annexure-2); student's OWN single bank account.
- **Application Precautions**: Applications accepted exclusively on NSP (scholarships.gov.in); parents' bank accounts lead to rejection; track institute and State Nodal Officer verification before portal deadlines.

### Scheme 6: MP Mukhyamantri Ladli Behna Yojana
- **Critical Eligibility Conditions**: Permanent woman resident of Madhya Pradesh; married/widowed/divorced/abandoned woman aged 21–60; ₹1,250 monthly DBT assistance; active 8-digit Samagra Family ID and 9-digit Member ID; Samagra e-KYC completed.
- **Reasons Leading to Disqualification**: Family annual income > ₹2,50,000; income-tax payer in family; government/PSU employee (Anganwadi/ASHA exempted); pension >= ₹1,250/mo; MP/MLA in family; agricultural land > 5 acres; four-wheeler vehicle ownership.
- **Document Requirements**: Samagra Family & Member ID; Aadhaar Card; single bank passbook linked with Aadhaar DBT; mobile number registered with Aadhaar and Samagra; MP Domicile Certificate.
- **Application Precautions**: Bank account MUST be single in the woman's name alone; husband's or joint accounts are rejected; verify NPCI DBT mapping at bank branch before submitting.

