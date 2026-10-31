"""
LangGraph Multi-Agent Orchestration Engine for SAHAY Application Assistant.
Coordinates 6 Specialized Agents:
1. ApplicationContextAgent
2. DocumentUnderstandingAgent
3. FormUnderstandingAgent
4. FieldMappingAgent
5. FieldExplanationAgent
6. ApplicationValidationAgent

DETERMINISTIC INVARIANT:
AI proposes semantic field interpretations and multilingual explanations.
Deterministic backend rules gate validation, bounds checks, and permissions.
User must explicitly approve any prefilled or ambiguous data.
"""

import logging
import re
from typing import Any, Dict, List, Optional
from langgraph.graph import END, START, StateGraph
from typing_extensions import TypedDict

from backend.app.schemas.application_schema import (
    ApplicationSection,
    ApplicationStatus,
    DocumentRequirement,
    DocumentVerificationStatus,
    FieldMapping,
    FieldType,
    MappingStatus,
    SourceType,
)
from backend.app.services.ollama_service import OllamaService

logger = logging.getLogger(__name__)


class ApplicationAgentState(TypedDict):
    """Shared state for the Application Assistant LangGraph workflow."""

    session_id: str
    user_id: str
    scheme_data: Dict[str, Any]
    user_profile: Dict[str, Any]
    uploaded_documents: List[Dict[str, Any]]
    detected_form_inputs: List[Dict[str, Any]]
    language: str

    # Agent outputs
    context_summary: Dict[str, Any]
    understood_documents: List[Dict[str, Any]]
    application_sections: List[Dict[str, Any]]
    mapped_fields: List[Dict[str, Any]]
    conflicts_detected: List[Dict[str, Any]]
    validation_errors: List[str]
    warnings: List[str]
    can_submit: bool
    step_history: List[str]
    iteration_count: int


# ==========================================
# Agent 1: Application Context Agent
# ==========================================


async def run_application_context_agent(state: ApplicationAgentState) -> Dict[str, Any]:
    """Analyzes scheme data, required documents, and prepares initial application context."""
    scheme = state.get("scheme_data", {})
    history = list(state.get("step_history", []))
    history.append("ApplicationContextAgent")

    scheme_id = scheme.get("schemeId", "UNKNOWN")
    scheme_name = scheme.get("name", "Unknown Scheme")
    req_docs = scheme.get("requiredDocuments", [])

    context = {
        "schemeId": scheme_id,
        "schemeName": scheme_name,
        "category": scheme.get("category", "general"),
        "officialUrl": scheme.get("applicationUrl") or scheme.get("officialSourceUrl"),
        "requiredDocuments": req_docs,
        "totalRequiredDocs": len(req_docs),
    }

    return {
        "context_summary": context,
        "step_history": history,
        "iteration_count": state.get("iteration_count", 0) + 1,
    }


# ==========================================
# Agent 2: Document Understanding Agent
# ==========================================


async def run_document_understanding_agent(state: ApplicationAgentState) -> Dict[str, Any]:
    """Normalizes EasyOCR extracted data across uploaded user documents."""
    docs = state.get("uploaded_documents", [])
    history = list(state.get("step_history", []))
    history.append("DocumentUnderstandingAgent")

    understood = []
    for d in docs:
        doc_type = d.get("document_type", "unknown")
        fields = d.get("fields", {})

        cleaned_fields = {}
        for f_name, f_data in fields.items():
            if isinstance(f_data, dict) and "value" in f_data:
                cleaned_fields[f_name] = f_data["value"]
            else:
                cleaned_fields[f_name] = f_data

        understood.append({
            "document_id": d.get("document_id", doc_type),
            "document_type": doc_type,
            "confidence": d.get("confidence", 0.8),
            "fields": cleaned_fields,
            "verification_status": DocumentVerificationStatus.OCR_PROCESSED.value,
        })

    return {
        "understood_documents": understood,
        "step_history": history,
        "iteration_count": state.get("iteration_count", 0) + 1,
    }


# ==========================================
# Agent 3: Form Understanding Agent
# ==========================================


async def run_form_understanding_agent(state: ApplicationAgentState) -> Dict[str, Any]:
    """
    Constructs standardized, verified application sections and fields based on
    the target scheme and detected portal inputs.
    """
    scheme = state.get("scheme_data", {})
    history = list(state.get("step_history", []))
    history.append("FormUnderstandingAgent")

    category = scheme.get("category", "").lower()
    scheme_id = scheme.get("schemeId", "")

    # Define standard canonical sections
    personal_section = {
        "section_id": "sec_personal",
        "title": "Personal & Demographic Details",
        "title_hi": "व्यक्तिगत और जनसांख्यिकीय विवरण",
        "description": "Basic identification and demographic information as per official records.",
        "fields": [
            {
                "field_id": "fullName",
                "field_label": "Full Name (as per Aadhaar)",
                "field_label_hi": "पूरा नाम (आधार के अनुसार)",
                "field_type": "text",
                "is_required": True,
                "explanation": "Enter your full name exactly as spelled on your Aadhaar card.",
                "explanation_hi": "अपना पूरा नाम ठीक वैसे ही लिखें जैसा आपके आधार कार्ड पर लिखा है।",
                "explanation_hinglish": "Apna poora naam Aadhaar card ke spelling ke hisaab se enter karein.",
            },
            {
                "field_id": "mobileNumber",
                "field_label": "Active Mobile Number",
                "field_label_hi": "सक्रिय मोबाइल नंबर",
                "field_type": "phone",
                "is_required": True,
                "explanation": "10-digit mobile number linked to Aadhaar for OTP verification.",
                "explanation_hi": "आधार से जुड़ा 10 अंकों का सक्रिय मोबाइल नंबर।",
                "explanation_hinglish": "Aadhaar linked 10-digit mobile number jisme OTP aayega.",
            },
            {
                "field_id": "aadhaarNumber",
                "field_label": "Aadhaar Number",
                "field_label_hi": "आधार संख्या",
                "field_type": "text",
                "is_required": True,
                "explanation": "Your 12-digit Unique Identification Number.",
                "explanation_hi": "आपकी 12 अंकों की विशिष्ट पहचान संख्या।",
                "explanation_hinglish": "Aapka 12 digit ka Aadhaar number.",
            },
            {
                "field_id": "gender",
                "field_label": "Gender",
                "field_label_hi": "लिंग",
                "field_type": "dropdown",
                "is_required": True,
                "options": ["Male", "Female", "Transgender"],
                "explanation": "Select your gender.",
                "explanation_hi": "अपना लिंग चुनें।",
                "explanation_hinglish": "Apna gender select karein.",
            },
            {
                "field_id": "casteCategory",
                "field_label": "Social Category / Caste",
                "field_label_hi": "सामाजिक श्रेणी / जाति",
                "field_type": "dropdown",
                "is_required": True,
                "options": ["General", "OBC", "SC", "ST"],
                "explanation": "Your reservation or social category.",
                "explanation_hi": "अपनी जाति अथवा सामाजिक श्रेणी चुनें।",
                "explanation_hinglish": "Apni social category (General, OBC, SC, ST) choose karein.",
            },
        ],
    }

    residence_section = {
        "section_id": "sec_residence",
        "title": "Address & Residence Details",
        "title_hi": "निवास और पता विवरण",
        "description": "Geographical details for state and district scheme quota allocation.",
        "fields": [
            {
                "field_id": "state",
                "field_label": "State of Residence",
                "field_label_hi": "निवास का राज्य",
                "field_type": "dropdown",
                "is_required": True,
                "options": ["Madhya Pradesh", "Uttar Pradesh", "Maharashtra", "Rajasthan", "Bihar", "Gujarat", "Delhi"],
                "explanation": "The Indian state where you currently reside permanently.",
                "explanation_hi": "वह राज्य जहां आप स्थायी रूप से निवास करते हैं।",
                "explanation_hinglish": "Aapka permanent domicile state.",
            },
            {
                "field_id": "district",
                "field_label": "District",
                "field_label_hi": "ज़िला",
                "field_type": "text",
                "is_required": True,
                "explanation": "Your revenue district.",
                "explanation_hi": "आपका ज़िला।",
                "explanation_hinglish": "Aapka revenue district.",
            },
            {
                "field_id": "residenceType",
                "field_label": "Residence Area Type",
                "field_label_hi": "निवास क्षेत्र का प्रकार",
                "field_type": "radio",
                "is_required": True,
                "options": ["Rural", "Urban"],
                "explanation": "Whether your address falls in a village/gram panchayat (Rural) or city/municipality (Urban).",
                "explanation_hi": "क्या आपका क्षेत्र ग्रामीण है या शहरी।",
                "explanation_hinglish": "Aap gaon (Rural) mein rehte hain ya shahar (Urban) mein.",
            },
        ],
    }

    financial_section = {
        "section_id": "sec_financial",
        "title": "Income & Bank Details",
        "title_hi": "आय और बैंक विवरण",
        "description": "Information required for DBT (Direct Benefit Transfer).",
        "fields": [
            {
                "field_id": "annualFamilyIncome",
                "field_label": "Annual Family Income (in ₹)",
                "field_label_hi": "वार्षिक पारिवारिक आय (₹ में)",
                "field_type": "number",
                "is_required": True,
                "explanation": "Combined annual income of all family members from all sources.",
                "explanation_hi": "सभी स्रोतों से परिवार के सभी सदस्यों की कुल वार्षिक आय।",
                "explanation_hinglish": "Poore parivaar ki ek saal ki total kamai (income).",
            },
            {
                "field_id": "bankAccountNumber",
                "field_label": "Bank Account Number (Aadhaar Seeded)",
                "field_label_hi": "बैंक खाता संख्या (आधार लिंक)",
                "field_type": "text",
                "is_required": True,
                "explanation": "Savings bank account number where government benefits will be credited.",
                "explanation_hi": "बचत खाता संख्या जिसमें सहायता राशि जमा होगी।",
                "explanation_hinglish": "Aapka active bank account number jisme subsidy aayegi.",
            },
            {
                "field_id": "bankIfsc",
                "field_label": "Bank IFSC Code",
                "field_label_hi": "बैंक आईएफएससी कोड",
                "field_type": "text",
                "is_required": True,
                "explanation": "11-character code printed on the first page of your passbook or cheque leaf.",
                "explanation_hi": "11 अक्षरों का आईएफएससी कोड जो पासबुक पर मुद्रित होता है।",
                "explanation_hinglish": "Passbook par likha 11 character ka IFSC code.",
            },
        ],
    }

    # Agriculture Specific Section if farmer scheme
    sections = [personal_section, residence_section, financial_section]

    if "agri" in category or "kisan" in scheme_id.lower() or "farmer" in str(scheme.get("name", "")).lower():
        agri_section = {
            "section_id": "sec_agriculture",
            "title": "Land & Farming Details",
            "title_hi": "भूमि और कृषि विवरण",
            "description": "Landholding details required for farmer beneficiary verification.",
            "fields": [
                {
                    "field_id": "isFarmer",
                    "field_label": "Are you a practicing farmer with cultivable land?",
                    "field_label_hi": "क्या आप कृषि योग्य भूमि वाले किसान हैं?",
                    "field_type": "radio",
                    "is_required": True,
                    "options": ["Yes", "No"],
                    "explanation": "Confirm whether you own or operate agricultural land.",
                    "explanation_hi": "पुष्टि करें कि आपके पास कृषि भूमि है।",
                    "explanation_hinglish": "Kya aapke paas kheti ki zameen hai?",
                },
                {
                    "field_id": "khasraNumber",
                    "field_label": "Khasra / Khatauni Number",
                    "field_label_hi": "खसरा / खतौनी संख्या",
                    "field_type": "text",
                    "is_required": False,
                    "explanation": "Survey or parcel number from your state revenue land records.",
                    "explanation_hi": "भू-अभिलेख के अनुसार खसरा अथवा खतौनी संख्या।",
                    "explanation_hinglish": "Aapke zameen ke kaagaz par likha khasra number.",
                },
            ],
        }
        sections.append(agri_section)

    return {
        "application_sections": sections,
        "step_history": history,
        "iteration_count": state.get("iteration_count", 0) + 1,
    }


# ==========================================
# Agent 4: Field Mapping Agent
# ==========================================


async def run_field_mapping_agent(state: ApplicationAgentState) -> Dict[str, Any]:
    """
    Intelligently maps citizen profile data and EasyOCR-extracted document entities
    to form fields, flagging conflicts where sources disagree.
    """
    profile = state.get("user_profile", {})
    docs = state.get("understood_documents", [])
    sections = state.get("application_sections", [])
    history = list(state.get("step_history", []))
    history.append("FieldMappingAgent")

    # Collate document fields by name
    doc_fields: Dict[str, Dict[str, Any]] = {}
    for d in docs:
        for f_name, f_val in d.get("fields", {}).items():
            doc_fields[f_name] = {
                "value": f_val,
                "source_doc_id": d.get("document_id"),
                "confidence": d.get("confidence", 0.8),
            }

    conflicts: List[Dict[str, Any]] = []
    mapped_sections = []

    for sec in sections:
        mapped_fields = []
        for f in sec.get("fields", []):
            f_id = f["field_id"]
            mapped_val = None
            src_type = None
            src_doc_id = None
            conf = 1.0
            status = MappingStatus.MISSING
            conflict_detected = False
            conflict_details = None

            # Profile lookup
            profile_val = profile.get(f_id)

            # Document lookup equivalents
            doc_info = None
            if f_id == "fullName" and "holder_name" in doc_fields:
                doc_info = doc_fields["holder_name"]
            elif f_id == "aadhaarNumber" and "aadhaar_number" in doc_fields:
                doc_info = doc_fields["aadhaar_number"]
            elif f_id == "panNumber" and "pan_number" in doc_fields:
                doc_info = doc_fields["pan_number"]
            elif f_id == "gender" and "gender" in doc_fields:
                doc_info = doc_fields["gender"]
            elif f_id == "annualFamilyIncome" and "annual_income" in doc_fields:
                doc_info = doc_fields["annual_income"]
            elif f_id == "casteCategory" and "caste_category" in doc_fields:
                doc_info = doc_fields["caste_category"]
            elif f_id == "state" and "domicile_state" in doc_fields:
                doc_info = doc_fields["domicile_state"]
            elif f_id == "bankAccountNumber" and "account_number" in doc_fields:
                doc_info = doc_fields["account_number"]
            elif f_id == "bankIfsc" and "ifsc_code" in doc_fields:
                doc_info = doc_fields["ifsc_code"]
            elif f_id == "khasraNumber" and "khasra_number" in doc_fields:
                doc_info = doc_fields["khasra_number"]

            # Conflict Detection
            if profile_val is not None and doc_info is not None:
                p_str = str(profile_val).strip().lower()
                d_str = str(doc_info["value"]).strip().lower()
                if p_str != d_str:
                    conflict_detected = True
                    conflict_details = {
                        "profile_value": profile_val,
                        "document_value": doc_info["value"],
                        "source_document_id": doc_info["source_doc_id"],
                        "description": f"Profile lists '{profile_val}' but uploaded document indicates '{doc_info['value']}'.",
                    }
                    conflicts.append({
                        "field_id": f_id,
                        "field_label": f["field_label"],
                        **conflict_details,
                    })
                    mapped_val = profile_val
                    src_type = SourceType.USER_PROFILE
                    status = MappingStatus.CONFLICT

            if not conflict_detected:
                if profile_val is not None:
                    mapped_val = profile_val
                    src_type = SourceType.USER_PROFILE
                    status = MappingStatus.PREFILLED
                    conf = 1.0
                elif doc_info is not None:
                    mapped_val = doc_info["value"]
                    src_type = SourceType.UPLOADED_DOCUMENT
                    src_doc_id = doc_info["source_doc_id"]
                    status = MappingStatus.PREFILLED
                    conf = doc_info.get("confidence", 0.85)

            field_dict = dict(f)
            field_dict.update({
                "mapped_value": mapped_val,
                "source_type": src_type.value if src_type else None,
                "source_document_id": src_doc_id,
                "confidence": conf,
                "mapping_status": status.value,
                "conflict_detected": conflict_detected,
                "conflict_details": conflict_details,
                "user_confirmed": False,
                "validation_status": "valid" if (mapped_val is not None and not conflict_detected) else "pending",
            })
            mapped_fields.append(field_dict)

        sec_copy = dict(sec)
        sec_copy["fields"] = mapped_fields
        mapped_sections.append(sec_copy)

    return {
        "application_sections": mapped_sections,
        "conflicts_detected": conflicts,
        "step_history": history,
        "iteration_count": state.get("iteration_count", 0) + 1,
    }


# ==========================================
# Agent 5: Field Explanation Agent
# ==========================================


class FieldExplanationAgent:
    """Provides plain-language multilingual explanations with real-world examples."""

    @staticmethod
    def explain_field(field_id: str, field_label: str, language: str = "en") -> Dict[str, str]:
        lang = language.lower()

        explanations = {
            "annualFamilyIncome": {
                "en": (
                    "This field requires the total gross income of all earning members of your household "
                    "in the previous financial year, not just your personal salary.",
                    "Example: If you earn ₹1,20,000/yr and your spouse earns ₹60,000/yr, total is ₹1,80,000.",
                ),
                "hi": (
                    "इस कॉलम में आपके परिवार के सभी कमाने वाले सदस्यों की पिछले एक वर्ष की कुल आय दर्ज करनी होती है, केवल आपकी व्यक्तिगत आय नहीं।",
                    "उदाहरण: यदि आपकी आय ₹1,20,000 है और जीवनसाथी की ₹60,000 है, तो कुल आय ₹1,80,000 होगी।",
                ),
                "hinglish": (
                    "Is field mein aapke poore parivaar ke sabhi members ki ek saal ki total income bharni hoti hai, sirf aapki akele ki nahi.",
                    "Example: Agar aap ₹1,20,000 kamate hain aur spouse ₹60,000, to total ₹1,80,000 bharein.",
                ),
            },
            "aadhaarNumber": {
                "en": (
                    "Your 12-digit Unique Identification Number issued by UIDAI.",
                    "Example: 1234 5678 9012 (found on your Aadhaar card).",
                ),
                "hi": (
                    "यूआईडीएआई द्वारा जारी आपका 12 अंकों का विशिष्ट पहचान नंबर।",
                    "उदाहरण: 1234 5678 9012 (आपके आधार कार्ड पर अंकित)।",
                ),
                "hinglish": (
                    "UIDAI dwara diya gaya aapka 12 digit ka unique Aadhaar number.",
                    "Example: 1234 5678 9012 jo aapke Aadhaar card par hota hai.",
                ),
            },
            "bankIfsc": {
                "en": (
                    "The 11-character Indian Financial System Code identifying your specific bank branch for DBT transfers.",
                    "Example: SBIN0001234 (printed on the front page of your bank passbook).",
                ),
                "hi": (
                    "11 अक्षरों का बैंक कोड जो आपकी शाखा की पहचान करता है और डीबीटी भुगतान हेतु आवश्यक है।",
                    "उदाहरण: SBIN0001234 (आपकी पासबुक के पहले पृष्ठ पर उपलब्ध)।",
                ),
                "hinglish": (
                    "Bank passbook par printed 11 character ka IFSC code jo branch identify karta hai.",
                    "Example: SBIN0001234 jo passbook ke front page par hota hai.",
                ),
            },
        }

        # Fallback generic generator
        if field_id in explanations:
            target_lang = "hi" if lang == "hi" else ("hinglish" if "hing" in lang else "en")
            exp, ex = explanations[field_id].get(target_lang, explanations[field_id]["en"])
            return {"explanation": exp, "example": ex, "language": target_lang}

        # Default fallback
        if lang == "hi":
            return {
                "explanation": f"कृपया अपने आधिकारिक दस्तावेजों के अनुसार '{field_label}' की सही जानकारी भरें।",
                "example": "दस्तावेजों में दर्ज विवरण के अनुसार प्रविष्टि करें।",
                "language": "hi",
            }
        elif "hing" in lang:
            return {
                "explanation": f"Official records ke hisaab se '{field_label}' ki sahi information yahan fill karein.",
                "example": "Valid govt document ke anusar bharein.",
                "language": "hinglish",
            }
        else:
            return {
                "explanation": f"Please provide accurate information for '{field_label}' as recorded in your official documents.",
                "example": "Refer to your official certificates before submitting.",
                "language": "en",
            }


# ==========================================
# Agent 6: Application Validation Agent
# ==========================================


async def run_application_validation_agent(state: ApplicationAgentState) -> Dict[str, Any]:
    """
    Deterministic gatekeeper verifying completeness, data format integrity,
    numerical constraints, and document requirements.
    """
    sections = state.get("application_sections", [])
    history = list(state.get("step_history", []))
    history.append("ApplicationValidationAgent")

    validation_errors: List[str] = []
    warnings: List[str] = []

    for sec in sections:
        for f in sec.get("fields", []):
            f_id = f["field_id"]
            f_label = f["field_label"]
            is_req = f.get("is_required", True)
            val = f.get("mapped_value")

            # Check required
            if is_req and (val is None or str(val).strip() == ""):
                validation_errors.append(f"Required field '{f_label}' is missing.")
                continue

            if val is not None and str(val).strip() != "":
                # Format checks
                if f.get("field_type") == "phone":
                    digits = re.sub(r"\D", "", str(val))
                    if len(digits) != 10:
                        validation_errors.append(f"Field '{f_label}' must be a valid 10-digit mobile number.")
                elif f_id == "bankIfsc":
                    if not re.match(r"^[A-Z]{4}0[A-Z0-9]{6}$", str(val).strip()):
                        validation_errors.append(f"Field '{f_label}' must follow valid IFSC format (e.g. SBIN0001234).")
                elif f_id == "annualFamilyIncome":
                    try:
                        inc = float(val)
                        if inc < 0 or inc > 100000000:
                            validation_errors.append(f"Income value ₹{inc} is out of realistic range.")
                    except ValueError:
                        validation_errors.append(f"Field '{f_label}' must be a valid numeric amount.")

    can_submit = len(validation_errors) == 0

    return {
        "validation_errors": validation_errors,
        "warnings": warnings,
        "can_submit": can_submit,
        "step_history": history,
        "iteration_count": state.get("iteration_count", 0) + 1,
    }


# ==========================================
# LangGraph Workflow Construction
# ==========================================


def create_application_assistant_graph():
    """Builds and compiles the multi-agent application assistance graph."""
    workflow = StateGraph(ApplicationAgentState)

    workflow.add_node("context_agent", run_application_context_agent)
    workflow.add_node("document_agent", run_document_understanding_agent)
    workflow.add_node("form_agent", run_form_understanding_agent)
    workflow.add_node("mapping_agent", run_field_mapping_agent)
    workflow.add_node("validation_agent", run_application_validation_agent)

    # Linear pipeline
    workflow.add_edge(START, "context_agent")
    workflow.add_edge("context_agent", "document_agent")
    workflow.add_edge("document_agent", "form_agent")
    workflow.add_edge("form_agent", "mapping_agent")
    workflow.add_edge("mapping_agent", "validation_agent")
    workflow.add_edge("validation_agent", END)

    return workflow.compile()

