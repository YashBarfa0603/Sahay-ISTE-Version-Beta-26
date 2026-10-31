from pathlib import Path
from typing import List
from pydantic import ConfigDict
from pydantic_settings import BaseSettings

_BACKEND_DIR = Path(__file__).resolve().parent.parent
_PROJECT_ROOT = _BACKEND_DIR.parent


class Settings(BaseSettings):
    APP_NAME: str = "SAHAY Backend API"
    APP_VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"  # "development", "testing", "production"
    ALLOW_MOCK_TOKENS: bool = False
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
        "pib.gov.in",
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

    # Firebase Admin SDK Service Account Credentials (path to JSON key file)
    GOOGLE_APPLICATION_CREDENTIALS: str = ""

    # Cloudinary Document Vault Settings
    CLOUDINARY_CLOUD_NAME: str = ""
    CLOUDINARY_API_KEY: str = ""
    CLOUDINARY_API_SECRET: str = ""
    CLOUDINARY_SECURE_VAULT_FOLDER: str = "sahay/document_vault"

    model_config = ConfigDict(
        env_file=(
            str(_BACKEND_DIR / ".env"),
            str(_PROJECT_ROOT / ".env"),
            ".env",
        ),
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()

