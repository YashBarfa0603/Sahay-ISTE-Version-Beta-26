
from typing import Any, Dict, List, Optional, Tuple

STATE_CODE_TO_NAME: Dict[str, str] = {
    "AP": "Andhra Pradesh",
    "AR": "Arunachal Pradesh",
    "AS": "Assam",
    "BR": "Bihar",
    "CG": "Chhattisgarh",
    "GA": "Goa",
    "GJ": "Gujarat",
    "HR": "Haryana",
    "HP": "Himachal Pradesh",
    "JH": "Jharkhand",
    "KA": "Karnataka",
    "KL": "Kerala",
    "MP": "Madhya Pradesh",
    "MH": "Maharashtra",
    "MN": "Manipur",
    "ML": "Meghalaya",
    "MZ": "Mizoram",
    "NL": "Nagaland",
    "OD": "Odisha",
    "PB": "Punjab",
    "RJ": "Rajasthan",
    "SK": "Sikkim",
    "TN": "Tamil Nadu",
    "TS": "Telangana",
    "TR": "Tripura",
    "UP": "Uttar Pradesh",
    "UK": "Uttarakhand",
    "WB": "West Bengal",
    "DL": "Delhi",
    "JK": "Jammu and Kashmir",
    "LA": "Ladakh",
    "CH": "Chandigarh",
    "PY": "Puducherry",
    "AN": "Andaman and Nicobar Islands",
}
STATE_NAME_TO_CODE = {v.lower(): k for k, v in STATE_CODE_TO_NAME.items()}

"""
Deterministic Evidence-Based Eligibility Explanation Service for SAHAY.
Generates condition-by-condition comparisons, difference analysis, and transparent reasons.
Strictly deterministic without requiring an LLM.
"""

import locale
from typing import Any, Dict, List, Optional, Tuple

from backend.app.models.scheme_schemas import (
    EligibilityOperator,
    EligibilityRuleSchema,
    SchemeModelSchema,
)
from backend.app.schemas.eligibility_explanation_schema import (
    AlternativeSchemeSuggestion,
    ConditionComparisonDetail,
    ConditionEvaluationStatus,
    DeterministicEligibilityReport,
    DifferenceDetail,
    MissingFieldPrompt,
    OverallAssessmentVerdict,
)

# ---------------------------------------------------------------------------
# Field Metadata & Provenance Mapping
# ---------------------------------------------------------------------------

FIELD_METADATA: Dict[str, Dict[str, Any]] = {
    "age": {
        "label": "Age",
        "labelHindi": "आयु",
        "unit": "years",
        "unitHindi": "वर्ष",
        "document": "Aadhaar Card / Birth Certificate",
        "documentHindi": "आधार कार्ड / जन्म प्रमाण पत्र",
        "inputType": "number",
        "questionText": "What is your age?",
        "questionTextHindi": "आपकी आयु कितनी है?",
    },
    "annualIncome": {
        "label": "Annual Income",
        "labelHindi": "वार्षिक आय",
        "unit": "₹",
        "unitHindi": "₹",
        "isCurrency": True,
        "document": "Income Certificate",
        "documentHindi": "आय प्रमाण पत्र",
        "inputType": "number",
        "questionText": "What is your total annual household income?",
        "questionTextHindi": "आपकी कुल वार्षिक पारिवारिक आय कितनी है?",
    },
    "annualFamilyIncome": {
        "label": "Annual Family Income",
        "labelHindi": "वार्षिक पारिवारिक आय",
        "unit": "₹",
        "unitHindi": "₹",
        "isCurrency": True,
        "document": "Income Certificate (Tehsildar / SDO)",
        "documentHindi": "आय प्रमाण पत्र (तहसीलदार / एसडीएम)",
        "inputType": "number",
        "questionText": "What is your total annual family income?",
        "questionTextHindi": "आपकी कुल वार्षिक पारिवारिक आय कितनी है?",
    },
    "occupation": {
        "label": "Primary Occupation",
        "labelHindi": "मुख्य व्यवसाय",
        "document": "Occupational ID / e-Shram Card / Labour Card",
        "documentHindi": "व्यवसाय पहचान पत्र / ई-श्रम कार्ड / श्रमिक कार्ड",
        "inputType": "single_choice",
        "questionText": "What is your primary occupation?",
        "questionTextHindi": "आपका मुख्य व्यवसाय क्या है?",
    },
    "state": {
        "label": "State / Domicile",
        "labelHindi": "राज्य / मूल निवास",
        "document": "Domicile Certificate / Aadhaar Card",
        "documentHindi": "मूल निवास प्रमाण पत्र / आधार कार्ड",
        "inputType": "single_choice",
        "questionText": "Which State or Union Territory do you reside in?",
        "questionTextHindi": "आप किस राज्य या केंद्र शासित प्रदेश के निवासी हैं?",
    },
    "gender": {
        "label": "Gender",
        "labelHindi": "लिंग",
        "document": "Aadhaar Card / Voter ID",
        "documentHindi": "आधार कार्ड / मतदाता पहचान पत्र",
        "inputType": "single_choice",
        "questionText": "What is your gender?",
        "questionTextHindi": "आपका लिंग क्या है?",
    },
    "casteCategory": {
        "label": "Social / Caste Category",
        "labelHindi": "सामाजिक वर्ग / जाति",
        "document": "Caste Certificate",
        "documentHindi": "जाति प्रमाण पत्र",
        "inputType": "single_choice",
        "questionText": "What is your social / caste category?",
        "questionTextHindi": "आपका सामाजिक वर्ग या जाति क्या है?",
    },
    "residenceType": {
        "label": "Residential Area",
        "labelHindi": "निवास क्षेत्र",
        "document": "Electricity Bill / Ration Card",
        "documentHindi": "बिजली बिल / राशन कार्ड",
        "inputType": "single_choice",
        "questionText": "Do you live in a rural or urban area?",
        "questionTextHindi": "आप ग्रामीण क्षेत्र में रहते हैं या शहरी में?",
    },
    "maritalStatus": {
        "label": "Marital Status",
        "labelHindi": "वैवाहिक स्थिति",
        "document": "Marriage Certificate / Death Certificate of Spouse",
        "documentHindi": "विवाह प्रमाण पत्र / पति का मृत्यु प्रमाण पत्र",
        "inputType": "single_choice",
        "questionText": "What is your marital status?",
        "questionTextHindi": "आपकी वैवाहिक स्थिति क्या है?",
    },
    "disability": {
        "label": "Benchmark Disability (40%+)",
        "labelHindi": "दिव्यांगता (40% या अधिक)",
        "document": "UDID Card / Disability Certificate",
        "documentHindi": "यूडीआईडी कार्ड / दिव्यांगता प्रमाण पत्र",
        "inputType": "boolean",
        "questionText": "Do you have a benchmark disability of 40% or more?",
        "questionTextHindi": "क्या आप 40% या अधिक दिव्यांग हैं?",
    },
    "landOwnership": {
        "label": "Agricultural Land Holding",
        "labelHindi": "कृषि भूमि का स्वामित्व",
        "unit": "hectares",
        "unitHindi": "हेक्टेयर",
        "document": "Land Revenue Records (Khasra-Khatoni / RoR)",
        "documentHindi": "भू-अभिलेख (खसरा-खतौनी / पट्टा)",
        "inputType": "number",
        "questionText": "How much cultivable land do you own in hectares?",
        "questionTextHindi": "आपके पास कितने हेक्टेयर कृषि भूमि है?",
    },
    "ownsCultivableLand": {
        "label": "Cultivable Land Ownership",
        "labelHindi": "कृषि भूमि का स्वामित्व",
        "document": "Land Revenue Records (Khasra / Khatoni)",
        "documentHindi": "भू-अभिलेख (खसरा / खतौनी)",
        "inputType": "boolean",
        "questionText": "Do you own registered cultivable agricultural land?",
        "questionTextHindi": "क्या आपके पास पंजीकृत कृषि भूमि है?",
    },
    "hasBankAccount": {
        "label": "Bank Account",
        "labelHindi": "बैंक खाता",
        "document": "Bank Passbook / Cancelled Cheque (Aadhaar Seeded)",
        "documentHindi": "बैंक पासबुक / आधार लिंक बैंक खाता",
        "inputType": "boolean",
        "questionText": "Do you have an active Aadhaar-seeded bank account?",
        "questionTextHindi": "क्या आपके पास आधार से जुड़ा सक्रिय बैंक खाता है?",
    },
    "hasAadhaar": {
        "label": "Aadhaar Card",
        "labelHindi": "आधार कार्ड",
        "document": "Aadhaar Card",
        "documentHindi": "आधार कार्ड",
        "inputType": "boolean",
        "questionText": "Do you possess an Aadhaar card?",
        "questionTextHindi": "क्या आपके पास आधार कार्ड है?",
    },
    "bplCard": {
        "label": "BPL / Priority Ration Card",
        "labelHindi": "बीपीएल / प्राथमिकता राशन कार्ड",
        "document": "BPL Ration Card / NFSA Card",
        "documentHindi": "बीपीएल राशन कार्ड / राष्ट्रीय खाद्य सुरक्षा कार्ड",
        "inputType": "boolean",
        "questionText": "Does your family have a BPL or Priority Ration Card?",
        "questionTextHindi": "क्या आपके परिवार के पास बीपीएल या प्राथमिकता राशन कार्ड है?",
    },
    "hasPriorityRationCard": {
        "label": "Priority Ration Card",
        "labelHindi": "प्राथमिकता राशन कार्ड",
        "document": "Ration Card (NFSA / BPL / Antyodaya)",
        "documentHindi": "राशन कार्ड (अंत्योदय / बीपीएल)",
        "inputType": "boolean",
        "questionText": "Do you have an Antyodaya or Priority Ration Card?",
        "questionTextHindi": "क्या आपके पास अंत्योदय या प्राथमिकता राशन कार्ड है?",
    },
    "isVulnerableCategory": {
        "label": "Vulnerable Welfare Category",
        "labelHindi": "वंचित / प्राथमिकता वर्ग",
        "document": "Caste Certificate / BPL Card",
        "documentHindi": "जाति प्रमाण पत्र / बीपीएल कार्ड",
        "inputType": "boolean",
        "questionText": "Do you belong to SC/ST or BPL vulnerable category?",
        "questionTextHindi": "क्या आप एससी/एसटी या बीपीएल वंचित वर्ग से हैं?",
    },
    "hasFourWheeler": {
        "label": "Motorized Four-Wheeler Ownership",
        "labelHindi": "चार पहिया वाहन स्वामित्व",
        "document": "Vehicle Registration Certificate (RC)",
        "documentHindi": "वाहन पंजीयन प्रमाण पत्र (आरसी)",
        "inputType": "boolean",
        "questionText": "Does any member of your household own a motorized 4-wheeler?",
        "questionTextHindi": "क्या आपके परिवार में किसी के पास चार पहिया वाहन है?",
    },
}


def _format_currency(value: Any) -> str:
    """Formats numeric values into Indian numbering format (₹x,xx,xxx)."""
    try:
        num = float(value)
        if num.is_integer():
            int_val = int(num)
            s = str(int_val)
            if len(s) <= 3:
                return f"₹{s}"
            last_three = s[-3:]
            remaining = s[:-3]
            groups = []
            while len(remaining) > 2:
                groups.insert(0, remaining[-2:])
                remaining = remaining[:-2]
            if remaining:
                groups.insert(0, remaining)
            return f"₹{','.join(groups)},{last_three}"
        return f"₹{num:,.2f}"
    except (ValueError, TypeError):
        return str(value)


def _format_value_for_display(field: str, val: Any) -> str:
    """Converts a raw value to user-friendly display string."""
    if val is None:
        return "Not Provided"
    meta = FIELD_METADATA.get(field, {})
    if meta.get("isCurrency"):
        return _format_currency(val)
    if isinstance(val, bool):
        return "Yes" if val else "No"
    unit = meta.get("unit")
    if unit:
        return f"{val} {unit}"
    if isinstance(val, str):
        return val.replace("_", " ").title()
    return str(val)


def _format_requirement_string(rule: EligibilityRuleSchema) -> Tuple[str, str]:
    """Generates standard human-readable requirement descriptions in English and Hindi."""
    field = rule.field
    meta = FIELD_METADATA.get(field, {})
    field_label = meta.get("label", field.replace("_", " ").title())
    field_label_hi = meta.get("labelHindi", field_label)
    op = rule.operator
    val = rule.value

    if op in [EligibilityOperator.lessThanOrEqual, EligibilityOperator.lessThan]:
        if meta.get("isCurrency"):
            req_en = f"At most {_format_currency(val)}"
            req_hi = f"अधिकतम {_format_currency(val)}"
        else:
            unit = meta.get("unit", "")
            req_en = f"At most {val} {unit}".strip()
            req_hi = f"अधिकतम {val} {meta.get('unitHindi', unit)}".strip()
        return req_en, req_hi

    if op in [EligibilityOperator.greaterThanOrEqual, EligibilityOperator.greaterThan]:
        unit = meta.get("unit", "")
        req_en = f"At least {val} {unit}".strip()
        req_hi = f"न्यूनतम {val} {meta.get('unitHindi', unit)}".strip()
        return req_en, req_hi

    if op == EligibilityOperator.equals:
        disp = _format_value_for_display(field, val)
        return f"Must be {disp}", f"{disp} होना आवश्यक है"

    if op == EligibilityOperator.notEquals:
        disp = _format_value_for_display(field, val)
        return f"Must not be {disp}", f"{disp} नहीं होना चाहिए"

    if op == EligibilityOperator.inList:
        list_vals = val if isinstance(val, list) else [val]
        disp_list = ", ".join(_format_value_for_display(field, v) for v in list_vals)
        return f"One of: {disp_list}", f"इनमें से एक: {disp_list}"

    if op == EligibilityOperator.notInList:
        list_vals = val if isinstance(val, list) else [val]
        disp_list = ", ".join(_format_value_for_display(field, v) for v in list_vals)
        return f"Excluded: {disp_list}", f"वर्जित: {disp_list}"

    if op == EligibilityOperator.isTrue:
        return "Must be applicable (Yes)", "लागू होना आवश्यक है (हाँ)"

    if op == EligibilityOperator.isFalse:
        return "Must not be applicable (No)", "लागू नहीं होना चाहिए (नहीं)"

    return rule.description or f"{op.value} {val}", rule.description or f"{op.value} {val}"


# ---------------------------------------------------------------------------
# Core Explanation Generation Service
# ---------------------------------------------------------------------------

class EligibilityExplanationService:
    """
    Evaluates scheme conditions and generates evidence-based, transparent explanations.
    Strictly deterministic and ground-truth verified.
    """

    def normalize_answers(self, user_answers: Dict[str, Any]) -> Dict[str, Any]:
        """Preserves and normalizes user answers across synonyms and inferences."""
        norm = dict(user_answers)

        # 1. landOwnership -> ownsCultivableLand
        if "ownsCultivableLand" not in norm and "landOwnership" in norm:
            try:
                if float(norm["landOwnership"]) > 0:
                    norm["ownsCultivableLand"] = True
            except (ValueError, TypeError):
                pass

        # 2. isExServiceman -> isDependentOfExServiceman
        if "isDependentOfExServiceman" not in norm and "isExServiceman" in norm:
            norm["isDependentOfExServiceman"] = bool(norm["isExServiceman"])

        # 3. SC/ST / BPL -> isVulnerableCategory
        if "isVulnerableCategory" not in norm:
            caste = str(norm.get("casteCategory", "")).lower()
            has_priority = norm.get("hasPriorityRationCard") is True or norm.get("bplCard") is True
            if caste in ["sc", "st"] or has_priority:
                norm["isVulnerableCategory"] = True

        # 4. Bank Account / Aadhaar -> hasAadhaarOrIdProof
        if "hasAadhaarOrIdProof" not in norm:
            if norm.get("hasBankAccount") is True or norm.get("hasAadhaar") is True:
                norm["hasAadhaarOrIdProof"] = True

        # 5. Senior citizen 70+ qualifies for PM-JAY
        if "hasPriorityRationCard" not in norm and "age" in norm:
            try:
                if float(norm["age"]) >= 70:
                    norm["hasPriorityRationCard"] = True
            except (ValueError, TypeError):
                pass

        # 6. Motorized vehicle & four-wheeler synonyms
        for key_a, key_b in [
            ("hasFourWheeler", "hasMotorizedVehicle"),
            ("hasMotorizedVehicle", "hasFourWheeler"),
            ("hasFourWheeler", "ownsFourWheeler"),
            ("ownsFourWheeler", "hasFourWheeler"),
        ]:
            if key_a not in norm and key_b in norm:
                norm[key_a] = norm[key_b]

        # 7. Unify annualIncome and annualFamilyIncome
        if "annualFamilyIncome" not in norm and "annualIncome" in norm:
            norm["annualFamilyIncome"] = norm["annualIncome"]
        if "annualIncome" not in norm and "annualFamilyIncome" in norm:
            norm["annualIncome"] = norm["annualFamilyIncome"]

        # 8. Synthesize demographic & occupational flags from survey answers
        occ = str(norm.get("occupation", "")).lower()
        if "isFarmer" not in norm:
            if occ == "farmer" or norm.get("ownsCultivableLand") is True:
                norm["isFarmer"] = True
        if "isStudent" not in norm and occ == "student":
            norm["isStudent"] = True
        if "isStreetVendor" not in norm and occ == "street_vendor":
            norm["isStreetVendor"] = True
        if "isConstructionWorker" not in norm and occ == "construction_worker":
            norm["isConstructionWorker"] = True
        if "isArtisan" not in norm and occ in ["artisan_craftsperson", "artisan"]:
            norm["isArtisan"] = True
        if "isUnorganizedWorker" not in norm:
            if occ in ["unorganized_worker", "construction_worker", "street_vendor", "agricultural_worker", "artisan_craftsperson"]:
                norm["isUnorganizedWorker"] = True

        # Government employment exclusion check
        if "isGovtEmployee" not in norm and occ:
            norm["isGovtEmployee"] = occ in ["government_employee", "salaried_govt"]

        # Income tax payer exclusion check
        if "isTaxpayer" not in norm:
            try:
                inc = float(norm.get("annualFamilyIncome", 0))
                if inc > 0:
                    norm["isTaxpayer"] = inc > 300000  # Below basic exemption limit in India
            except (ValueError, TypeError):
                pass

        # Gender & Age derived flags
        gender = str(norm.get("gender", "")).lower()
        if "isWoman" not in norm and gender == "female":
            norm["isWoman"] = True

        age = norm.get("age")
        if age is not None:
            try:
                age_num = float(age)
                if "isSeniorCitizen" not in norm:
                    norm["isSeniorCitizen"] = age_num >= 60
                if "isYouth" not in norm:
                    norm["isYouth"] = 18 <= age_num <= 35
            except (ValueError, TypeError):
                pass

        return norm

    def evaluate_condition_detailed(
        self,
        rule: EligibilityRuleSchema,
        norm_answers: Dict[str, Any],
    ) -> ConditionComparisonDetail:
        """Evaluates an individual rule and builds structured condition-by-condition evidence."""
        field = rule.field
        meta = FIELD_METADATA.get(field, {})
        label = meta.get("label", field.replace("_", " ").title())
        label_hi = meta.get("labelHindi", label)
        req_en, req_hi = _format_requirement_string(rule)
        doc_en = meta.get("document", "Official Certificate / Proof")
        doc_hi = meta.get("documentHindi", "आधिकारिक प्रमाण पत्र")

        has_value = field in norm_answers and norm_answers[field] is not None
        actual_val = norm_answers.get(field)

        # 1. Handle Missing Information
        if not has_value:
            reason_en = f"Information for {label} has not been provided. Please provide this detail to verify eligibility."
            reason_hi = f"{label_hi} की जानकारी उपलब्ध नहीं है। पात्रता की पुष्टि के लिए कृपया यह विवरण प्रदान करें।"
            return ConditionComparisonDetail(
                field=field,
                label=label,
                labelHindi=label_hi,
                required=req_en,
                requiredHindi=req_hi,
                userValue=None,
                formattedUserValue="Not Provided",
                status=ConditionEvaluationStatus.missing,
                isMandatory=rule.isMandatory,
                isBorderline=False,
                reason=reason_en,
                reasonHindi=reason_hi,
                difference=None,
                sourceUrl=getattr(rule, "sourceUrl", None),
                sourceQuote=getattr(rule, "sourceQuote", None),
                verifyingDocument=doc_en,
                verifyingDocumentHindi=doc_hi,
                verificationStatus="self_reported",
            )

        formatted_user = _format_value_for_display(field, actual_val)
        op = rule.operator
        expected_val = rule.value

        # 2. Evaluate Operators & Calculate Numerical / String Differences
        satisfied = False
        is_borderline = False
        difference: Optional[DifferenceDetail] = None
        reason_en = ""
        reason_hi = ""

        # Numeric comparisons
        if op in [
            EligibilityOperator.lessThan,
            EligibilityOperator.lessThanOrEqual,
            EligibilityOperator.greaterThan,
            EligibilityOperator.greaterThanOrEqual,
        ]:
            try:
                num_actual = float(actual_val)
                num_expected = float(expected_val)
                diff = abs(num_actual - num_expected)

                # Borderline check (within 10% threshold)
                denom = num_expected if num_expected != 0 else 1.0
                if abs(diff) / denom <= 0.10:
                    is_borderline = True

                if op == EligibilityOperator.lessThan:
                    satisfied = num_actual < num_expected
                elif op == EligibilityOperator.lessThanOrEqual:
                    satisfied = num_actual <= num_expected
                elif op == EligibilityOperator.greaterThan:
                    satisfied = num_actual > num_expected
                elif op == EligibilityOperator.greaterThanOrEqual:
                    satisfied = num_actual >= num_expected

                # Build differences and explanations
                if satisfied:
                    if op in [EligibilityOperator.lessThan, EligibilityOperator.lessThanOrEqual]:
                        reason_en = f"Your reported {label.lower()} ({formatted_user}) is within the prescribed limit of {req_en.lower()}."
                        reason_hi = f"आपकी {label_hi} ({formatted_user}) निर्धारित सीमा ({req_hi}) के अंतर्गत है।"
                    else:
                        reason_en = f"Your {label.lower()} ({formatted_user}) satisfies the minimum requirement of {req_en.lower()}."
                        reason_hi = f"आपकी {label_hi} ({formatted_user}) न्यूनतम आवश्यकता ({req_hi}) को पूरा करती है।"
                else:
                    if op in [EligibilityOperator.lessThan, EligibilityOperator.lessThanOrEqual]:
                        over_amount = num_actual - num_expected
                        diff_formatted = _format_currency(over_amount) if meta.get("isCurrency") else f"{over_amount:g} {meta.get('unit', '')}".strip()
                        difference = DifferenceDetail(
                            amount=over_amount,
                            description=f"{diff_formatted} above the prescribed limit",
                        )
                        reason_en = (
                            f"Your reported {label.lower()} is {formatted_user}, which exceeds the scheme's limit of "
                            f"{_format_currency(num_expected) if meta.get('isCurrency') else num_expected} by {diff_formatted}."
                        )
                        reason_hi = (
                            f"आपकी {label_hi} {formatted_user} है, जो योजना की निर्धारित सीमा "
                            f"({_format_currency(num_expected) if meta.get('isCurrency') else num_expected}) से {diff_formatted} अधिक है।"
                        )
                    else:
                        under_amount = num_expected - num_actual
                        diff_formatted = f"{under_amount:g} {meta.get('unit', '')}".strip()
                        difference = DifferenceDetail(
                            amount=under_amount,
                            description=f"{diff_formatted} below the minimum required limit",
                        )
                        reason_en = (
                            f"Your {label.lower()} is {formatted_user}, which is below the minimum required limit of "
                            f"{expected_val} {meta.get('unit', '')} (difference: {diff_formatted})."
                        )
                        reason_hi = (
                            f"आपकी {label_hi} {formatted_user} है, जो न्यूनतम आवश्यक सीमा "
                            f"({expected_val} {meta.get('unitHindi', meta.get('unit', ''))}) से कम है।"
                        )
            except (ValueError, TypeError):
                satisfied = False
                reason_en = f"Unable to perform numeric comparison for {label} (actual={actual_val}, expected={expected_val})."
                reason_hi = f"{label_hi} के लिए संख्यात्मक तुलना नहीं की जा सकी।"

        # Equality comparisons
        elif op == EligibilityOperator.equals:
            satisfied = str(actual_val).strip().lower() == str(expected_val).strip().lower()
            if satisfied:
                reason_en = f"Your {label.lower()} ({formatted_user}) matches the scheme's eligible {label.lower()} requirement."
                reason_hi = f"आपका {label_hi} ({formatted_user}) योजना की पात्रता आवश्यकता से मेल खाता है।"
            else:
                expected_disp = _format_value_for_display(field, expected_val)
                reason_en = f"The scheme requires {label.lower()} to be {expected_disp}, but your reported {label.lower()} is {formatted_user}."
                reason_hi = f"योजना के अनुसार {label_hi} '{expected_disp}' होना आवश्यक है, जबकि आपका विवरण '{formatted_user}' है।"

        # Non-equality
        elif op == EligibilityOperator.notEquals:
            satisfied = str(actual_val).strip().lower() != str(expected_val).strip().lower()
            if satisfied:
                reason_en = f"Your {label.lower()} is not in the excluded category ({expected_val})."
                reason_hi = f"आपका {label_hi} अपवर्जित श्रेणी में नहीं है।"
            else:
                reason_en = f"Your {label.lower()} matches the excluded category ({expected_val})."
                reason_hi = f"आपका {label_hi} अपवर्जित श्रेणी ({expected_val}) से मेल खाता है।"

        # In-List
        elif op == EligibilityOperator.inList:
            expected_list = expected_val if isinstance(expected_val, list) else [expected_val]
            actual_norm = str(actual_val).strip().lower()
            # If checking state, expand state codes to full names and vice versa
            expanded_expected = []
            for e in expected_list:
                e_str = str(e).strip()
                expanded_expected.append(e_str.lower())
                if e_str.upper() in STATE_CODE_TO_NAME:
                    expanded_expected.append(STATE_CODE_TO_NAME[e_str.upper()].lower())
            if actual_norm in STATE_NAME_TO_CODE:
                actual_code = STATE_NAME_TO_CODE[actual_norm].lower()
                satisfied = actual_norm in expanded_expected or actual_code in expanded_expected
            else:
                satisfied = actual_norm in expanded_expected
            disp_list = ", ".join(_format_value_for_display(field, e) for e in expected_list)
            if satisfied:
                reason_en = f"Your {label.lower()} ({formatted_user}) is included in the scheme's eligible categories."
                reason_hi = f"आपका {label_hi} ({formatted_user}) योजना की पात्र श्रेणियों में शामिल है।"
            else:
                reason_en = f"Your {label.lower()} '{formatted_user}' is not in the eligible categories ({disp_list})."
                reason_hi = f"आपका {label_hi} '{formatted_user}' पात्र श्रेणियों ({disp_list}) में शामिल नहीं है।"

        # Not-In-List
        elif op == EligibilityOperator.notInList:
            expected_list = expected_val if isinstance(expected_val, list) else [expected_val]
            satisfied = not any(str(actual_val).strip().lower() == str(e).strip().lower() for e in expected_list)
            if satisfied:
                reason_en = f"Your {label.lower()} is not in the excluded list."
                reason_hi = f"आपका {label_hi} अपवर्जित सूची में नहीं है।"
            else:
                reason_en = f"Your {label.lower()} '{formatted_user}' is in the scheme's excluded list."
                reason_hi = f"आपका {label_hi} '{formatted_user}' अपवर्जित सूची में है।"

        # Boolean
        elif op == EligibilityOperator.isTrue:
            satisfied = bool(actual_val) is True
            if satisfied:
                reason_en = f"You satisfy the mandatory confirmation requirement for {label.lower()}."
                reason_hi = f"आप {label_hi} की अनिवार्य पुष्टि आवश्यकता को पूरा करते हैं।"
            else:
                reason_en = f"Requirement not satisfied: {label} is required to be confirmed as Yes."
                reason_hi = f"आवश्यकता पूरी नहीं हुई: {label_hi} की पुष्टि आवश्यक है।"

        elif op == EligibilityOperator.isFalse:
            satisfied = bool(actual_val) is False
            if satisfied:
                reason_en = f"You meet the non-exclusion criteria for {label.lower()}."
                reason_hi = f"आप {label_hi} के गैर-अपवर्जन मानदंड को पूरा करते हैं।"
            else:
                reason_en = f"Condition triggers exclusion: {label} must not be present."
                reason_hi = f"शर्त अपवर्जन उत्पन्न करती है: {label_hi} लागू नहीं होना चाहिए।"

        status = ConditionEvaluationStatus.satisfied if satisfied else ConditionEvaluationStatus.not_satisfied

        return ConditionComparisonDetail(
            field=field,
            label=label,
            labelHindi=label_hi,
            required=req_en,
            requiredHindi=req_hi,
            userValue=actual_val,
            formattedUserValue=formatted_user,
            status=status,
            isMandatory=rule.isMandatory,
            isBorderline=is_borderline,
            reason=reason_en,
            reasonHindi=reason_hi,
            difference=difference,
            sourceUrl=getattr(rule, "sourceUrl", None),
            sourceQuote=getattr(rule, "sourceQuote", None),
            verifyingDocument=doc_en,
            verifyingDocumentHindi=doc_hi,
            verificationStatus="self_reported",
        )

    def evaluate_scheme(
        self,
        scheme: SchemeModelSchema,
        user_answers: Dict[str, Any],
        catalog_schemes: Optional[List[SchemeModelSchema]] = None,
    ) -> DeterministicEligibilityReport:
        """
        Executes a complete evidence-based assessment for a single scheme.
        Evaluates mandatory, optional, and complex logical groups deterministically.
        """
        norm_answers = self.normalize_answers(user_answers)
        rules = scheme.eligibilityRules or []

        # Geographic residency pre-check if applicableStates is non-empty
        app_states = scheme.applicableStates or []
        state_rules: List[EligibilityRuleSchema] = []
        # If applicableStates has "ALL_INDIA" or is empty, it is a national scheme open to all states
        is_all_india = not app_states or any(s.upper() == "ALL_INDIA" for s in app_states)
        if app_states and not is_all_india and not any(r.field == "state" for r in rules):
            state_rules.append(
                EligibilityRuleSchema(
                    field="state",
                    operator=EligibilityOperator.inList,
                    value=app_states,
                    isMandatory=True,
                    description=f"Must be a resident of: {', '.join(app_states)}",
                )
            )

        all_rules_to_eval = state_rules + rules

        if not all_rules_to_eval:
            return DeterministicEligibilityReport(
                schemeId=scheme.schemeId,
                schemeName=scheme.name,
                schemeNameHindi=scheme.nameHindi,
                verdict=OverallAssessmentVerdict.needs_more_information,
                summaryExplanation="This scheme currently has no verified automated rules configured and requires manual departmental verification.",
                summaryExplanationHindi="इस योजना के लिए वर्तमान में कोई सत्यापित स्वचालित नियम कॉन्फ़िगर नहीं हैं।",
                disclaimer="SAHAY provides indicative assessments based on self-reported profile data. Official eligibility is confirmed solely by the designated government authority.",
                disclaimerHindi="सहाय स्व-घोषित विवरण के आधार पर सांकेतिक आकलन प्रदान करता है। आधिकारिक स्वीकृति संबंधित सरकारी विभाग द्वारा दी जाती है।",
            )

        all_conditions: List[ConditionComparisonDetail] = []
        satisfied_conditions: List[ConditionComparisonDetail] = []
        unsatisfied_conditions: List[ConditionComparisonDetail] = []
        missing_conditions: List[ConditionComparisonDetail] = []
        optional_conditions: List[ConditionComparisonDetail] = []
        missing_prompts: List[MissingFieldPrompt] = []

        mandatory_total = 0
        mandatory_satisfied = 0
        optional_total = 0
        optional_satisfied = 0
        has_failed_mandatory = False
        has_missing_mandatory = False

        for rule in all_rules_to_eval:
            cond = self.evaluate_condition_detailed(rule, norm_answers)
            all_conditions.append(cond)

            if rule.isMandatory:
                mandatory_total += 1
                if cond.status == ConditionEvaluationStatus.satisfied:
                    mandatory_satisfied += 1
                    satisfied_conditions.append(cond)
                elif cond.status == ConditionEvaluationStatus.not_satisfied:
                    has_failed_mandatory = True
                    unsatisfied_conditions.append(cond)
                elif cond.status == ConditionEvaluationStatus.missing:
                    has_missing_mandatory = True
                    missing_conditions.append(cond)
                    meta = FIELD_METADATA.get(rule.field, {})
                    missing_prompts.append(
                        MissingFieldPrompt(
                            field=rule.field,
                            label=cond.label,
                            labelHindi=cond.labelHindi,
                            questionText=meta.get("questionText", f"Please provide {cond.label}."),
                            questionTextHindi=meta.get("questionTextHindi", f"कृपया {cond.labelHindi} प्रदान करें।"),
                            inputType=meta.get("inputType", "text"),
                            options=meta.get("options"),
                            reasonNeeded=cond.required,
                        )
                    )
            else:
                optional_total += 1
                optional_conditions.append(cond)
                if cond.status == ConditionEvaluationStatus.satisfied:
                    optional_satisfied += 1
                elif cond.status == ConditionEvaluationStatus.missing:
                    missing_conditions.append(cond)

        # -----------------------------------------------------------------------
        # Determine Overall Verdict
        # -----------------------------------------------------------------------
        if has_failed_mandatory:
            verdict = OverallAssessmentVerdict.does_not_appear_to_qualify
        elif has_missing_mandatory:
            verdict = OverallAssessmentVerdict.needs_more_information
        elif mandatory_satisfied == mandatory_total:
            verdict = OverallAssessmentVerdict.may_qualify
        else:
            verdict = OverallAssessmentVerdict.does_not_appear_to_qualify

        # -----------------------------------------------------------------------
        # Generate Deterministic Plain-Language Summary
        # -----------------------------------------------------------------------
        summary_en, summary_hi = self._generate_summary_explanation(
            scheme_name=scheme.name,
            verdict=verdict,
            satisfied=satisfied_conditions,
            unsatisfied=unsatisfied_conditions,
            missing=missing_conditions,
        )

        # -----------------------------------------------------------------------
        # Required Documents to Verify
        # -----------------------------------------------------------------------
        docs_en: List[str] = []
        docs_hi: List[str] = []
        for cond in satisfied_conditions:
            if cond.verifyingDocument and cond.verifyingDocument not in docs_en:
                docs_en.append(cond.verifyingDocument)
            if cond.verifyingDocumentHindi and cond.verifyingDocumentHindi not in docs_hi:
                docs_hi.append(cond.verifyingDocumentHindi)

        # Include official required documents
        for d in scheme.requiredDocuments or []:
            if d not in docs_en:
                docs_en.append(d)

        # -----------------------------------------------------------------------
        # Next Steps
        # -----------------------------------------------------------------------
        next_steps_en = [
            f"Collect and verify required documents ({', '.join(docs_en[:3]) if docs_en else 'Aadhaar / Identity Proof'}).",
            f"Apply online at {scheme.officialSourceUrl or 'the official government portal'} or visit your nearest Common Service Centre (CSC / Jan Seva Kendra).",
            "Keep the application acknowledgment number safe for status tracking.",
        ]
        next_steps_hi = [
            f"आवश्यक दस्तावेज एकत्र करें ({', '.join(docs_hi[:3]) if docs_hi else 'आधार कार्ड / पहचान प्रमाण'})।",
            f"आधिकारिक पोर्टल ({scheme.officialSourceUrl or 'सरकारी वेबसाइट'}) पर ऑनलाइन आवेदन करें या नजदीकी जन सेवा केंद्र (CSC) पर जाएं।",
            "स्थिति ट्रैकिंग के लिए आवेदन पावती संख्या सुरक्षित रखें।",
        ]

        # -----------------------------------------------------------------------
        # Find Alternative Schemes if user does not qualify
        # -----------------------------------------------------------------------
        alternatives: List[AlternativeSchemeSuggestion] = []
        if verdict == OverallAssessmentVerdict.does_not_appear_to_qualify and catalog_schemes:
            alternatives = self._find_alternatives(scheme, norm_answers, catalog_schemes)

        return DeterministicEligibilityReport(
            schemeId=scheme.schemeId,
            schemeName=scheme.name,
            schemeNameHindi=scheme.nameHindi,
            verdict=verdict,
            summaryExplanation=summary_en,
            summaryExplanationHindi=summary_hi,
            mandatorySatisfiedCount=mandatory_satisfied,
            mandatoryTotalCount=mandatory_total,
            optionalSatisfiedCount=optional_satisfied,
            optionalTotalCount=optional_total,
            conditions=all_conditions,
            satisfiedConditions=satisfied_conditions,
            unsatisfiedConditions=unsatisfied_conditions,
            missingConditions=missing_conditions,
            optionalConditions=optional_conditions,
            missingFieldPrompts=missing_prompts,
            alternativeSchemes=alternatives,
            requiredDocumentsToVerify=docs_en,
            requiredDocumentsToVerifyHindi=docs_hi,
            nextSteps=next_steps_en,
            nextStepsHindi=next_steps_hi,
            disclaimer="SAHAY provides indicative assessments based on self-reported profile data. Official eligibility and approval are granted solely by designated government authorities upon physical document verification.",
            disclaimerHindi="सहाय स्व-घोषित विवरण के आधार पर सांकेतिक आकलन प्रदान करता है। आधिकारिक स्वीकृति संबंधित सरकारी विभाग द्वारा भौतिक दस्तावेज सत्यापन के बाद ही दी जाती है।",
        )

    def _generate_summary_explanation(
        self,
        scheme_name: str,
        verdict: OverallAssessmentVerdict,
        satisfied: List[ConditionComparisonDetail],
        unsatisfied: List[ConditionComparisonDetail],
        missing: List[ConditionComparisonDetail],
    ) -> Tuple[str, str]:
        """Generates clear, empathetic, and condition-grounded summary paragraphs."""
        if verdict == OverallAssessmentVerdict.may_qualify:
            sat_reasons = "; ".join(f"{c.label}: {c.formattedUserValue} (matches {c.required})" for c in satisfied)
            summary_en = (
                f"Based on the information you provided, you appear to satisfy all mandatory eligibility conditions "
                f"for {scheme_name}. Satisfied conditions: {sat_reasons}."
            )
            summary_hi = (
                f"आपके द्वारा प्रदान की गई जानकारी के आधार पर, आप {scheme_name} के लिए सभी अनिवार्य पात्रता शर्तों "
                f"को पूरा करते प्रतीत होते हैं।"
            )
            return summary_en, summary_hi

        if verdict == OverallAssessmentVerdict.does_not_appear_to_qualify:
            failed_reasons_en = "; ".join(f"{c.reason}" for c in unsatisfied)
            failed_reasons_hi = "; ".join(f"{c.reasonHindi or c.reason}" for c in unsatisfied)
            sat_notes_en = f" You satisfied {len(satisfied)} other condition(s)." if satisfied else ""
            sat_notes_hi = f" आपने अन्य {len(satisfied)} शर्तों को पूरा किया है।" if satisfied else ""
            summary_en = (
                f"You do not currently appear to meet the eligibility requirements for {scheme_name}. "
                f"Reason: {failed_reasons_en}.{sat_notes_en}"
            )
            summary_hi = (
                f"आप वर्तमान में {scheme_name} की पात्रता आवश्यकताओं को पूरा करते प्रतीत नहीं होते हैं। "
                f"कारण: {failed_reasons_hi}.{sat_notes_hi}"
            )
            return summary_en, summary_hi

        # Needs more info
        missing_names_en = ", ".join(c.label for c in missing)
        missing_names_hi = ", ".join(c.labelHindi or c.label for c in missing)
        summary_en = (
            f"Additional information is required to assess your eligibility for {scheme_name}. "
            f"Please provide details for: {missing_names_en}."
        )
        summary_hi = (
            f"{scheme_name} के लिए आपकी पात्रता का आकलन करने के लिए अतिरिक्त जानकारी की आवश्यकता है। "
            f"कृपया निम्नलिखित विवरण प्रदान करें: {missing_names_hi}।"
        )
        return summary_en, summary_hi

    def _find_alternatives(
        self,
        failed_scheme: SchemeModelSchema,
        norm_answers: Dict[str, Any],
        catalog_schemes: List[SchemeModelSchema],
    ) -> List[AlternativeSchemeSuggestion]:
        """Identifies active schemes in the same category where the citizen appears to qualify."""
        alternatives: List[AlternativeSchemeSuggestion] = []
        target_category = failed_scheme.category.lower()

        for cand in catalog_schemes:
            if cand.schemeId == failed_scheme.schemeId:
                continue
            if cand.category.lower() != target_category and not cand.isPopular:
                continue

            # Quick check if candidate's mandatory rules are satisfied
            cand_rules = cand.eligibilityRules or []
            if not cand_rules:
                continue

            all_passed = True
            for r in cand_rules:
                if not r.isMandatory:
                    continue
                cond = self.evaluate_condition_detailed(r, norm_answers)
                if cond.status != ConditionEvaluationStatus.satisfied:
                    all_passed = False
                    break

            if all_passed:
                reason = f"Alternative {cand.category.title()} scheme matching your profile."
                reason_hi = f"आपकी प्रोफ़ाइल से मेल खाने वाली वैकल्पिक {cand.category} योजना।"
                alternatives.append(
                    AlternativeSchemeSuggestion(
                        schemeId=cand.schemeId,
                        schemeName=cand.name,
                        schemeNameHindi=cand.nameHindi,
                        category=cand.category,
                        reasonWhyRelevant=reason,
                        reasonWhyRelevantHindi=reason_hi,
                    )
                )
                if len(alternatives) >= 3:
                    break

        return alternatives
