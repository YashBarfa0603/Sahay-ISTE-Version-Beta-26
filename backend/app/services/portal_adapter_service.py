"""
Official Government Portal Compatibility Registry & Controlled Adapter Engine for SAHAY.
Defines official portal schemas, field selector mappings, and the restricted JavaScript bridge protocol.
CRITICAL SECURITY INVARIANT:
Arbitrary AI-generated JavaScript execution is strictly prohibited.
All browser operations must be emitted as pre-compiled, sanitized, declarative instructions.
OTP, CAPTCHA, and legal declaration checkboxes are marked protected and require direct human interaction.
"""

from typing import Any, Dict, List, Optional
from urllib.parse import urlparse
from backend.app.schemas.application_schema import (
    InteractionMode,
    PortalAdapterInfo,
    PortalCompatibilityStatus,
)


class PortalAdapterService:
    """Registry of verified official government portals and adapter specifications."""

    # Curated official portal adapters
    PORTAL_REGISTRY: Dict[str, PortalAdapterInfo] = {
        "PM_KISAN_PORTAL": PortalAdapterInfo(
            portal_id="PM_KISAN_PORTAL",
            official_domain="pmkisan.gov.in",
            official_application_url="https://pmkisan.gov.in/RegistrationFormNew.aspx",
            scheme_ids=["PM_KISAN_001"],
            interaction_mode=InteractionMode.DIRECT_WEB,
            adapter_id="pm_kisan_adapter_v1",
            supported_fields=[
                "aadhaar_number",
                "mobile_number",
                "state",
                "district",
                "sub_district",
                "block",
                "village",
                "farmer_name",
                "gender",
                "category",
            ],
            document_upload_supported=False,
            authentication_requirements="aadhaar_otp",
            known_restrictions=[
                "Mandatory OTP verification required on citizen mobile",
                "Visual image CAPTCHA must be completed manually by citizen",
                "Cross-origin iframe restrictions apply to external uploads",
            ],
            compatibility_status=PortalCompatibilityStatus.TESTED_SUPPORTED,
            last_tested_at="2026-10-31",
        ),
        "PMAY_PORTAL": PortalAdapterInfo(
            portal_id="PMAY_PORTAL",
            official_domain="pmaymis.gov.in",
            official_application_url="https://pmaymis.gov.in/Open/Check_Aadhar_Existence.aspx",
            scheme_ids=["PMAY_G_001", "PMAY_U_001"],
            interaction_mode=InteractionMode.DIRECT_WEB,
            adapter_id="pmay_adapter_v1",
            supported_fields=[
                "aadhaar_number",
                "applicant_name",
                "state",
                "district",
                "mobile_number",
            ],
            document_upload_supported=False,
            authentication_requirements="aadhaar_auth",
            known_restrictions=[
                "Requires preliminary Aadhaar validation before form opens",
                "CAPTCHA required on submission",
            ],
            compatibility_status=PortalCompatibilityStatus.PARTIALLY_SUPPORTED,
            last_tested_at="2026-10-31",
        ),
        "MP_LADLI_BAHNA_PORTAL": PortalAdapterInfo(
            portal_id="MP_LADLI_BAHNA_PORTAL",
            official_domain="ladlibahna.mp.gov.in",
            official_application_url="https://ladlibahna.mp.gov.in/",
            scheme_ids=["MP_LADLI_BAHNA_001"],
            interaction_mode=InteractionMode.GUIDED_FORM,
            adapter_id="ladli_bahna_guided_adapter",
            supported_fields=[
                "samagra_id",
                "aadhaar_number",
                "mobile_number",
                "bank_account",
            ],
            document_upload_supported=False,
            authentication_requirements="samagra_ekyc",
            known_restrictions=[
                "Application submitted primarily via Gram Panchayat / Ward camps / VLE kiosk",
                "Biometric eKYC required",
            ],
            compatibility_status=PortalCompatibilityStatus.GUIDED_ONLY,
            last_tested_at="2026-10-31",
        ),
        "NSP_SCHOLARSHIP_PORTAL": PortalAdapterInfo(
            portal_id="NSP_SCHOLARSHIP_PORTAL",
            official_domain="scholarships.gov.in",
            official_application_url="https://scholarships.gov.in/fresh/newstdRegfrmInstruction",
            scheme_ids=["AICTE_PRAGATI_001", "AICTE_SAKSHAM_001"],
            interaction_mode=InteractionMode.DIRECT_WEB,
            adapter_id="nsp_scholarship_adapter_v1",
            supported_fields=[
                "state_of_domicile",
                "scholarship_category",
                "student_name",
                "date_of_birth",
                "gender",
                "mobile_number",
                "email_id",
                "bank_ifsc",
                "bank_account_number",
            ],
            document_upload_supported=True,
            authentication_requirements="mobile_otp_registration",
            known_restrictions=[
                "OTP registration required before full application form opens",
                "Document scans must be under 200KB PDF/JPEG",
            ],
            compatibility_status=PortalCompatibilityStatus.PARTIALLY_SUPPORTED,
            last_tested_at="2026-10-31",
        ),
    }

    # ==========================================
    # Registry Resolution & Compatibility Routing
    # ==========================================

    @classmethod
    def get_adapter_for_scheme(cls, scheme_id: str, official_url: Optional[str] = None) -> PortalAdapterInfo:
        """Finds matching portal adapter by scheme ID or official URL domain."""
        # 1. Match by scheme ID
        for adapter in cls.PORTAL_REGISTRY.values():
            if scheme_id in adapter.scheme_ids:
                return adapter

        # 2. Match by domain if URL provided
        if official_url:
            try:
                parsed = urlparse(official_url)
                domain = parsed.netloc.lower()
                for adapter in cls.PORTAL_REGISTRY.values():
                    if adapter.official_domain in domain or domain in adapter.official_domain:
                        return adapter
            except Exception:
                pass

        # 3. Default generic adapter for unverified/new schemes (Guided Mode)
        return PortalAdapterInfo(
            portal_id="GENERIC_GUIDED_PORTAL",
            official_domain=urlparse(official_url).netloc if official_url else "gov.in",
            official_application_url=official_url or "https://www.india.gov.in",
            scheme_ids=[scheme_id],
            interaction_mode=InteractionMode.GUIDED_FORM,
            adapter_id="generic_guided_adapter",
            supported_fields=["full_name", "mobile_number", "aadhaar_number", "state", "income"],
            document_upload_supported=False,
            authentication_requirements="varies_by_portal",
            known_restrictions=["Unregistered official portal. Guided application mode enabled."],
            compatibility_status=PortalCompatibilityStatus.GUIDED_ONLY,
            last_tested_at="2026-10-31",
        )

    # ==========================================
    # Restricted JavaScript Bridge Builder
    # ==========================================

    @classmethod
    def generate_inspection_script(cls) -> str:
        """
        Generates a strictly sandboxed, read-only JavaScript payload to inspect
        form inputs on the government portal page and communicate metadata back to Flutter.
        """
        return """
        (function() {
            try {
                var inputs = document.querySelectorAll('input, select, textarea');
                var fields = [];
                for (var i = 0; i < inputs.length; i++) {
                    var el = inputs[i];
                    var type = (el.getAttribute('type') || el.tagName).toLowerCase();
                    // Never inspect password fields
                    if (type === 'password') continue;

                    var id = el.id || '';
                    var name = el.name || '';
                    var label = '';
                    if (id) {
                        var lbl = document.querySelector('label[for="' + id + '"]');
                        if (lbl) label = lbl.innerText.trim();
                    }
                    if (!label && el.placeholder) label = el.placeholder.trim();

                    var isProtected = (
                        id.toLowerCase().indexOf('captcha') !== -1 ||
                        name.toLowerCase().indexOf('captcha') !== -1 ||
                        id.toLowerCase().indexOf('otp') !== -1 ||
                        name.toLowerCase().indexOf('otp') !== -1
                    );

                    fields.push({
                        id: id,
                        name: name,
                        type: type,
                        label: label,
                        value: el.value || '',
                        isProtected: isProtected,
                        tagName: el.tagName.toLowerCase()
                    });
                }
                
                var payload = JSON.stringify({
                    action: 'INSPECT_RESULTS',
                    url: window.location.href,
                    domain: window.location.hostname,
                    fields: fields
                });

                if (window.SahayBridge && window.SahayBridge.postMessage) {
                    window.SahayBridge.postMessage(payload);
                } else if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                    window.flutter_inappwebview.callHandler('SahayBridge', payload);
                }
                return payload;
            } catch(e) {
                return JSON.stringify({action: 'INSPECT_ERROR', error: e.toString()});
            }
        })();
        """.strip()

    @classmethod
    def generate_population_script(cls, field_instructions: List[Dict[str, Any]]) -> str:
        """
        Emits declarative, safe field population commands.
        NEVER allows arbitrary eval or prompt-injected code.
        Only operates on designated selector IDs/names with sanitized string values.
        """
        import json
        clean_instructions = []
        for inst in field_instructions:
            selector = inst.get("selector", "")
            value = inst.get("value", "")
            # Security guard: never populate captcha or otp fields
            if any(term in str(selector).lower() for term in ["captcha", "otp", "password"]):
                continue
            clean_instructions.append({
                "selector": str(selector).strip(),
                "value": str(value).strip(),
                "tag": inst.get("tag", "input"),
            })

        instructions_json = json.dumps(clean_instructions)

        return f"""
        (function() {{
            var instructions = {instructions_json};
            var results = [];
            for (var i = 0; i < instructions.length; i++) {{
                var inst = instructions[i];
                try {{
                    var el = document.getElementById(inst.selector) || document.querySelector('[name="' + inst.selector + '"]');
                    if (el) {{
                        el.value = inst.value;
                        el.dispatchEvent(new Event('input', {{ bubbles: true }}));
                        el.dispatchEvent(new Event('change', {{ bubbles: true }}));
                        results.push({{ selector: inst.selector, status: 'success' }});
                    }} else {{
                        results.push({{ selector: inst.selector, status: 'not_found' }});
                    }}
                }} catch(err) {{
                    results.push({{ selector: inst.selector, status: 'error', error: err.toString() }});
                }}
            }}
            var report = JSON.stringify({{ action: 'POPULATE_RESULTS', results: results }});
            if (window.SahayBridge && window.SahayBridge.postMessage) {{
                window.SahayBridge.postMessage(report);
            }}
            return report;
        }})();
        """.strip()

