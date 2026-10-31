"""
Agent 6: Income Assistance Agent.
Assists citizens with unknown household income by estimating conservative ranges
and mapping them against verified scheme eligibility thresholds.
"""

from typing import Any, Dict
from backend.app.agents.state import AgentState
from backend.app.services.income_estimator_service import IncomeEstimationInput, IncomeEstimatorService


async def run_income_agent(state: AgentState) -> Dict[str, Any]:
    """Computes conservative income range when user specifies uncertain or unknown income."""
    answers = state.get("user_answers", {})
    schemes = state.get("matched_schemes", [])

    # Collect income thresholds from matched schemes
    thresholds: Dict[str, float] = {}
    for s in schemes:
        s_id = s.get("schemeId")
        for rule in s.get("eligibilityRules", []):
            field = rule.get("field")
            if field in ["annualIncome", "annualFamilyIncome"] and rule.get("value") is not None:
                try:
                    thresholds[s_id] = float(rule["value"])
                except (ValueError, TypeError):
                    pass

    # Extract user estimates if provided in questionnaire answers
    occ = answers.get("occupation", "unorganized_worker")
    monthly = answers.get("monthlyEstimatedIncome")
    if monthly is not None:
        try:
            monthly = float(monthly)
        except (ValueError, TypeError):
            monthly = None

    input_data = IncomeEstimationInput(
        primary_source=occ,
        monthly_estimated_income=monthly,
        household_earners=int(answers.get("householdEarners", 1)),
        has_agricultural_income=bool(answers.get("hasAgriculturalIncome", False)),
        seasonal_agricultural_income=float(answers.get("seasonalHarvestIncome", 0.0))
        if answers.get("seasonalHarvestIncome")
        else None,
    )

    estimator = IncomeEstimatorService()
    result = estimator.estimate_income(input_data, thresholds)

    history = list(state.get("step_history", []))
    history.append("IncomeAssistanceAgent")

    return {
        "income_estimate": result.model_dump(),
        "requires_income_estimation": False,  # resolved
        "step_history": history,
        "iteration_count": state.get("iteration_count", 0) + 1,
    }
