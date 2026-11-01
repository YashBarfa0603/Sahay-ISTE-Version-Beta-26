"""
FastAPI Router for SAHAY Assistance AI Chatbot.
Provides conversational scheme support, screen-aware question suggestions,
and verified navigation actions.
"""

from typing import List, Optional
from fastapi import APIRouter, Query, status

from backend.app.schemas.chatbot_schema import (
    ChatbotMessageRequest,
    ChatbotMessageResponse,
    ContextPromptsResponse,
)
from backend.app.services.chatbot_service import ChatbotService

router = APIRouter(prefix="/api/assistance", tags=["SAHAY Assistance Chatbot"])
chatbot_service = ChatbotService()


@router.post("/chat", response_model=ChatbotMessageResponse)
async def chat_with_sahay(request: ChatbotMessageRequest):
    """
    Conversational support endpoint for citizens seeking help using SAHAY.
    Accepts screen context, scheme identifiers, and questions in English or Hindi.
    Returns grounded answers, quick follow-up prompts, and validated navigation action chips.
    """
    return await chatbot_service.process_chat_message(request)


@router.get("/context-prompts", response_model=ContextPromptsResponse)
async def get_screen_prompts(
    current_screen: Optional[str] = Query(None, description="Active screen identifier (e.g. scheme_detail, document_vault)"),
    selected_scheme_id: Optional[str] = Query(None, description="Currently selected scheme ID"),
    language: str = Query("en", description="Client language code ('en' or 'hi')"),
):
    """Returns contextual quick question chips and welcome text tailored for the user's active screen."""
    return chatbot_service.get_contextual_prompts(
        current_screen=current_screen,
        selected_scheme_id=selected_scheme_id,
        language=language,
    )

