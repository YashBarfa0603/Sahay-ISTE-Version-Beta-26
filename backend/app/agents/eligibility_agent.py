"""
Agent 2: Eligibility Assistance Agent.
Enforces deterministic rule evaluation via EligibilityEvaluationService.
NEVER uses an LLM to decide eligibility. Explains results in simple citizen language.
"""

import logging
from typing import Any, Dict, List
from backend.app.agents.state import AgentState
from backend.app.models.scheme_schemas import SchemeModelSchema
from backend.app.services.eligibility_service import EligibilityEvaluationService, EvaluationVerdict

logger = logging.getLogger(__name__)


async def run_eligibility_agent(state: AgentState) -> Dict[str, Any]:
    """Runs deterministic eligibility assessment against verified rules and explains the decision."""
    schemes_raw = state.get("matched_schemes", [])
    user_answers = state.get("user_answers", {})

    service = EligibilityEvaluationService()
    reports_dicts: List[Dict[str, Any]] = []
    qualifying_ids: List[str] = []

    for s_dict in schemes_raw:
        try:
            scheme = SchemeModelSchema.model_validate(s_dict)
            report = service.evaluate_scheme(scheme, user_answers)
            r_dump = report.model_dump()
            reports_dicts.append(r_dump)

            if report.verdict == EvaluationVerdict.mayQualify:
                qualifying_ids.append(scheme.schemeId)
        except Exception as e:
            logger.error(f"Error evaluating scheme {s_dict.get('schemeId')}: {e}")

    history = list(state.get("step_history", []))
    history.append("EligibilityAssistanceAgent")

    return {
        "eligibility_reports": reports_dicts,
        "qualifying_scheme_ids": qualifying_ids,
        "step_history": history,
        "iteration_count": state.get("iteration_count", 0) + 1,
    }

