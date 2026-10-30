from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    APP_NAME: str = "SAHAY Backend API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # Tavily Search API
    TAVILY_API_KEY: str = ""

    # Ollama AI Model (Qwen2.5)
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "qwen2.5:latest"

    # Prioritized Government Domains for Scheme Discovery
    TRUSTED_GOV_DOMAINS: List[str] = [
        "myscheme.gov.in",
        "india.gov.in",
        "data.gov.in",
        "pmkisan.gov.in",
        "pmjay.gov.in",
        "pmayg.nic.in",
        "pmuy.gov.in",
        "desw.gov.in",
        "ladlibahna.mp.gov.in",
        "nic.in",
        "gov.in",
    ]

    # Minimum similarity / result count threshold to avoid Tavily search
    CATALOGUE_MIN_RESULTS: int = 3

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()

