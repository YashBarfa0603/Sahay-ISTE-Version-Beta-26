"""
Hybrid Scheme Discovery Pipeline Orchestrator.
Coordinates: Catalogue Search -> Tavily Discovery -> BeautifulSoup Scraping ->
Qwen2.5 (Ollama) Extraction -> Verification Audit -> Persistence Queue.
"""

import logging
from typing import List
from backend.app.config import settings
from backend.app.database.db_interface import SchemeDatabaseInterface
from backend.app.models.scheme_schemas import (
    SchemeModelSchema,
    SchemeSearchQuery,
    SchemeSearchResponse,
    VerificationStatus,
)
from backend.app.services.tavily_service import TavilyService
from backend.app.services.scraper_service import ScraperService
from backend.app.services.ollama_service import OllamaService
from backend.app.services.verification_service import VerificationService

logger = logging.getLogger(__name__)


class DiscoveryPipeline:
    """End-to-end hybrid discovery workflow orchestrator."""

    def __init__(
        self,
        db: SchemeDatabaseInterface,
        tavily: TavilyService,
        scraper: ScraperService,
        ollama: OllamaService,
        verifier: VerificationService,
    ):
        self.db = db
        self.tavily = tavily
        self.scraper = scraper
        self.ollama = ollama
        self.verifier = verifier

    async def execute_search(self, request: SchemeSearchQuery) -> SchemeSearchResponse:
        """Executes the 10-step hybrid discovery pipeline."""
        query = request.query.strip()
        logger.info(f"Initiating scheme search for: '{query}'")

        # Step 2: Search trusted catalogue through database interface
        catalogue_results = await self.db.search_schemes(
            query=query,
            category=request.category,
            level=request.governmentLevel,
            state=request.state,
        )

        # Step 3: If sufficient verified results exist and dynamic discovery not forced, return them
        if len(catalogue_results) >= settings.CATALOGUE_MIN_RESULTS and not request.forceDynamicDiscovery:
            logger.info(f"Returning {len(catalogue_results)} verified catalogue results.")
            return SchemeSearchResponse(
                total=len(catalogue_results),
                results=catalogue_results,
                isDynamicDiscovery=False,
                sourcesChecked=["Trusted Scheme Catalogue"],
                message="Results retrieved from verified government scheme database.",
            )

        # Step 4: Otherwise, trigger Tavily Dynamic Discovery
        logger.info(f"Catalogue results ({len(catalogue_results)}) below threshold. Invoking Tavily.")
        tavily_results = await self.tavily.search_government_schemes(query, max_results=3)

        discovered_schemes: List[SchemeModelSchema] = []
        sources_checked = ["Trusted Scheme Catalogue", "Tavily Search API"]
        existing_all = await self.db.list_all_schemes()

        for t_item in tavily_results:
            url = t_item.get("url", "")
            title = t_item.get("title", "")
            snippet = t_item.get("content", "")

            if not url:
                continue

            sources_checked.append(url)

            # Step 5: Extract relevant webpage content using BeautifulSoup
            extracted_text = await self.scraper.extract_content(url)
            full_text = extracted_text if extracted_text else snippet

            # Step 6 & 7: Use Qwen2.5 through Ollama to extract structured scheme information
            candidate_scheme = await self.ollama.extract_scheme_data(
                raw_text=full_text,
                source_url=url,
                source_name=title,
            )

            if not candidate_scheme:
                continue

            # Step 8: Run source credibility, freshness, completeness and conflict checks
            audited_scheme, report = self.verifier.audit_scheme(
                candidate=candidate_scheme,
                existing_catalog=existing_all,
            )

            # Filter out non-credible/rejected or duplicates of existing records
            if report.is_duplicate:
                logger.info(f"Skipping duplicate scheme: {audited_scheme.name}")
                continue
            if audited_scheme.verificationStatus == VerificationStatus.rejected:
                logger.warning(f"Rejected non-credible candidate: {audited_scheme.name}")
                continue

            # Step 10: Pass approved records to the database integration interface
            await self.db.save_discovered_scheme(audited_scheme)
            discovered_schemes.append(audited_scheme)

        # Combine results: catalogue matches first, followed by discovered schemes (with pending verification)
        combined_results = list(catalogue_results) + discovered_schemes

        return SchemeSearchResponse(
            total=len(combined_results),
            results=combined_results,
            isDynamicDiscovery=len(discovered_schemes) > 0,
            sourcesChecked=sources_checked,
            message=(
                f"Found {len(catalogue_results)} verified and {len(discovered_schemes)} newly discovered schemes "
                "(discovered schemes marked as under verification)."
                if discovered_schemes
                else f"Found {len(catalogue_results)} schemes in verified catalogue."
            ),
        )

