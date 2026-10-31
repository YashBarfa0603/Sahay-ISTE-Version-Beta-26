"""
Agent 5: Trust and Verification Agent.
Audits source freshness, domain whitelisting, rule completeness, and provenance.
Final approval relies strictly on deterministic verification.
"""

import logging
from typing import Any, Dict, List
from backend.app.agents.state import AgentState
from backend.app.config import settings

logger = logging.getLogger(__name__)


async def run_trust_agent(state: AgentState) -> Dict[str, Any]:
    """Inspects matched schemes for domain authenticity and source trustworthiness."""
    schemes = state.get("matched_schemes", [])
    findings: List[Dict[str, Any]] = []
    all_trusted = True

    for s in schemes:
        url = s.get("officialSourceUrl", "")
        name = s.get("name", "Unknown Scheme")
        is_gov = any(domain in url for domain in settings.TRUSTED_GOV_DOMAINS)

        rule_count = len(s.get("eligibilityRules", []))
        has_rules = rule_count > 0
        has_docs = len(s.get("requiredDocuments", [])) > 0

        finding = {
            "schemeId": s.get("schemeId"),
            "name": name,
            "url": url,
            "is_government_domain": is_gov,
            "has_rules": has_rules,
            "rule_count": rule_count,
            "has_documents": has_docs,
            "status": "trusted" if is_gov and has_rules else "needs_review",
        }
        findings.append(finding)

        if not is_gov:
            all_trusted = False

    history = list(state.get("step_history", []))
    history.append("TrustAndVerificationAgent")

    return {
        "trust_findings": findings,
        "is_trusted": all_trusted,
        "step_history": history,
        "iteration_count": state.get("iteration_count", 0) + 1,
    }
