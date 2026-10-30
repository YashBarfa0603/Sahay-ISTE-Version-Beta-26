#!/usr/bin/env python3
"""
Catalogue Validation Script for SAHAY (Schema v2).
Performs comprehensive schema, integrity, provenance, and domain verification.
Supports local JSON validation, Firestore Emulator validation, and live Firestore validation.
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from urllib.parse import urlparse
from typing import Dict, List, Set, Any, Tuple

# Add parent path to import schemas
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from backend.app.schemas.scheme_schema import (
    SchemeDocument,
    ALLOWED_CATEGORIES,
    ALLOWED_TAGS,
    ALLOWED_OPERATORS,
    ALLOWED_STATE_CODES,
)

# Section 7: List of 100 Scheme IDs with target levels and state expectations
EXPECTED_SCHEMES_SPEC: List[Dict[str, Any]] = [
    # 60 Central schemes
    {"schemeId": "PM_KISAN_001", "name": "PM-KISAN – Pradhan Mantri Kisan Samman Nidhi", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PMFBY_001", "name": "Pradhan Mantri Fasal Bima Yojana (PMFBY)", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "KISAN_CREDIT_CARD_001", "name": "Kisan Credit Card (KCC)", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PM_KISAN_MAANDHAN_001", "name": "Pradhan Mantri Kisan Maandhan Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PMKSY_001", "name": "Pradhan Mantri Krishi Sinchayee Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "SOIL_HEALTH_CARD_001", "name": "Soil Health Card Scheme", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "AGRI_INFRASTRUCTURE_FUND_001", "name": "Agriculture Infrastructure Fund", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "NATIONAL_FOOD_SECURITY_MISSION_001", "name": "National Food Security Mission", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "RKVY_001", "name": "Rashtriya Krishi Vikas Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "MGNREGA_001", "name": "MGNREGA – Mahatma Gandhi National Rural Employment Guarantee Act", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "AYUSHMAN_001", "name": "Ayushman Bharat – PM Jan Arogya Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PM_JAN_AUSHADHI_001", "name": "Pradhan Mantri Jan Aushadhi Pariyojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "NATIONAL_HEALTH_MISSION_001", "name": "National Health Mission", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PMSBY_001", "name": "Pradhan Mantri Suraksha Bima Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PMJJBY_001", "name": "Pradhan Mantri Jeevan Jyoti Bima Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "ATAL_PENSION_YOJANA_001", "name": "Atal Pension Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "NSAP_001", "name": "National Social Assistance Programme", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PM_SYM_001", "name": "Pradhan Mantri Shram Yogi Maandhan", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "E_SHRAM_001", "name": "e-Shram", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "RASHTRIYA_VAYOSHRI_YOJANA_001", "name": "Rashtriya Vayoshri Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PMAY_001", "name": "Pradhan Mantri Awas Yojana – Gramin", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PMAY_002", "name": "Pradhan Mantri Awas Yojana – Urban", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PM_UJJWALA_001", "name": "Pradhan Mantri Ujjwala Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PM_JAN_DHAN_001", "name": "Pradhan Mantri Jan Dhan Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PM_MUDRA_001", "name": "Pradhan Mantri Mudra Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "STAND_UP_INDIA_001", "name": "Stand-Up India", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PM_SVANIDHI_001", "name": "PM SVANidhi", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "SUKANYA_SAMRIDDHI_001", "name": "Sukanya Samriddhi Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PM_SURYA_GHAR_001", "name": "Pradhan Mantri Surya Ghar: Muft Bijli Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "JAL_JEEVAN_MISSION_001", "name": "Jal Jeevan Mission", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "NMMSS_001", "name": "National Means-cum-Merit Scholarship Scheme", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "CS_SCHOLARSHIP_COLLEGE_UNIVERSITY_001", "name": "Central Sector Scheme of Scholarships for College and University Students", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "NATIONAL_SCHOLARSHIP_SC_001", "name": "National Scholarship Scheme for SC Students", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "POST_MATRIC_SCHOLARSHIP_SC_001", "name": "Post-Matric Scholarship for SC Students", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "POST_MATRIC_SCHOLARSHIP_ST_001", "name": "Post-Matric Scholarship for ST Students", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PRE_MATRIC_SCHOLARSHIP_MINORITIES_001", "name": "Pre-Matric Scholarship for Minorities", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PM_YASASVI_001", "name": "PM YASASVI", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "NATIONAL_OVERSEAS_SCHOLARSHIP_001", "name": "National Overseas Scholarship", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "AICTE_PRAGATI_001", "name": "AICTE Pragati Scholarship", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "AICTE_SAKSHAM_001", "name": "AICTE Saksham Scholarship", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "BETI_BACHAO_BETI_PADHAO_001", "name": "Beti Bachao Beti Padhao", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PM_MATRU_VANDANA_001", "name": "Pradhan Mantri Matru Vandana Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "MISSION_SHAKTI_001", "name": "Mission Shakti", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "MISSION_VATSALYA_001", "name": "Mission Vatsalya", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "SAKSHAM_ANGANWADI_POSHAN_2_001", "name": "Saksham Anganwadi and POSHAN 2.0", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PMKVY_001", "name": "Pradhan Mantri Kaushal Vikas Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "DDU_GKY_001", "name": "Deen Dayal Upadhyaya Grameen Kaushalya Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "NATIONAL_CAREER_SERVICE_001", "name": "National Career Service", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PM_VISHWAKARMA_001", "name": "PM Vishwakarma", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "STARTUP_INDIA_001", "name": "Startup India", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PMFME_001", "name": "PM Formalisation of Micro Food Processing Enterprises Scheme (PMFME)", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PMEGP_001", "name": "Prime Minister's Employment Generation Programme (PMEGP)", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "NRLM_001", "name": "National Rural Livelihoods Mission", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "NULM_001", "name": "National Urban Livelihoods Mission", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PMMSY_001", "name": "Pradhan Mantri Matsya Sampada Yojana", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "NATIONAL_LIVESTOCK_MISSION_001", "name": "National Livestock Mission", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "DIGITAL_INDIA_001", "name": "Digital India", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "ONE_NATION_ONE_RATION_CARD_001", "name": "One Nation One Ration Card", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "NAPS_001", "name": "National Apprenticeship Promotion Scheme", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},
    {"schemeId": "PM_JANMAN_001", "name": "Pradhan Mantri Janjati Adivasi Nyaya Maha Abhiyan (PM-JANMAN)", "governmentLevel": "central", "applicableStates": ["ALL_INDIA"]},

    # 15 Madhya Pradesh schemes
    {"schemeId": "MP_LADLI_BEHNA_001", "name": "Mukhyamantri Ladli Behna Yojana", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_LADLI_LAXMI_001", "name": "Mukhyamantri Ladli Laxmi Yojana", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_KISAN_KALYAN_001", "name": "Mukhyamantri Kisan Kalyan Yojana", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_SIKHO_KAMAO_001", "name": "Mukhyamantri Sikho Kamao Yojana", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_MEDHAVI_VIDYARTHI_001", "name": "Mukhyamantri Medhavi Vidyarthi Yojana", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_GAON_KI_BETI_001", "name": "Gaon Ki Beti Yojana", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_PRATIBHA_KIRAN_001", "name": "Pratibha Kiran Yojana", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_SAMBAL_2_001", "name": "Sambal 2.0 Yojana", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_KANYA_VIVAH_NIKAH_001", "name": "Mukhyamantri Kanya Vivah/Nikah Yojana", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_TIRTH_DARSHAN_001", "name": "Mukhyamantri Tirth-Darshan Yojana", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_YUVA_INTERNSHIP_001", "name": "Mukhyamantri Yuva Internship Yojana", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_VIKRAMADITYA_SCHOLARSHIP_001", "name": "Vikramaditya Scholarship Yojana", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_POST_MATRIC_SCHOLARSHIP_SC_ST_001", "name": "Post-Matric Scholarship for SC/ST Students (MP implementation)", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_JAN_KALYAN_SHIKSHA_PROTSAHAN_001", "name": "Mukhyamantri Jan Kalyan (Shiksha Protsahan) Yojana", "governmentLevel": "state", "applicableStates": ["MP"]},
    {"schemeId": "MP_STATE_RURAL_LIVELIHOODS_MISSION_001", "name": "MP Day State Rural Livelihoods Mission programmes", "governmentLevel": "state", "applicableStates": ["MP"]},

    # 25 Other State schemes
    {"schemeId": "MH_MAJHI_LADKI_BAHIN_001", "name": "Mukhyamantri Majhi Ladki Bahin Yojana", "governmentLevel": "state", "applicableStates": ["MH"]},
    {"schemeId": "MH_NAMO_SHETKARI_001", "name": "Namo Shetkari Mahasanman Nidhi Yojana", "governmentLevel": "state", "applicableStates": ["MH"]},
    {"schemeId": "MH_LEK_LADKI_001", "name": "Lek Ladki Yojana", "governmentLevel": "state", "applicableStates": ["MH"]},
    {"schemeId": "KA_GRUHA_LAKSHMI_001", "name": "Gruha Lakshmi Scheme", "governmentLevel": "state", "applicableStates": ["KA"]},
    {"schemeId": "KA_GRUHA_JYOTHI_001", "name": "Gruha Jyothi Scheme", "governmentLevel": "state", "applicableStates": ["KA"]},
    {"schemeId": "KA_YUVA_NIDHI_001", "name": "Yuva Nidhi Scheme", "governmentLevel": "state", "applicableStates": ["KA"]},
    {"schemeId": "KA_SHAKTI_001", "name": "Shakti Scheme", "governmentLevel": "state", "applicableStates": ["KA"]},
    {"schemeId": "WB_LAKSHMIR_BHANDAR_001", "name": "Lakshmir Bhandar", "governmentLevel": "state", "applicableStates": ["WB"]},
    {"schemeId": "WB_KANYASHREE_001", "name": "Kanyashree Prakalpa", "governmentLevel": "state", "applicableStates": ["WB"]},
    {"schemeId": "WB_RUPASHREE_001", "name": "Rupashree Prakalpa", "governmentLevel": "state", "applicableStates": ["WB"]},
    {"schemeId": "WB_KRISHAK_BANDHU_001", "name": "Krishak Bandhu Scheme", "governmentLevel": "state", "applicableStates": ["WB"]},
    {"schemeId": "TN_MAGALIR_URIMAI_THOGAI_001", "name": "Kalaignar Magalir Urimai Thogai", "governmentLevel": "state", "applicableStates": ["TN"]},
    {"schemeId": "TN_PUDHUMAI_PENN_001", "name": "Pudhumai Penn Scheme", "governmentLevel": "state", "applicableStates": ["TN"]},
    {"schemeId": "TN_NAAN_MUDHALVAN_001", "name": "Naan Mudhalvan Scheme", "governmentLevel": "state", "applicableStates": ["TN"]},
    {"schemeId": "UP_KANYA_SUMANGALA_001", "name": "Mukhyamantri Kanya Sumangala Yojana", "governmentLevel": "state", "applicableStates": ["UP"]},
    {"schemeId": "UP_SAMUHIK_VIVAH_001", "name": "Mukhyamantri Samuhik Vivah Yojana", "governmentLevel": "state", "applicableStates": ["UP"]},
    {"schemeId": "UP_VISHWAKARMA_SHRAM_SAMMAN_001", "name": "Vishwakarma Shram Samman Yojana", "governmentLevel": "state", "applicableStates": ["UP"]},
    {"schemeId": "BR_KANYA_UTTHAN_001", "name": "Mukhyamantri Kanya Utthan Yojana", "governmentLevel": "state", "applicableStates": ["BR"]},
    {"schemeId": "BR_STUDENT_CREDIT_CARD_001", "name": "Bihar Student Credit Card Scheme", "governmentLevel": "state", "applicableStates": ["BR"]},
    {"schemeId": "JH_MAIYA_SAMMAN_001", "name": "Mukhyamantri Maiya Samman Yojana", "governmentLevel": "state", "applicableStates": ["JH"]},
    {"schemeId": "CG_MAHTARI_VANDAN_001", "name": "Mahtari Vandan Yojana", "governmentLevel": "state", "applicableStates": ["CG"]},
    {"schemeId": "AS_ORUNODOI_001", "name": "Orunodoi Scheme", "governmentLevel": "state", "applicableStates": ["AS"]},
    {"schemeId": "OD_SUBHADRA_001", "name": "Subhadra Yojana", "governmentLevel": "state", "applicableStates": ["OD"]},
    {"schemeId": "RJ_MUKHYAMANTRI_AYUSHMAN_AROGYA_001", "name": "Mukhyamantri Ayushman Arogya Yojana", "governmentLevel": "state", "applicableStates": ["RJ"]},
    {"schemeId": "GJ_VAHLI_DIKRI_001", "name": "Vahli Dikri Yojana", "governmentLevel": "state", "applicableStates": ["GJ"]},
]

POPULAR_SCHEMES_ORDER = [
    "PM_KISAN_001",
    "AYUSHMAN_001",
    "PM_UJJWALA_001",
    "PMAY_001",
    "PMAY_002",
    "SUKANYA_SAMRIDDHI_001",
    "ATAL_PENSION_YOJANA_001",
    "PM_MUDRA_001",
    "MGNREGA_001",
    "MP_LADLI_BEHNA_001",
]


def is_official_url(url: str) -> bool:
    """Validates that a URL is well-formed and belongs to an official government domain."""
    if not url:
        return True
    try:
        parsed = urlparse(url)
        if not parsed.scheme or parsed.scheme not in ("http", "https"):
            return False
        host = (parsed.hostname or "").lower()
        if not host:
            return False
        # Approved official domains: *.gov.in, *.nic.in, or state official portal subdomains
        if host.endswith(".gov.in") or host.endswith(".nic.in"):
            return True
        # Explicitly allowed state government official domains (e.g., mp.gov.in, maharashtra.gov.in, etc.)
        allowed_exact_or_suffix = [
            "myscheme.gov.in",
            "mp.gov.in",
            "maharashtra.gov.in",
            "karnataka.gov.in",
            "wb.gov.in",
            "tn.gov.in",
            "up.gov.in",
            "bihar.gov.in",
            "jharkhand.gov.in",
            "cgstate.gov.in",
            "assam.gov.in",
            "odisha.gov.in",
            "rajasthan.gov.in",
            "gujarat.gov.in",
        ]
        for domain in allowed_exact_or_suffix:
            if host == domain or host.endswith("." + domain):
                return True
        return False
    except Exception:
        return False


def validate_scheme_dict(
    doc: Dict[str, Any],
    profile_field_keys: Set[str],
    categories_set: Set[str],
    is_firestore_doc: bool = False,
) -> List[str]:
    """Validates a single scheme dictionary against all schema v2 and catalogue rules."""
    errors = []
    scheme_id = doc.get("schemeId", "UNKNOWN")

    # 1. Pydantic schema validation
    try:
        validated = SchemeDocument(**doc)
    except Exception as e:
        errors.append(f"[{scheme_id}] Pydantic validation failed: {e}")
        return errors

    # 2. Match schemeId and document ID
    if doc.get("schemeId") != scheme_id:
        errors.append(f"[{scheme_id}] schemeId mismatch in document")

    # 3. Category existence
    if validated.category not in categories_set:
        errors.append(f"[{scheme_id}] Category '{validated.category}' not found in _categories.json")

    # 4. Tags validation
    for tag in validated.tags:
        if tag not in ALLOWED_TAGS:
            errors.append(f"[{scheme_id}] Tag '{tag}' is not in controlled tag vocabulary")

    # 5. Applicable states & governmentLevel
    if validated.governmentLevel == "central":
        if validated.applicableStates != ["ALL_INDIA"]:
            errors.append(f"[{scheme_id}] Central scheme must have applicableStates=['ALL_INDIA']")
    elif validated.governmentLevel == "state":
        if "ALL_INDIA" in validated.applicableStates or not validated.applicableStates:
            errors.append(f"[{scheme_id}] State scheme must specify non-empty state codes excluding ALL_INDIA")

    # 6. Rules fields and operators
    for rule in validated.eligibilityRules:
        if rule.field not in profile_field_keys:
            errors.append(f"[{scheme_id}] Rule field '{rule.field}' not found in profile fields vocabulary")
        if rule.operator not in ALLOWED_OPERATORS:
            errors.append(f"[{scheme_id}] Rule operator '{rule.operator}' invalid")
        if not rule.sourceUrl:
            errors.append(f"[{scheme_id}] Rule for field '{rule.field}' missing sourceUrl")
        elif not is_official_url(rule.sourceUrl):
            errors.append(f"[{scheme_id}] Rule sourceUrl '{rule.sourceUrl}' is not an official domain")
        if not rule.sourceQuote or len(rule.sourceQuote.split()) > 25:
            errors.append(f"[{scheme_id}] Rule for field '{rule.field}' has invalid sourceQuote (must be 1-25 words)")

    # 7. URL checks
    for url_field, url_val in [
        ("officialSourceUrl", validated.officialSourceUrl),
        ("applicationUrl", validated.applicationUrl),
    ]:
        if url_val and not is_official_url(url_val):
            errors.append(f"[{scheme_id}] {url_field} '{url_val}' is not on an official domain (*.gov.in, *.nic.in)")

    for src_url in validated.sourceUrls:
        if not is_official_url(src_url):
            errors.append(f"[{scheme_id}] sourceUrls entry '{src_url}' is not on an official domain")

    # 8. Mandatory Agent constraints
    if validated.rulesVerificationStatus != "unverified":
        errors.append(f"[{scheme_id}] rulesVerificationStatus must be 'unverified' on seed documents")
    if validated.eligibilityEnabled is not False:
        errors.append(f"[{scheme_id}] eligibilityEnabled must be False on seed documents")

    # 9. Verification status consistency
    if validated.verificationStatus == "verified":
        if not validated.officialSourceUrl:
            errors.append(f"[{scheme_id}] verified status requires officialSourceUrl")
        if not validated.lastVerified:
            errors.append(f"[{scheme_id}] verified status requires lastVerified timestamp")
        if not validated.verifiedBy:
            errors.append(f"[{scheme_id}] verified status requires verifiedBy")

    # 10. Hindi documents parity
    if validated.requiredDocumentsHindi and len(validated.requiredDocumentsHindi) != len(validated.requiredDocuments):
        errors.append(f"[{scheme_id}] requiredDocumentsHindi length must match requiredDocuments or be empty")

    # 11. Search keywords
    if len(validated.searchKeywords) > 25:
        errors.append(f"[{scheme_id}] searchKeywords exceeds max limit 25")
    for kw in validated.searchKeywords:
        if kw != kw.lower():
            errors.append(f"[{scheme_id}] searchKeyword '{kw}' must be lowercase")

    return errors


def validate_catalogue(
    data_dir: Path,
    expected_count: int = 100,
    check_all_files: bool = True,
    db: Any = None,
) -> Tuple[bool, List[str], Dict[str, Any]]:
    """Runs full catalogue validation across seed files or Firestore."""
    all_errors = []
    summary = {
        "total_files": 0,
        "valid_schemes": 0,
        "central_count": 0,
        "mp_count": 0,
        "other_state_count": 0,
        "popular_count": 0,
        "verified_count": 0,
        "pending_count": 0,
    }

    if db is not None:
        print("[*] Fetching catalogue directly from Firestore...")
        # 1. Categories
        cat_snaps = list(db.collection("categories").stream())
        categories_set = {snap.id for snap in cat_snaps}
        if categories_set != ALLOWED_CATEGORIES:
            all_errors.append(f"Categories mismatch with allowed vocabulary: {categories_set.symmetric_difference(ALLOWED_CATEGORIES)}")

        # 2. Profile fields
        pf_snap = db.collection("appConfig").document("profileFields").get()
        if not pf_snap.exists:
            all_errors.append("Missing appConfig/profileFields document in Firestore")
            profile_fields_set = set()
        else:
            profile_fields_set = {f["key"] for f in pf_snap.to_dict().get("fields", [])}

        # 3. Schemes
        scheme_snaps = list(db.collection("schemes").stream())
        summary["total_files"] = len(scheme_snaps)
        loaded_schemes: Dict[str, Dict[str, Any]] = {s.id: s.to_dict() for s in scheme_snaps}
    else:
        categories_file = data_dir / "_categories.json"
        profile_fields_file = data_dir / "_profile_fields.json"

        if not categories_file.exists():
            all_errors.append(f"Categories file missing: {categories_file}")
            return False, all_errors, summary

        if not profile_fields_file.exists():
            all_errors.append(f"Profile fields file missing: {profile_fields_file}")
            return False, all_errors, summary

        with open(categories_file, "r", encoding="utf-8") as f:
            categories_data = json.load(f)
        categories_set = {cat["categoryId"] for cat in categories_data}
        if categories_set != ALLOWED_CATEGORIES:
            all_errors.append(f"Categories mismatch with allowed vocabulary: {categories_set.symmetric_difference(ALLOWED_CATEGORIES)}")

        with open(profile_fields_file, "r", encoding="utf-8") as f:
            profile_fields_data = json.load(f)
        profile_fields_set = {pf["key"] for pf in profile_fields_data.get("fields", [])}

        expected_ids = {spec["schemeId"] for spec in EXPECTED_SCHEMES_SPEC}
        found_files = list(data_dir.glob("*.json"))
        scheme_files = [p for p in found_files if not p.name.startswith("_")]
        summary["total_files"] = len(scheme_files)

        if check_all_files and len(scheme_files) != expected_count:
            all_errors.append(f"Expected {expected_count} scheme files, found {len(scheme_files)}")

        loaded_schemes = {}
        for p in scheme_files:
            scheme_id = p.stem
            if scheme_id not in expected_ids:
                all_errors.append(f"Unexpected scheme file: {p.name} not in Section 7 list")
                continue
            try:
                with open(p, "r", encoding="utf-8") as f:
                    data = json.load(f)
                loaded_schemes[scheme_id] = data
            except Exception as e:
                all_errors.append(f"Failed to read/parse {p.name}: {e}")

    # Validate each scheme
    popular_ranks = {}
    for spec in EXPECTED_SCHEMES_SPEC:
        s_id = spec["schemeId"]
        if s_id not in loaded_schemes:
            if check_all_files:
                all_errors.append(f"Missing scheme document file for: {s_id}")
            continue

        doc = loaded_schemes[s_id]
        doc_errors = validate_scheme_dict(doc, profile_fields_set, categories_set)
        if doc_errors:
            all_errors.extend(doc_errors)
        else:
            summary["valid_schemes"] += 1

        # Count levels
        gov_level = doc.get("governmentLevel")
        states = doc.get("applicableStates", [])
        if gov_level == "central":
            summary["central_count"] += 1
        elif "MP" in states:
            summary["mp_count"] += 1
        else:
            summary["other_state_count"] += 1

        if doc.get("isPopular"):
            summary["popular_count"] += 1
            rank = doc.get("popularityRank")
            popular_ranks[s_id] = rank

        if doc.get("verificationStatus") == "verified":
            summary["verified_count"] += 1
        else:
            summary["pending_count"] += 1

    # Validate popularity ranking (exact 1 to 10 for the designated popular schemes)
    if check_all_files:
        if summary["popular_count"] != 10:
            all_errors.append(f"Expected exactly 10 popular schemes, found {summary['popular_count']}")
        for expected_rank, pop_id in enumerate(POPULAR_SCHEMES_ORDER, start=1):
            actual_rank = popular_ranks.get(pop_id)
            if actual_rank != expected_rank:
                all_errors.append(f"Popular scheme {pop_id} expected rank {expected_rank}, got {actual_rank}")

    is_valid = len(all_errors) == 0
    return is_valid, all_errors, summary


def main():
    parser = argparse.ArgumentParser(description="Validate SAHAY Scheme Catalogue")
    parser.add_argument(
        "--data-dir",
        type=Path,
        default=PROJECT_ROOT / "data" / "schemes_seed",
        help="Path to seed data directory",
    )
    parser.add_argument(
        "--allow-partial",
        action="store_true",
        help="Allow validation of partial batches (<100 files)",
    )
    parser.add_argument(
        "--emulator",
        action="store_true",
        help="Validate directly against Firestore Emulator",
    )
    parser.add_argument(
        "--firestore",
        action="store_true",
        help="Validate directly against live Cloud Firestore",
    )
    parser.add_argument(
        "--project",
        type=str,
        default="demo-sahay",
        help="Google Cloud / Firebase Project ID",
    )
    args = parser.parse_args()

    db = None
    if args.emulator:
        if "FIRESTORE_EMULATOR_HOST" not in os.environ:
            os.environ["FIRESTORE_EMULATOR_HOST"] = "127.0.0.1:8080"
        from google.cloud import firestore as gc_firestore
        from google.auth.credentials import AnonymousCredentials
        db = gc_firestore.Client(project=args.project, credentials=AnonymousCredentials())
        print(f"[*] Validating against Firestore Emulator at {os.environ['FIRESTORE_EMULATOR_HOST']} (project: {args.project})")
    elif args.firestore:
        import firebase_admin
        from firebase_admin import credentials as fa_credentials, firestore as fa_firestore
        cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
        if cred_path and os.path.exists(cred_path):
            cred = fa_credentials.Certificate(cred_path)
            if not firebase_admin._apps:
                firebase_admin.initialize_app(cred, {"projectId": args.project})
        else:
            if not firebase_admin._apps:
                firebase_admin.initialize_app(options={"projectId": args.project})
        db = fa_firestore.client()
        print(f"[*] Validating against Cloud Firestore project: {args.project}")

    print("=" * 60)
    print("SAHAY Scheme Catalogue Validator (Schema v2)")
    if db is None:
        print(f"Data directory: {args.data_dir}")
    print("=" * 60)

    is_valid, errors, summary = validate_catalogue(
        args.data_dir,
        expected_count=100,
        check_all_files=not args.allow_partial,
        db=db,
    )

    print(f"Total Scheme Files Found: {summary['total_files']}")
    print(f"Valid Schemes:           {summary['valid_schemes']}")
    print(f"Central Schemes:         {summary['central_count']}")
    print(f"Madhya Pradesh Schemes:  {summary['mp_count']}")
    print(f"Other State Schemes:     {summary['other_state_count']}")
    print(f"Popular Schemes:         {summary['popular_count']}")
    print(f"Verified Schemes:        {summary['verified_count']}")
    print(f"Pending Schemes:         {summary['pending_count']}")

    if errors:
        print("\n" + "!" * 60)
        print(f"VALIDATION FAILED with {len(errors)} error(s):")
        for err in errors[:25]:
            print(f"  - {err}")
        if len(errors) > 25:
            print(f"  ... and {len(errors) - 25} more error(s).")
        print("!" * 60)
        sys.exit(1)
    else:
        print("\nCatalogue validation passed successfully!")
        sys.exit(0)


if __name__ == "__main__":
    main()

