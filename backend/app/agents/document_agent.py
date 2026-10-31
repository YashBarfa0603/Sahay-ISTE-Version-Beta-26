"""
Agent 3: Document Assistance Agent.
Extracts verified document checklists, issuance guidelines, and preparatory advice.
"""

from typing import Any, Dict, List
from backend.app.agents.state import AgentState

# Known official document issuing authorities in India
ISSUING_AUTHORITIES = {
    "aadhaar": "UIDAI / Aadhaar Seva Kendra",
    "ration": "State Food & Civil Supplies Department",
    "land": "Tehsil / Revenue Department (Patwari/Khatauni)",
    "income": "Tehsildar / Sub-Divisional Magistrate (SDM) / Revenue Officer",
    "caste": "Tehsildar / District Welfare Office",
    "bank": "Any Scheduled Commercial / Gramin Bank (Aadhaar Seeded)",
    "disability": "District Chief Medical Officer (CMO) / UDID Portal",
}


def _get_authority(doc_name: str) -> str:
    name_lower = doc_name.lower()
    for key, auth in ISSUING_AUTHORITIES.items():
        if key in name_lower:
            return auth
    return "Relevant Competent State/Central Government Authority"


async def run_document_agent(state: AgentState) -> Dict[str, Any]:
    """Generates comprehensive document checklists and preparation guidelines."""
    schemes = state.get("matched_schemes", [])
    qualifying_ids = set(state.get("qualifying_scheme_ids", []))

    guidance_by_scheme: Dict[str, Any] = {}
    master_checklist: List[Dict[str, str]] = []
    seen_docs = set()

    for s in schemes:
        s_id = s.get("schemeId")
        name = s.get("name")
        req_docs = s.get("requiredDocuments", [])

        scheme_docs = []
        for doc in req_docs:
            authority = _get_authority(doc)
            doc_entry = {
                "documentName": doc,
                "issuingAuthority": authority,
                "instruction": f"Ensure your {doc} is valid, updated with current address, and linked with your active mobile number.",
                "isEssential": True,
            }
            scheme_docs.append(doc_entry)

            if doc not in seen_docs and s_id in qualifying_ids:
                seen_docs.add(doc)
                master_checklist.append(doc_entry)

        guidance_by_scheme[s_id] = {
            "schemeName": name,
            "documents": scheme_docs,
            "applicationUrl": s.get("applicationUrl") or s.get("officialSourceUrl"),
        }

    history = list(state.get("step_history", []))
    history.append("DocumentAssistanceAgent")

    return {
        "document_guidance": {
            "by_scheme": guidance_by_scheme,
            "master_checklist": master_checklist,
        },
        "step_history": history,
        "iteration_count": state.get("iteration_count", 0) + 1,
    }
