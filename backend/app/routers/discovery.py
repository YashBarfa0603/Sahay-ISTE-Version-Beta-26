"""
Dynamic Scheme Discovery API Router.
Coordinates hybrid search across trusted catalogue, Tavily, and Qwen2.5.
"""

from fastapi import APIRouter, Depends
from backend.app.database.db_interface import SchemeDatabaseInterface, get_scheme_db
from backend.app.models.scheme_schemas import (
    SchemeSearchQuery,
    SchemeSearchResponse,
)
from backend.app.services.tavily_service import TavilyService
from backend.app.services.scraper_service import ScraperService
from backend.app.services.ollama_service import OllamaService
from backend.app.services.verification_service import VerificationService
from backend.app.services.discovery_pipeline import DiscoveryPipeline

router = APIRouter(prefix="/api/schemes", tags=["Discovery"])

# Service singletons
_tavily = TavilyService()
_scraper = ScraperService()
_ollama = OllamaService()
_verifier = VerificationService()


def get_discovery_pipeline(
    db: SchemeDatabaseInterface = Depends(get_scheme_db),
) -> DiscoveryPipeline:
    return DiscoveryPipeline(
        db=db,
        tavily=_tavily,
        scraper=_scraper,
        ollama=_ollama,
        verifier=_verifier,
    )


@router.post("/search", response_model=SchemeSearchResponse)
async def search_and_discover_schemes(
    query: SchemeSearchQuery,
    pipeline: DiscoveryPipeline = Depends(get_discovery_pipeline),
):
    """
    Search schemes with automatic dynamic discovery trigger.
    If verified catalogue lacks sufficient matches, triggers Tavily + BeautifulSoup +
    Qwen2.5 extraction pipeline and performs strict authenticity verification.
    """
    return await pipeline.execute_search(query)

