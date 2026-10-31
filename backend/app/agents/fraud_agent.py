"""
Agent 4: Fraud and Authenticity Agent.
Flags suspicious links, unverified third-party fee claims, and source anomalies.
INVARIANT: Never automatically accuses a citizen of fraud.
"""

from typing import Any, Dict, List
from backend.app.agents.state import AgentState
from backend.app.config import settings

SUSPICIOUS_KEYWORDS = [
    "free money",
    "instant cash",
    "lottery",
    "pay registration fee",
    "deposit advance",
    "guaranteed loan",
    "whatsapp to apply",
    "telegram channel",
]


async def run_fraud_agent(state: AgentState) -> Dict[str, Any]:
    """Inspects external links and scheme descriptions for phishing, unverified fees, or fraud signals."""
    schemes = state.get("matched_schemes", [])
    warnings: List[str] = []
    is_safe = True

    for s in schemes:
        url = s.get("officialSourceUrl", "").lower()
        app_url = (s.get("applicationUrl") or "").lower()
        desc = (s.get("description") or "").lower()
        name = s.get("name", "Unknown Scheme")

        # 1. URL domain safety check
        if url and not any(gov in url for gov in settings.TRUSTED_GOV_DOMAINS):
            warnings.append(
                f"Source for '{name}' points to an unverified non-governmental domain ({url}). Exercise caution."
            )
            is_safe = False

        if app_url and not any(gov in app_url for gov in settings.TRUSTED_GOV_DOMAINS):
            warnings.append(
                f"Application portal for '{name}' ({app_url}) is not an official .gov.in or .nic.in domain."
            )
            is_safe = False

        # 2. Suspicious keywords check
        for kw in SUSPICIOUS_KEYWORDS:
            if kw in desc:
                warnings.append(
                    f"Notice for '{name}': Mentions suspicious phrasing ('{kw}'). Legitimate government schemes do not require private processing fees."
                )
                is_safe = False

    history = list(state.get("step_history", []))
    history.append("FraudAndAuthenticityAgent")

    return {
        "fraud_warnings": warnings,
        "is_safe": is_safe,
        "step_history": history,
        "iteration_count": state.get("iteration_count", 0) + 1,
    }
