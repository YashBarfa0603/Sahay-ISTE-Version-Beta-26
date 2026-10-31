"""
SAHAY (सहाय) — FastAPI Backend Application Entrypoint.
Multilingual Indian Government Scheme Discovery & AI Extraction Engine.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.app.config import settings
from backend.app.routers import schemes, discovery, assistance, agents, versioning, eligibility, applications

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description=(
        "Backend API for SAHAY (सहाय) — Indian Government Scheme Discovery and "
        "Eligibility Assessment. Features hybrid scheme retrieval via trusted catalogue, "
        "Tavily Search API, BeautifulSoup extraction, and Qwen2.5 (Ollama) structuring."
    ),
)

# Configure CORS for Flutter client communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(schemes.router)
app.include_router(discovery.router)
app.include_router(assistance.router)
app.include_router(agents.router)
app.include_router(versioning.router)
app.include_router(eligibility.router)
app.include_router(applications.router)


@app.get("/api/health", tags=["Health"])
async def health_check():
    """Health check endpoint for container and client connectivity."""
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "ollama_model": settings.OLLAMA_MODEL,
        "trusted_domains_count": len(settings.TRUSTED_GOV_DOMAINS),
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("backend.app.main:app", host="0.0.0.0", port=8000, reload=True)

