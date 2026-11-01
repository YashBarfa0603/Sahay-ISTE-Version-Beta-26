"""
SAHAY Assistance AI Chatbot Service.
Provides conversational in-app guidance, screen-aware support, grounded scheme assistance,
contextual quick prompts, verified navigation actions, and multilingual processing.

Architectural Guarantees:
1. Distinct from Fill with SAHAY: Explains and guides, but does not execute portal DOM manipulation.
2. Grounded Truth: Never hallucinates fake eligibility criteria or nonexistent application numbers.
3. Privacy Invariant: Never requests or stores sensitive credentials (passwords, OTPs, PINs).
4. Graceful Fallback: Runs deterministic rule-based knowledge engine when Ollama/Qwen2.5 is unavailable.
"""

import json
import logging
import re
import uuid
from typing import Any, Dict, List, Optional, Tuple

import httpx

from backend.app.config import settings
from backend.app.schemas.chatbot_schema import (
    ChatbotMessageRequest,
    ChatbotMessageResponse,
    ContextPromptsResponse,
    NavigationAction,
)
from backend.app.services.portal_adapter_service import PortalAdapterService

logger = logging.getLogger(__name__)


# ==============================================================================
# Grounded SAHAY Knowledge Base
# ==============================================================================

SAHAY_KNOWLEDGE_BASE = {
    "about_sahay": {
        "en": (
            "**SAHAY (सहाय)** is an AI-powered public welfare platform designed to help Indian citizens "
            "discover, verify eligibility for, and apply to central and state government schemes.\n\n"
            "Key capabilities:\n"
            "• **Scheme Discovery:** Find schemes across Agriculture, Housing, Education, Health, MSME, and Social Welfare.\n"
            "• **Eligibility Engine:** Answer questions to see which welfare benefits you qualify for.\n"
            "• **Document Vault:** Securely store documents (Aadhaar, Income Certificate, etc.) with automatic OCR parsing.\n"
            "• **Fill with SAHAY:** Intelligent 7-stage application assistant that fills supported portal fields."
        ),
        "hi": (
            "**सहाय (SAHAY)** एक एआई-संचालित जन-कल्याणकारी प्लेटफ़ॉर्म है जो भारतीय नागरिकों को केंद्र और राज्य "
            "सरकार की योजनाओं की खोज करने, पात्रता जांचने और आवेदन करने में मदद करता है।\n\n"
            "प्रमुख विशेषताएं:\n"
            "• **योजना खोज:** कृषि, आवास, शिक्षा, स्वास्थ्य, और व्यवसाय से जुड़ी योजनाएं खोजें।\n"
            "• **पात्रता जांच:** कुछ आसान सवालों के जवाब देकर अपनी पात्रता जानें।\n"
            "• **दस्तावेज़ वॉल्ट (Document Vault):** आय प्रमाण पत्र, आधार आदि सुरक्षित रखें और स्वतः विवरण प्राप्त करें।\n"
            "• **सहाय के साथ फॉर्म भरें (Fill with SAHAY):** सरकारी पोर्टल पर समर्थित फ़ील्ड्स भरने में मदद करता है।"
        ),
    },
    "fill_with_sahay": {
        "en": (
            "**Fill with SAHAY** is an intelligent scheme-specific application assistant. When you select 'Fill with SAHAY' "
            "from the How to Apply section of a scheme, SAHAY guides you through 7 transparent stages:\n\n"
            "1. **Preparation:** Analyzes scheme requirements and checks your uploaded documents.\n"
            "2. **Information Review:** Shows data gathered from your profile and document OCR, highlighting any discrepancies.\n"
            "3. **Missing Information:** Asks only the necessary scheme-specific questions.\n"
            "4. **Portal Autofill:** Loads the official portal in a secure WebView and populates supported form inputs.\n"
            "5. **Validation:** Reads back populated DOM values and verifies data integrity.\n"
            "6. **Final Review:** Presents full summary for your explicit review and confirmation.\n"
            "7. **Submission Status:** Tracks official submission only after your personal approval.\n\n"
            "⚠️ **Protected Actions:** You must personally complete OTP verification, CAPTCHA, and legal declarations. "
            "SAHAY never bypasses government security controls or submits without your explicit consent."
        ),
        "hi": (
            "**सहाय के साथ फॉर्म भरें (Fill with SAHAY)** एक बुद्धिमान आवेदन सहायक है। 'How to Apply' सेक्शन से इसे चुनने पर, "
            "सहाय आपको 7 पारदर्शी चरणों के माध्यम से मार्गदर्शन करता है:\n\n"
            "1. **तैयारी (Preparation):** योजना की आवश्यकताओं और आपके दस्तावेज़ों की जांच करता है।\n"
            "2. **जानकारी समीक्षा (Info Review):** प्रोफ़ाइल और दस्तावेज़ों से मिली जानकारी दिखाता है।\n"
            "3. **अधूरी जानकारी (Missing Info):** केवल आवश्यक छूटे हुए प्रश्न पूछता है।\n"
            "4. **पोर्टल ऑटो-फिल (Portal Autofill):** आधिकारिक पोर्टल पर समर्थित फ़ील्ड्स भरता है।\n"
            "5. **सत्यापन (Validation):** भरे गए डेटा की पोर्टल से जांच करता है।\n"
            "6. **अंतिम समीक्षा (Final Review):** आपकी अंतिम स्वीकृति के लिए पूर्ण विवरण प्रस्तुत करता है।\n"
            "7. **आवेदन स्थिति (Submission Status):** आपके व्यक्तिगत अनुमोदन के बाद ही स्थिति दर्ज करता है।\n\n"
            "⚠️ **सुरक्षा:** OTP, कैप्चा (CAPTCHA) और कानूनी घोषणाएं आपको स्वयं भरनी होती हैं।"
        ),
    },
    "document_vault": {
        "en": (
            "The **Document Vault (दस्तावेज़ वॉल्ट)** is your personal, secure digital locker inside SAHAY:\n\n"
            "• Store essential documents: Aadhaar Card, Income Certificate, Caste Certificate, Domicile, Bank Passbook, Ration Card, Samagra ID, etc.\n"
            "• **EasyOCR & AI Processing:** SAHAY automatically extracts key data (such as annual income, certificate numbers, and dates) so you don't have to retype them.\n"
            "• **Cloudinary Encrypted Storage:** Documents are securely stored with role-restricted access.\n"
            "• Uploading a document helps Fill with SAHAY pre-fill official forms instantly."
        ),
        "hi": (
            "**दस्तावेज़ वॉल्ट (Document Vault)** सहाय के भीतर आपका सुरक्षित डिजिटल लॉकर है:\n\n"
            "• अपने आवश्यक दस्तावेज़ रखें: आधार कार्ड, आय प्रमाण पत्र, जाति प्रमाण पत्र, मूल निवास, बैंक पासबुक, राशन कार्ड आदि।\n"
            "• **OCR और AI तकनीक:** सहाय स्वचालित रूप से आय, नाम, जन्मतिथि और प्रमाण पत्र संख्या निकाल लेता है।\n"
            "• **सुरक्षित संग्रहण:** आपके दस्तावेज़ पूरी तरह सुरक्षित और एन्क्रिप्टेड रहते हैं।\n"
            "• दस्तावेज़ अपलोड करने से 'Fill with SAHAY' स्वतः फ़ील्ड भरने में सक्षम होता है।"
        ),
    },
    "eligibility_engine": {
        "en": (
            "The **Eligibility Assessment** evaluates your qualifications for welfare programs without storing sensitive data:\n\n"
            "• Answer quick demographic questions (State, Age, Gender, Category, Annual Income, Occupation, Land ownership).\n"
            "• SAHAY evaluates deterministic business rules from official government guidelines.\n"
            "• Statuses shown: **Eligible (पात्र)**, **May Qualify (शर्तों के अधीन)**, or **Ineligible (अपात्र)** with clear explanations."
        ),
        "hi": (
            "**पात्रता मूल्यांकन (Eligibility Assessment)** आपकी योग्यता की जांच करता है:\n\n"
            "• कुछ आसान प्रश्नों के उत्तर दें (राज्य, आयु, लिंग, वर्ग, वार्षिक आय, व्यवसाय, भूमि विवरण)।\n"
            "• सहाय आधिकारिक सरकारी दिशानिर्देशों के आधार पर आपकी पात्रता की गणना करता है।\n"
            "• परिणाम: **पात्र (Eligible)**, **संभावित पात्र (May Qualify)**, या **अपात्र (Ineligible)** स्पष्ट कारण सहित दिखाई देता है।"
        ),
    },
    "security_and_privacy": {
        "en": (
            "**Privacy and Security Principles:**\n\n"
            "• **Zero Secret Exposure:** SAHAY never stores or shares passwords, OTPs, or biometrics.\n"
            "• **No Automated Submissions:** Applications are never submitted without your final, explicit review and tap.\n"
            "• **Official Portals Only:** Form filling connects strictly to verified `.gov.in` and `.nic.in` domains.\n"
            "• **Citizen in Full Control:** You can cancel, review, or edit details at any stage."
        ),
        "hi": (
            "**गोपनीयता और सुरक्षा सिद्धांत:**\n\n"
            "• **सुरक्षित और निजी:** सहाय कभी भी पासवर्ड, ओटीपी या बायोमेट्रिक्स संग्रहीत नहीं करता है।\n"
            "• **कोई स्वतः सबमिशन नहीं:** आपकी स्पष्ट स्वीकृति के बिना कोई भी आवेदन अंतिम रूप से सबमिट नहीं होता।\n"
            "• **केवल आधिकारिक पोर्टल:** फॉर्म भरना केवल सत्यापित सरकारी (.gov.in / .nic.in) पोर्टल्स पर होता है।\n"
            "• **नागरिक का पूर्ण नियंत्रण:** आप किसी भी चरण पर जानकारी देख और बदल सकते हैं।"
        ),
    },
    "ten_supported_schemes": {
        "en": (
            "The SAHAY Smart Application Filler currently provides dedicated assistance for **10 major schemes**:\n\n"
            "1. **PM-KISAN Samman Nidhi** (₹6,000/year farmer income support)\n"
            "2. **PMAY-U 2.0** (Pradhan Mantri Awas Yojana – Urban housing subsidy)\n"
            "3. **e-Shram Registration** (National Database of Unorganised Workers & social security)\n"
            "4. **Udyam Registration** (Free official MSME certification & benefits)\n"
            "5. **PM Surya Ghar: Muft Bijli Yojana** (Rooftop solar subsidy up to ₹78,000)\n"
            "6. **PM SVANidhi** (Collateral-free working capital loan for street vendors)\n"
            "7. **PMEGP** (Credit-linked subsidy for new micro-enterprises up to 35%)\n"
            "8. **MP Post-Matric Scholarship** (SC/ST/OBC higher education scholarship on MP TAAS)\n"
            "9. **AICTE Pragati Scholarship** (₹50,000/year for girls in technical degree/diploma)\n"
            "10. **AICTE Saksham Scholarship** (₹50,000/year for specially-abled technical students)"
        ),
        "hi": (
            "सहाय स्मार्ट एप्लिकेशन फिलर वर्तमान में **10 प्रमुख योजनाओं** के लिए समर्पित सहायता प्रदान करता है:\n\n"
            "1. **पीएम किसान सम्मान निधि** (किसानों को ₹6,000 वार्षिक सहायता)\n"
            "2. **पीएम आवास योजना 2.0 (PMAY-U)** (शहरी पक्के मकान के लिए सब्सिडी)\n"
            "3. **ई-श्रम पंजीकरण (e-Shram)** (असंगठित श्रमिकों के लिए सामाजिक सुरक्षा कार्ड)\n"
            "4. **उद्यम पंजीकरण (Udyam)** (सूक्ष्म, लघु एवं मध्यम उद्योगों के लिए निःशुल्क प्रमाण पत्र)\n"
            "5. **पीएम सूर्य घर: मुफ्त बिजली योजना** (सोलर रूफटॉप पर ₹78,000 तक की सब्सिडी)\n"
            "6. **पीएम स्वनिधि (PM SVANidhi)** (रेहड़ी-पटरी वालों के लिए ब्याज-सब्सिडी ऋण)\n"
            "7. **PMEGP योजना** (सूक्ष्म उद्यमों के लिए 35% तक मार्जिन मनी सब्सिडी)\n"
            "8. **मध्य प्रदेश पोस्ट-मैट्रिक छात्रवृत्ति** (MP TAAS पोर्टल पर उच्च शिक्षा छात्रवृत्ति)\n"
            "9. **एआईसीटीई प्रगति छात्रवृत्ति (AICTE Pragati)** (तकनीकी छात्राओं को ₹50,000 वार्षिक)\n"
            "10. **एआईसीटीई सक्षम छात्रवृत्ति (AICTE Saksham)** (दिव्यांग छात्रों को ₹50,000 वार्षिक)"
        ),
    },
}

# Scheme-specific knowledge details
SCHEME_QUICK_FACTS = {
    "PM_KISAN_001": {
        "en": "PM-KISAN provides ₹6,000 per year in three 4-monthly installments of ₹2,000 to landholding farmer families. Required documents: Aadhaar card, bank passbook, and land ownership records (Khasra/Khatauni). Manual step: Visual CAPTCHA & Aadhaar OTP.",
        "hi": "पीएम किसान योजना के तहत पात्र किसान परिवारों को ₹2,000 की तीन किस्तों में ₹6,000 प्रति वर्ष मिलते हैं। आवश्यक दस्तावेज़: आधार कार्ड, बैंक पासबुक और खसरा/खतौनी। आवश्यक व्यक्तिगत चरण: विज़ुअल कैप्चा और आधार ओटीपी।",
    },
    "PMAY_002": {
        "en": "PMAY-U 2.0 provides interest subsidy and financial assistance for pucca houses to EWS/LIG families in urban areas. Required documents: Aadhaar, income certificate, bank details, and urban residence proof. Manual step: Mobile OTP & Aadhaar e-KYC.",
        "hi": "पीएम आवास योजना (शहरी 2.0) शहरी ईडब्ल्यूएस/एलआईजी परिवारों को पक्के घर हेतु ब्याज सब्सिडी व सहायता देती है। आवश्यक दस्तावेज़: आधार, आय प्रमाण पत्र, बैंक खाता व स्थानीय निवास प्रमाण। व्यक्तिगत चरण: मोबाइल ओटीपी और ई-केवाईसी।",
    },
    "E_SHRAM_001": {
        "en": "e-Shram provides a 12-digit Universal Account Number (UAN) and social security benefits to unorganised workers aged 16-59. Required documents: Aadhaar card, active mobile number linked with Aadhaar, and bank account. Manual step: Aadhaar OTP & CAPTCHA.",
        "hi": "ई-श्रम 16 से 59 वर्ष के असंगठित कामगारों को 12 अंकों का यूएएन कार्ड और सामाजिक सुरक्षा लाभ प्रदान करता है। आवश्यक दस्तावेज़: आधार कार्ड, आधार से जुड़ा मोबाइल नंबर और बैंक खाता। व्यक्तिगत चरण: आधार ओटीपी।",
    },
    "UDYAM_001": {
        "en": "Udyam Registration is the official, free online registration for Micro, Small and Medium Enterprises (MSMEs). Required documents: Aadhaar of owner/promoter, PAN card, and GSTIN (if applicable). Manual step: Aadhaar OTP verification.",
        "hi": "उद्यम पंजीकरण एमएसएमई उद्योगों के लिए भारत सरकार का आधिकारिक निःशुल्क रजिस्ट्रेशन है। आवश्यक दस्तावेज़: प्रोप्राइटर का आधार कार्ड, पैन कार्ड और जीएसटी। व्यक्तिगत चरण: आधार ओटीपी सत्यापन।",
    },
    "PM_SURYA_GHAR_001": {
        "en": "PM Surya Ghar provides up to ₹78,000 central subsidy for installing 1-3 kW rooftop solar panels, delivering up to 300 units of free electricity monthly. Required documents: Electricity bill, consumer number, Aadhaar, and bank passbook. Manual step: Mobile OTP.",
        "hi": "पीएम सूर्य घर योजना 1 से 3 किलोवाट सोलर रूफटॉप पर ₹78,000 तक की सब्सिडी देती है, जिससे 300 यूनिट तक मुफ्त बिजली मिलती है। आवश्यक दस्तावेज़: नवीनतम बिजली बिल, उपभोक्ता संख्या, आधार और बैंक पासबुक।",
    },
    "PM_SVANIDHI_001": {
        "en": "PM SVANidhi offers collateral-free micro-credit starting at ₹10,000 up to ₹50,000 with 7% interest subsidy for street vendors. Required documents: Certificate of Vending (CoV), Vendor ID card, Aadhaar, and bank passbook. Manual step: Mobile OTP verification.",
        "hi": "पीएम स्वनिधि रेहड़ी-पटरी विक्रेताओं को ₹10,000 से ₹50,000 तक का संपार्श्विक-मुक्त ऋण 7% ब्याज सब्सिडी के साथ देती है। आवश्यक दस्तावेज़: वेंडिंग प्रमाण पत्र/पहचान पत्र, आधार और बैंक पासबुक।",
    },
    "PMEGP_001": {
        "en": "PMEGP provides credit-linked margin money subsidy up to 35% on bank loans for setting up new micro-enterprises up to ₹50 lakh. Required documents: Project report, Aadhaar, PAN card, educational certificate, and caste certificate. Manual step: Portal registration & OTP.",
        "hi": "पीएमईजीपी नए सूक्ष्म उद्यम शुरू करने के लिए बैंकों से ₹50 लाख तक के ऋण पर 15% से 35% तक मार्जिन मनी सब्सिडी प्रदान करती है। आवश्यक दस्तावेज़: प्रोजेक्ट रिपोर्ट, आधार, पैन, शैक्षणिक योग्यता और जाति प्रमाण पत्र।",
    },
    "MP_POST_MATRIC_SCHOLARSHIP_SC_ST_001": {
        "en": "MP Post-Matric Scholarship reimburses course tuition fees and maintenance allowance for SC/ST/OBC students pursuing higher education in Madhya Pradesh via MP TAAS. Required documents: MP Samagra ID, Domicile certificate, Caste certificate, Income certificate, and Admission fee receipt.",
        "hi": "मध्य प्रदेश पोस्ट-मैट्रिक छात्रवृत्ति एमपी तास (MP TAAS) पोर्टल पर उच्च शिक्षा ले रहे एससी/एसटी/ओबीसी छात्रों को शिक्षण शुल्क व भत्ता देती है। आवश्यक दस्तावेज़: समग्र आईडी, मूल निवास प्रमाण पत्र, जाति प्रमाण पत्र, आय प्रमाण पत्र और कॉलेज प्रवेश रसीद।",
    },
    "AICTE_PRAGATI_001": {
        "en": "AICTE Pragati Scholarship provides ₹50,000 per year towards tuition and college expenses for girl students admitted to first year AICTE-approved technical degree or diploma courses with family income ≤ ₹8 lakh. Required documents: Admission letter, 10th/12th marksheet, Income certificate, and Aadhaar.",
        "hi": "एआईसीटीई प्रगति छात्रवृत्ति एआईसीटीई-मान्यता प्राप्त डिग्री या डिप्लोमा में प्रवेशित छात्राओं को ₹50,000 वार्षिक देती है (पारिवारिक आय ₹8 लाख तक)। आवश्यक दस्तावेज़: कॉलेज प्रवेश पत्र, अंकसूची, आय प्रमाण पत्र और आधार कार्ड।",
    },
    "AICTE_SAKSHAM_001": {
        "en": "AICTE Saksham Scholarship awards ₹50,000 per year to specially-abled students with disability ≥ 40% admitted to technical degree or diploma courses with family income ≤ ₹8 lakh. Required documents: Disability certificate (UDID), Admission receipt, Income certificate, and Aadhaar.",
        "hi": "एआईसीटीई सक्षम छात्रवृत्ति 40% या अधिक दिव्यांगता वाले तकनीकी छात्रों को ₹50,000 प्रति वर्ष सहायता देती है (पारिवारिक आय ₹8 लाख तक)। आवश्यक दस्तावेज़: दिव्यांगता प्रमाण पत्र (UDID), प्रवेश रसीद, आय प्रमाण पत्र और आधार कार्ड।",
    },
}


class ChatbotService:
    """Core service powering the SAHAY Assistance AI Chatbot."""

    def __init__(self, ollama_base_url: Optional[str] = None, ollama_model: Optional[str] = None):
        self.ollama_base_url = (ollama_base_url or settings.OLLAMA_BASE_URL).rstrip("/")
        self.ollama_model = ollama_model or settings.OLLAMA_MODEL
        self.portal_service = PortalAdapterService()

    # ==========================================================================
    # Context-Aware Suggested Prompts
    # ==========================================================================

    def get_contextual_prompts(
        self,
        current_screen: Optional[str] = None,
        selected_scheme_id: Optional[str] = None,
        language: str = "en",
    ) -> ContextPromptsResponse:
        """Emits targeted quick prompts tailored to the user's active screen and scheme."""
        screen = (current_screen or "home").lower()
        is_hi = language.startswith("hi")

        welcome_message = (
            "नमस्ते! मैं सहाय सहायक (SAHAY Assistance) हूँ। मैं ऐप की सुविधाओं, योजनाओं और आवेदन में आपकी सहायता कर सकता हूँ।"
            if is_hi
            else "Namaste! Welcome to SAHAY Assistance. I can help you understand the app, discover schemes, manage documents, and prepare applications."
        )

        questions: List[str] = []

        if screen in ["scheme_detail", "how_to_apply"]:
            if is_hi:
                questions = [
                    "क्या सहाय इस योजना का फॉर्म भर सकता है?",
                    "इस योजना के लिए कौन से दस्तावेज़ चाहिए?",
                    "मुझे ओटीपी खुद क्यों दर्ज करना होगा?",
                    "योजना के मुख्य लाभ क्या हैं?",
                ]
            else:
                questions = [
                    "Can SAHAY help me fill this form?",
                    "What documents are required for this scheme?",
                    "Why do I need to enter OTP manually?",
                    "What are the key benefits of this scheme?",
                ]
        elif screen in ["document_vault", "my_documents"]:
            if is_hi:
                questions = [
                    "दस्तावेज़ वॉल्ट कैसे काम करता है?",
                    "आय प्रमाण पत्र कैसे अपलोड करें?",
                    "क्या मेरे दस्तावेज़ यहाँ सुरक्षित हैं?",
                    "दस्तावेज़ से डेटा कैसे निकाला जाता है?",
                ]
            else:
                questions = [
                    "How does the Document Vault work?",
                    "How do I upload my Income Certificate?",
                    "Are my uploaded documents secure?",
                    "How does OCR extract my information?",
                ]
        elif screen in ["smart_filler_preparation", "smart_filler_portal", "smart_filler_missing_info"]:
            if is_hi:
                questions = [
                    "इस चरण (Stage) में क्या हो रहा है?",
                    "अगर पोर्टल लोड न हो तो क्या करें?",
                    "क्या मेरे बिना पूछे फॉर्म सबमिट हो जाएगा?",
                    "छूटी हुई जानकारी कैसे भरें?",
                ]
            else:
                questions = [
                    "What is happening at this stage?",
                    "What if the official portal does not load?",
                    "Will SAHAY submit without my approval?",
                    "How do I provide missing information?",
                ]
        elif screen in ["eligibility", "questionnaire"]:
            if is_hi:
                questions = [
                    "मेरी पात्रता कैसे जांची जाती है?",
                    "अगर मेरी सही आय नहीं मालूम तो क्या करें?",
                    "क्या पात्रता का डेटा सुरक्षित रहता है?",
                    "पात्र होने के बाद आवेदन कैसे करें?",
                ]
            else:
                questions = [
                    "How is my eligibility assessed?",
                    "What if I don't know my exact annual income?",
                    "Is my questionnaire information kept private?",
                    "How do I apply after checking eligibility?",
                ]
        else:  # home, schemes, default
            if is_hi:
                questions = [
                    "सहाय ऐप कैसे काम करता है?",
                    "सरकारी योजनाएं कैसे खोजें?",
                    "दस्तावेज़ कैसे अपलोड करें?",
                    "'Fill with SAHAY' क्या है?",
                ]
            else:
                questions = [
                    "How does the SAHAY app work?",
                    "How do I find eligible schemes?",
                    "How do I upload documents to the Vault?",
                    "What is 'Fill with SAHAY'?",
                ]

        return ContextPromptsResponse(
            current_screen=screen,
            suggested_questions=questions[:4],
            welcome_message=welcome_message,
        )

    # ==========================================================================
    # Deterministic Rule-Based Knowledge Engine (Fallback & Grounded Truth)
    # ==========================================================================

    def _evaluate_deterministic_knowledge(
        self,
        query: str,
        current_screen: Optional[str] = None,
        selected_scheme_id: Optional[str] = None,
        language: str = "en",
    ) -> Tuple[Optional[str], Optional[NavigationAction], List[str]]:
        """
        Evaluates citizen queries against the verified SAHAY knowledge base.
        Returns (answer_markdown, optional_nav_action, suggested_followup_prompts).
        """
        q = query.lower().strip()
        is_hi = language.startswith("hi") or any(word in q for word in ["नमस्ते", "सहाय", "योजना", "फॉर्म", "आवेदन", "दस्तावेज़"])
        lang_key = "hi" if is_hi else "en"

        nav_action: Optional[NavigationAction] = None
        follow_ups: List[str] = []

        # 1. Scheme-Specific Inquiries
        canonical_scheme_id = None
        if selected_scheme_id:
            canonical_scheme_id = self.portal_service.normalize_scheme_id(selected_scheme_id)

        # Check for scheme name mentions in query if no scheme is explicitly selected
        if not canonical_scheme_id:
            if "kisan" in q:
                canonical_scheme_id = "PM_KISAN_001"
            elif "pmay" in q or "awas" in q or "आवास" in q:
                canonical_scheme_id = "PMAY_002"
            elif "shram" in q or "श्रम" in q:
                canonical_scheme_id = "E_SHRAM_001"
            elif "udyam" in q or "msme" in q or "उद्यम" in q:
                canonical_scheme_id = "UDYAM_001"
            elif "surya" in q or "solar" in q or "सौर" in q or "बिजली" in q:
                canonical_scheme_id = "PM_SURYA_GHAR_001"
            elif "svanidhi" in q or "vendor" in q or "रेहड़ी" in q:
                canonical_scheme_id = "PM_SVANIDHI_001"
            elif "pmegp" in q:
                canonical_scheme_id = "PMEGP_001"
            elif "matric" in q or "scholarship" in q or "छात्रवृत्ति" in q:
                canonical_scheme_id = "MP_POST_MATRIC_SCHOLARSHIP_SC_ST_001"
            elif "pragati" in q:
                canonical_scheme_id = "AICTE_PRAGATI_001"
            elif "saksham" in q:
                canonical_scheme_id = "AICTE_SAKSHAM_001"

        # Inquiry: "What is Fill with SAHAY?" (general, no specific scheme)
        # But NOT "which 10 schemes..." type queries
        is_fill_with_sahay_general = ("fill with sahay" in q or "fill with sahay" in q.replace("'", "") or "फिल विद सहाय" in q) and not canonical_scheme_id
        is_ten_schemes_query = any(term in q for term in ["10 scheme", "which scheme", "all scheme", "supported scheme", "दस योजनाएं", "कौन सी योजनाएं", "समर्थित"])
        if is_fill_with_sahay_general and not is_ten_schemes_query:
            ans = SAHAY_KNOWLEDGE_BASE["fill_with_sahay"][lang_key]
            follow_ups = (
                ["किसी योजना का फॉर्म कैसे भरें?", "10 योजनाएं कौन सी हैं?", "दस्तावेज़ वॉल्ट क्या है?"]
                if is_hi
                else ["How to fill a scheme form?", "Which 10 schemes are supported?", "What is Document Vault?"]
            )
            return ans, None, follow_ups

        # Inquiry: Apply / Fill with SAHAY for a scheme
        if any(term in q for term in ["apply", "fill", "form", "आवेदन", "फॉर्म", "भरना", "मदद"]):
            if canonical_scheme_id:
                entry = self.portal_service.get_entry_for_scheme(canonical_scheme_id)
                scheme_name = entry.schemeName if entry else canonical_scheme_id
                facts = SCHEME_QUICK_FACTS.get(canonical_scheme_id, {}).get(lang_key, "")

                nav_action = NavigationAction(
                    action="start_fill_with_sahay",
                    title="सहाय के साथ फॉर्म भरें" if is_hi else "Start Fill with SAHAY",
                    scheme_id=canonical_scheme_id,
                    scheme_name=scheme_name,
                )

                if is_hi:
                    ans = (
                        f"हाँ! आप **{scheme_name}** के लिए **Fill with SAHAY** का उपयोग कर सकते हैं।\n\n"
                        f"{facts}\n\n"
                        f"**सहाय आपकी कैसे मदद करेगा:**\n"
                        f"1. आपके वॉल्ट से आवश्यक दस्तावेज़ पहचानेगा।\n"
                        f"2. आधिकारिक पोर्टल पर समर्थित फ़ील्ड्स को सुरक्षित भरेगा।\n"
                        f"3. ओटीपी और कैप्चा आपको स्वयं पोर्टल पर डालना होगा।\n"
                        f"4. आपकी अंतिम समीक्षा और मंज़ूरी के बाद ही आवेदन आगे बढ़ेगा।\n\n"
                        f"आवेदन शुरू करने के लिए नीचे दिए गए बटन पर टैप करें।"
                    )
                    follow_ups = ["ओटीपी मुझे क्यों डालना होगा?", "कौन से दस्तावेज़ लगेंगे?", "क्या यह निःशुल्क है?"]
                else:
                    ans = (
                        f"Yes! SAHAY provides intelligent application-filling assistance for **{scheme_name}**.\n\n"
                        f"{facts}\n\n"
                        f"**How Fill with SAHAY works:**\n"
                        f"1. Automatically maps your profile and Document Vault records.\n"
                        f"2. Opens the official portal in a secure browser and populates verified fields.\n"
                        f"3. You personally complete the manual OTP and CAPTCHA steps.\n"
                        f"4. Runs read-back verification so you can inspect every field before approving.\n\n"
                        f"Tap the button below to start application preparation now."
                    )
                    follow_ups = ["Why do I need to enter OTP?", "Which documents are required?", "Is my data secure?"]

                return ans, nav_action, follow_ups

        # Inquiry: Scheme details / benefits / facts
        if canonical_scheme_id and (any(term in q for term in ["benefit", "about", "what is", "document", "लाभ", "क्या है", "दस्तावेज़"]) or len(q.split()) <= 4):
            facts = SCHEME_QUICK_FACTS.get(canonical_scheme_id, {}).get(lang_key, "")
            entry = self.portal_service.get_entry_for_scheme(canonical_scheme_id)
            scheme_name = entry.schemeName if entry else canonical_scheme_id

            nav_action = NavigationAction(
                action="start_fill_with_sahay",
                title="Fill with SAHAY" if not is_hi else "फॉर्म भरना शुरू करें",
                scheme_id=canonical_scheme_id,
                scheme_name=scheme_name,
            )

            if is_hi:
                ans = (
                    f"**{scheme_name} की जानकारी:**\n\n"
                    f"{facts}\n\n"
                    f"**आधिकारिक पोर्टल:** `{entry.portalDomain if entry else 'gov.in'}`\n"
                    f"**मोड:** स्मार्ट एप्लिकेशन फिलर (सहायता उपलब्ध)\n\n"
                    f"आप 'Fill with SAHAY' द्वारा इस योजना के लिए सहायता प्राप्त कर सकते हैं।"
                )
                follow_ups = ["फॉर्म कैसे भरें?", "पात्रता कैसे जांचें?", "दस्तावेज़ कैसे अपलोड करें?"]
            else:
                ans = (
                    f"**Scheme Details for {scheme_name}:**\n\n"
                    f"{facts}\n\n"
                    f"• **Official Portal:** `{entry.portalDomain if entry else 'gov.in'}`\n"
                    f"• **Application Mode:** Supported via Fill with SAHAY\n"
                    f"• **Manual Steps:** Citizen enters OTP and visual CAPTCHA.\n\n"
                    f"Would you like to start preparing your application for this scheme?"
                )
                follow_ups = ["How to start application?", "Check my eligibility", "What documents are needed?"]

            return ans, nav_action, follow_ups

        # 2. Topic: Document Vault
        if any(term in q for term in ["vault", "document", "upload", "income certificate", "aadhaar", "दस्तावेज़", "वॉल्ट", "अपलोड", "प्रमाण पत्र"]):
            nav_action = NavigationAction(action="open_document_vault", title="दस्तावेज़ वॉल्ट खोलें" if is_hi else "Open Document Vault")
            ans = SAHAY_KNOWLEDGE_BASE["document_vault"][lang_key]
            follow_ups = (
                ["क्या दस्तावेज़ सुरक्षित हैं?", "आय प्रमाण पत्र कैसे जोड़ें?", "फॉर्म में यह कैसे काम आता है?"]
                if is_hi
                else ["Are my documents secure?", "How to add Income Certificate?", "How are documents used in forms?"]
            )
            return ans, nav_action, follow_ups

        # 3. Topic: Eligibility Assessment
        if any(term in q for term in ["eligib", "qualify", "पात्र", "योग्यता", "जांच"]):
            nav_action = NavigationAction(action="open_eligibility", title="पात्रता जांचें" if is_hi else "Check Eligibility")
            ans = SAHAY_KNOWLEDGE_BASE["eligibility_engine"][lang_key]
            follow_ups = (
                ["पात्रता के नियम क्या हैं?", "अगर आय मालूम न हो?", "पात्र होने के बाद क्या करें?"]
                if is_hi
                else ["What are the eligibility rules?", "What if I don't know my income?", "What next after checking?"]
            )
            return ans, nav_action, follow_ups

        # 4. Topic: Security, OTP, and Privacy
        if any(term in q for term in ["otp", "captcha", "security", "privacy", "सुरक्षा", "ओटीपी", "गोपनीयता", "कैप्चा"]):
            ans = SAHAY_KNOWLEDGE_BASE["security_and_privacy"][lang_key]
            follow_ups = (
                ["ओटीपी मुझे क्यों डालना पड़ता है?", "क्या सहाय खुद सबमिट करता है?", "दस्तावेज़ कितने सुरक्षित हैं?"]
                if is_hi
                else ["Why do I have to enter OTP?", "Does SAHAY auto-submit?", "How secure are my documents?"]
            )
            return ans, None, follow_ups

        # 5. Topic: 10 Supported Schemes
        if any(term in q for term in ["10 scheme", "which scheme", "all scheme", "supported scheme", "दस योजनाएं", "कौन सी योजनाएं", "समर्थित"]):
            nav_action = NavigationAction(action="open_schemes", title="सभी योजनाएं देखें" if is_hi else "Explore All Schemes")
            ans = SAHAY_KNOWLEDGE_BASE["ten_supported_schemes"][lang_key]
            follow_ups = (
                ["पीएम किसान के बारे में बताएं", "सूर्य घर योजना क्या है?", "फॉर्म कैसे भरें?"]
                if is_hi
                else ["Tell me about PM Kisan", "What is PM Surya Ghar?", "How do I apply?"]
            )
            return ans, nav_action, follow_ups

        # 6. Topic: General "How SAHAY works"
        if any(term in q for term in ["how", "what is sahay", "work", "app", "help", "सहाय क्या है", "कैसे काम करता है", "मदद"]):
            nav_action = NavigationAction(action="open_schemes", title="योजनाएं खोजें" if is_hi else "Browse Schemes")
            ans = SAHAY_KNOWLEDGE_BASE["about_sahay"][lang_key]
            follow_ups = (
                ["'Fill with SAHAY' क्या है?", "पात्रता कैसे जांचें?", "दस्तावेज़ कैसे अपलोड करें?"]
                if is_hi
                else ["What is 'Fill with SAHAY'?", "How to check eligibility?", "How to upload documents?"]
            )
            return ans, nav_action, follow_ups

        return None, None, []

    # ==========================================================================
    # Main Message Handler (Hybrid: Grounded Knowledge + Qwen2.5 + Fallback)
    # ==========================================================================

    async def process_chat_message(self, request: ChatbotMessageRequest) -> ChatbotMessageResponse:
        """
        Processes citizen inquiries using grounded SAHAY knowledge, screen context,
        and optionally Qwen2.5 / Ollama with guaranteed deterministic fallback.
        """
        conv_id = request.conversation_id or f"chat_{uuid.uuid4().hex[:10]}"
        lang = request.app_language or "en"
        is_hi = lang.startswith("hi")

        # 1. First, check deterministic knowledge engine for high-confidence match
        det_answer, nav_action, follow_ups = self._evaluate_deterministic_knowledge(
            query=request.message,
            current_screen=request.current_screen,
            selected_scheme_id=request.selected_scheme_id,
            language=lang,
        )

        if det_answer:
            return ChatbotMessageResponse(
                conversation_id=conv_id,
                assistant_message=det_answer,
                suggested_questions=follow_ups[:4],
                navigation_action=nav_action,
                response_language="hi" if is_hi else "en",
                response_status="success",
            )

        # 2. If not immediately matched, attempt Qwen2.5 / Ollama with grounded system prompt
        try:
            ai_response = await self._generate_ai_response(request)
            if ai_response:
                return ChatbotMessageResponse(
                    conversation_id=conv_id,
                    assistant_message=ai_response,
                    suggested_questions=(
                        ["'Fill with SAHAY' कैसे काम करता है?", "मेरी पात्रता कैसे जांचें?", "दस्तावेज़ कैसे अपलोड करें?"]
                        if is_hi
                        else ["How does Fill with SAHAY work?", "How to check eligibility?", "How to upload documents?"]
                    ),
                    navigation_action=None,
                    response_language="hi" if is_hi else "en",
                    response_status="success",
                )
        except Exception as e:
            logger.info(f"Ollama generation offline or failed: {e}. Falling back to default assistant response.")

        # 3. Graceful General Fallback
        fallback_msg = (
            "नमस्ते! मैं सहाय सहायक हूँ। मैं ऐप की सुविधाओं, सरकारी योजनाओं, पात्रता और 'Fill with SAHAY' के 7 चरणों के बारे में आपकी मदद कर सकता हूँ।\n\n"
            "आप मुझसे किसी विशिष्ट योजना (जैसे पीएम किसान, सूर्य घर, आवास योजना) या दस्तावेज़ वॉल्ट के बारे में पूछ सकते हैं।"
            if is_hi
            else "Namaste! I am SAHAY Assistance. I can help you with application features, scheme eligibility, document requirements, and our 7-stage 'Fill with SAHAY' assistant.\n\n"
            "Feel free to ask about any specific scheme (such as PM-KISAN, PM Surya Ghar, PMAY-U) or how to upload your documents."
        )

        default_follow_ups = (
            ["'Fill with SAHAY' क्या है?", "सरकारी योजनाएं कैसे खोजें?", "दस्तावेज़ वॉल्ट क्या है?"]
            if is_hi
            else ["What is 'Fill with SAHAY'?", "How do I find schemes?", "What is Document Vault?"]
        )

        return ChatbotMessageResponse(
            conversation_id=conv_id,
            assistant_message=fallback_msg,
            suggested_questions=default_follow_ups,
            navigation_action=NavigationAction(action="open_schemes", title="योजनाएं खोजें" if is_hi else "Browse Schemes"),
            response_language="hi" if is_hi else "en",
            response_status="fallback",
        )

    async def _generate_ai_response(self, request: ChatbotMessageRequest) -> Optional[str]:
        """Calls local Ollama Qwen2.5 instance with strictly grounded prompt."""
        system_instruction = (
            "You are SAHAY Assistance (सहाय सहायक), an AI assistant built into the SAHAY Indian Government Welfare platform. "
            "Your role is to help citizens understand and use the SAHAY app, explain government schemes, clarify document requirements, "
            "and guide them through the 7-stage 'Fill with SAHAY' application assistant. "
            "Rules:\n"
            "1. Answer concisely, respectfully, and accurately in the citizen's language (Hindi, English, or Hinglish).\n"
            "2. Never invent application status, reference numbers, or false eligibility.\n"
            "3. Emphasize that OTP, CAPTCHA, and legal declarations are always performed personally by the citizen.\n"
            "4. Format your output in clear markdown bullet points."
        )

        context_info = f"Current Screen: {request.current_screen or 'Home'}\n"
        if request.selected_scheme_id:
            context_info += f"Viewing Scheme: {request.selected_scheme_id} ({request.selected_scheme_name or ''})\n"

        prompt = f"{system_instruction}\n\nContext:\n{context_info}\nCitizen Question: {request.message}\nAssistant Answer:"

        async with httpx.AsyncClient(timeout=8.0) as client:
            res = await client.post(
                f"{self.ollama_base_url}/api/generate",
                json={
                    "model": self.ollama_model,
                    "prompt": prompt,
                    "stream": False,
                    "options": {"temperature": 0.2, "num_predict": 300},
                },
            )
            if res.status_code == 200:
                data = res.json()
                raw_answer = data.get("response", "").strip()
                if raw_answer:
                    return raw_answer
        return None

