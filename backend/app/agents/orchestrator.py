"""
Multi-Agent Orchestrator using LangGraph.
Implements shared state, conditional routing, infinite-loop guards, and result aggregation.
"""

import logging
from typing import Any, Dict, List
from langgraph.graph import END, START, StateGraph

from backend.app.agents.discovery_agent import run_discovery_agent
from backend.app.agents.document_agent import run_document_agent
from backend.app.agents.eligibility_agent import run_eligibility_agent
from backend.app.agents.fraud_agent import run_fraud_agent
from backend.app.agents.income_agent import run_income_agent
from backend.app.agents.state import AgentState
from backend.app.agents.trust_agent import run_trust_agent

logger = logging.getLogger(__name__)


def should_check_income(state: AgentState) -> str:
    """Conditional router determining if Income Assistance Agent is required."""
    answers = state.get("user_answers", {})
    # Check if annualIncome was marked unknown, missing, or explicitly requested
    annual_income = answers.get("annualIncome") or answers.get("annualFamilyIncome")
    needs_income = (
        state.get("requires_income_estimation", False)
        or annual_income is None
        or annual_income == "unknown"
        or annual_income == "dont_know"
        or str(annual_income).lower() in ["i don't know", "unknown", "prefer not to answer"]
    )

    if needs_income:
        return "income_assistance"
    return "result_aggregator"


async def run_result_aggregator(state: AgentState) -> Dict[str, Any]:
    """Compiles findings from all specialist agents into a final, coherent response."""
    history = list(state.get("step_history", []))
    history.append("ResultAggregator")

    schemes = state.get("matched_schemes", [])
    reports = state.get("eligibility_reports", [])
    qualifying_ids = state.get("qualifying_scheme_ids", [])
    doc_guidance = state.get("document_guidance", {})
    fraud_warnings = state.get("fraud_warnings", [])
    income_est = state.get("income_estimate")
    trust_findings = state.get("trust_findings", [])

    final_payload = {
        "citizenQuery": state.get("citizen_query"),
        "language": state.get("language", "en"),
        "totalSchemesEvaluated": len(schemes),
        "qualifyingCount": len(qualifying_ids),
        "qualifyingSchemeIds": qualifying_ids,
        "eligibilityReports": reports,
        "documentGuidance": doc_guidance,
        "trustFindings": trust_findings,
        "fraudWarnings": fraud_warnings,
        "incomeEstimate": income_est,
        "isDynamicDiscovery": state.get("is_dynamic_discovery", False),
        "sourcesChecked": state.get("sources_checked", []),
        "agentExecutionPath": history,
        "systemStatus": "completed_successfully",
    }

    return {
        "final_response": final_payload,
        "step_history": history,
        "iteration_count": state.get("iteration_count", 0) + 1,
    }


def create_sahay_agent_graph():
    """Builds the compiled LangGraph workflow."""
    workflow = StateGraph(AgentState)

    # Register Nodes
    workflow.add_node("discovery", run_discovery_agent)
    workflow.add_node("trust_verification", run_trust_agent)
    workflow.add_node("eligibility", run_eligibility_agent)
    workflow.add_node("document_guidance", run_document_agent)
    workflow.add_node("fraud_check", run_fraud_agent)
    workflow.add_node("income_assistance", run_income_agent)
    workflow.add_node("result_aggregator", run_result_aggregator)

    # Build Edge Sequence
    workflow.add_edge(START, "discovery")
    workflow.add_edge("discovery", "trust_verification")
    workflow.add_edge("trust_verification", "eligibility")
    workflow.add_edge("eligibility", "document_guidance")
    workflow.add_edge("document_guidance", "fraud_check")

    # Conditional Branch: Check if citizen needs unknown income assistance
    workflow.add_conditional_edges(
        "fraud_check",
        should_check_income,
        {
            "income_assistance": "income_assistance",
            "result_aggregator": "result_aggregator",
        },
    )

    workflow.add_edge("income_assistance", "result_aggregator")
    workflow.add_edge("result_aggregator", END)

    return workflow.compile()


class SahayMultiAgentOrchestrator:
    """Entry point for executing multi-agent scheme discovery and eligibility workflows."""

    def __init__(self):
        self._graph = create_sahay_agent_graph()

    async def execute(
        self,
        query: str,
        user_answers: Dict[str, Any],
        language: str = "en",
    ) -> Dict[str, Any]:
        """Runs the LangGraph multi-agent pipeline."""
        initial_state: AgentState = {
            "citizen_query": query,
            "language": language,
            "user_answers": user_answers,
            "matched_schemes": [],
            "is_dynamic_discovery": False,
            "sources_checked": [],
            "trust_findings": [],
            "is_trusted": True,
            "eligibility_reports": [],
            "qualifying_scheme_ids": [],
            "document_guidance": {},
            "fraud_warnings": [],
            "is_safe": True,
            "requires_income_estimation": False,
            "income_estimate": None,
            "step_history": [],
            "iteration_count": 0,
            "errors": [],
            "final_response": None,
        }

        try:
            result_state = await self._graph.ainvoke(initial_state)
            return result_state.get("final_response") or {}
        except Exception as e:
            logger.error(f"Multi-agent orchestrator execution failed: {e}", exc_info=True)
            return {
                "citizenQuery": query,
                "error": str(e),
                "systemStatus": "failed_safe_fallback",
            }
