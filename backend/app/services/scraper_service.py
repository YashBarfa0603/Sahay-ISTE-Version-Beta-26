"""
Webpage Content Extraction Service using BeautifulSoup.
Extracts and normalizes scheme documentation from official government URLs.
"""

import logging
import re
from typing import Optional
from bs4 import BeautifulSoup
import httpx

logger = logging.getLogger(__name__)


class ScraperService:
    """Extracts readable scheme content from government webpage HTML."""

    USER_AGENT = "Mozilla/5.0 (compatible; SAHAYGovSchemeBot/1.0; +https://sahay.gov.in)"

    async def extract_content(self, url: str) -> Optional[str]:
        """
        Fetches the webpage at `url` and extracts cleaned textual content.
        Removes scripts, styles, navigations, and footers.
        """
        try:
            headers = {
                "User-Agent": self.USER_AGENT,
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9,hi;q=0.8",
            }
            async with httpx.AsyncClient(timeout=10.0, follow_redirects=True) as client:
                response = await client.get(url, headers=headers)
                if response.status_code != 200:
                    logger.warning(f"Failed to fetch {url}: status {response.status_code}")
                    return None
                html = response.text

            return self.parse_html_content(html)
        except Exception as e:
            logger.error(f"Error scraping content from {url}: {e}")
            return None

    def parse_html_content(self, html: str) -> str:
        """Parses raw HTML and extracts the main text body with high signal-to-noise ratio."""
        soup = BeautifulSoup(html, "html.parser")

        # Strip unhelpful elements
        for element in soup(["script", "style", "nav", "footer", "header", "aside", "noscript", "svg"]):
            element.extract()

        # Prioritize main content containers if present
        main_content = (
            soup.find("main")
            or soup.find("article")
            or soup.find("div", {"id": re.compile(r"content|main|scheme", re.I)})
            or soup.find("div", {"class": re.compile(r"content|main|scheme|details", re.I)})
            or soup.body
        )

        if not main_content:
            text = soup.get_text(separator=" ")
        else:
            text = main_content.get_text(separator=" ")

        # Clean excess whitespaces and blank lines
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        cleaned_text = " ".join(lines)
        cleaned_text = re.sub(r"\s+", " ", cleaned_text)

        # Truncate to reasonable context window for Qwen2.5 (around 3000 words / 15000 chars)
        if len(cleaned_text) > 15000:
            cleaned_text = cleaned_text[:15000] + "..."

        return cleaned_text

