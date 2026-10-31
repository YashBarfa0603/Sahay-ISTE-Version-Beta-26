"""
Agent 1: Scheme Discovery Agent.
Understands citizen intent, queries verified scheme catalogue, and initiates dynamic discovery if needed.
"""

import logging
from typing import Any, Dict
from backend.app.agents.state import AgentState
from backend.app.database.db_interface import get_scheme_db
from backend.app.models.scheme_schemas import SchemeSearchQuery
from backend.app.services.discovery_pipeline import DiscoveryPipeline
from backend.app.services.ollama_service import OllamaService
from backend.app.services.scraper_service import ScraperService
from backend.app.services.tavily_service import TavilyService
from backend.app.services.verification_service import VerificationService

logger = logging.getLogger(__name__)


async def run_discovery_agent(state: AgentState) -> Dict[str, Any]:
    """Retrieves relevant schemes matching the citizen query and profile answers."""
    query = state.get("citizen_query", "").strip()
    answers = state.get("user_answers", {})
    state_filter = answers.get("state")
    category_filter = answers.get("category")

    db = get_scheme_db()
    pipeline = DiscoveryPipeline(
        db=db,
        tavily=TavilyService(),
        scraper=ScraperService(),
        ollama=OllamaService(),
        verifier=VerificationService(),
    )

    search_req = SchemeSearchQuery(
        query=query,
        category=category_filter,
        state=state_filter,
        forceDynamicDiscovery=False,
    )

    try:
        search_res = await pipeline.execute_search(search_req)
        schemes_dicts = [s.model_dump() for s in search_res.results]
        sources = search_res.sourcesChecked
        is_dynamic = search_res.isDynamicDiscovery
    except Exception as e:
        logger.error(f"Discovery agent encountered error: {e}")
        # Graceful fallback to all baseline schemes
        all_schemes = await db.list_all_schemes(limit=10)
        schemes_dicts = [s.model_dump() for s in all_schemes]
        sources = ["Verified Baseline Scheme Catalogue"]
        is_dynamic = False

    history = list(state.get("step_history", []))
    history.append("DiscoveryAgent")

    return {
        "matched_schemes": schemes_dicts,
        "is_dynamic_discovery": is_dynamic,
        "sources_checked": sources,
        "step_history": history,
        "iteration_count": state.get("iteration_count", 0) + 1,
    }

