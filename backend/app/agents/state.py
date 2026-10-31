"""
Typed Shared State for the SAHAY LangGraph Multi-Agent System.
"""

from typing import Any, Dict, List, Optional
from typing_extensions import TypedDict


class AgentState(TypedDict):
    """Shared state passed between LangGraph specialist agents."""

    # Citizen input
    citizen_query: str
    language: str  # en, hi, mr, etc.
    user_answers: Dict[str, Any]

    # Discovery outputs
    matched_schemes: List[Dict[str, Any]]
    is_dynamic_discovery: bool
    sources_checked: List[str]

    # Verification and trust findings
    trust_findings: List[Dict[str, Any]]
    is_trusted: bool

    # Deterministic eligibility evaluation
    eligibility_reports: List[Dict[str, Any]]
    qualifying_scheme_ids: List[str]

    # Document assistance
    document_guidance: Dict[str, Any]

    # Fraud and authenticity
    fraud_warnings: List[str]
    is_safe: bool

    # Income assistance
    requires_income_estimation: bool
    income_estimate: Optional[Dict[str, Any]]

    # System & routing
    step_history: List[str]
    iteration_count: int
    errors: List[str]
    final_response: Optional[Dict[str, Any]]

