"""
Scheme Catalogue API Router.
Provides verified scheme lookup, category filtering, and detail retrieval.
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from backend.app.database.db_interface import SchemeDatabaseInterface, get_scheme_db
from backend.app.models.scheme_schemas import (
    GovernmentLevel,
    SchemeModelSchema,
)

router = APIRouter(prefix="/api/schemes", tags=["Schemes"])


@router.get("", response_model=List[SchemeModelSchema])
async def list_schemes(
    category: Optional[str] = Query(None, description="Filter by scheme welfare category"),
    level: Optional[GovernmentLevel] = Query(None, description="Filter by central or state government level"),
    state: Optional[str] = Query(None, description="Filter by specific Indian State/UT"),
    limit: int = Query(50, ge=1, le=100),
    db: SchemeDatabaseInterface = Depends(get_scheme_db),
):
    """Retrieves list of schemes with optional filtering."""
    if category or level or state:
        return await db.search_schemes(
            query="",
            category=category,
            level=level,
            state=state,
            limit=limit,
        )
    return await db.list_all_schemes(limit=limit)


@router.get("/{scheme_id}", response_model=SchemeModelSchema)
async def get_scheme_by_id(
    scheme_id: str,
    db: SchemeDatabaseInterface = Depends(get_scheme_db),
):
    """Fetches full metadata and eligibility rules for a specific scheme."""
    scheme = await db.get_scheme(scheme_id)
    if not scheme:
        raise HTTPException(status_code=404, detail=f"Scheme with ID '{scheme_id}' not found")
    return scheme


@router.get("/categories/all")
async def list_categories():
    """Lists standard scheme categories supported by SAHAY."""
    return [
        {"id": "agriculture", "name": "Agriculture & Farming", "nameHindi": "कृषि एवं किसानी", "icon": "grass"},
        {"id": "health", "name": "Health & Healthcare", "nameHindi": "स्वास्थ्य एवं चिकित्सा", "icon": "health_and_safety"},
        {"id": "housing", "name": "Housing & Shelter", "nameHindi": "आवास एवं आश्रय", "icon": "home"},
        {"id": "education", "name": "Education & Learning", "nameHindi": "शिक्षा एवं छात्रवृत्ति", "icon": "school"},
        {"id": "women", "name": "Women & Child Development", "nameHindi": "महिला एवं बाल विकास", "icon": "family_restroom"},
        {"id": "employment", "name": "Employment & Skills", "nameHindi": "रोजगार एवं कौशल", "icon": "work"},
        {"id": "socialWelfare", "name": "Social Welfare & Security", "nameHindi": "सामाजिक कल्याण एवं सुरक्षा", "icon": "volunteer_activism"},
        {"id": "financial", "name": "Financial Inclusion & Loans", "nameHindi": "वित्तीय समावेशन एवं ऋण", "icon": "account_balance"},
    ]

