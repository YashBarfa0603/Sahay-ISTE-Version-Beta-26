"""
Multi-Agent Orchestrator API Router.
Executes the LangGraph multi-agent pipeline for scheme discovery, verification, and eligibility.
"""

from typing import Any, Dict
from fastapi import APIRouter
from pydantic import BaseModel, Field
from backend.app.agents.orchestrator import SahayMultiAgentOrchestrator

router = APIRouter(prefix="/api/agents", tags=["Agents"])

_orchestrator = SahayMultiAgentOrchestrator()


class AgentAssessmentRequest(BaseModel):
    query: str = Field(..., description="Citizen natural language query")
    user_answers: Dict[str, Any] = Field(default_factory=dict, description="Citizen demographic answers")
    language: str = Field("en", description="Preferred language code (en, hi, etc.)")


@router.post("/assess")
async def run_multi_agent_assessment(request: AgentAssessmentRequest):
    """
    Executes the multi-agent pipeline:
    Discovery -> Trust & Verification -> Deterministic Eligibility -> Document Guidance -> Fraud Checks -> Income Assistance (conditional) -> Aggregation.
    """
    return await _orchestrator.execute(
        query=request.query,
        user_answers=request.user_answers,
        language=request.language,
    )
