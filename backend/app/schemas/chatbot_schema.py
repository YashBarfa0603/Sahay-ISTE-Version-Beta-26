"""
Pydantic schemas for the SAHAY Assistance AI Chatbot.
Supports conversational support, screen-aware context, verified navigation actions,
and multilingual question handling.
"""

from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class NavigationAction(BaseModel):
    """
    Structured navigation payload allowing SAHAY Assistance to suggest verified,
    client-executable navigation actions.
    """
    action: str = Field(..., description="Action identifier, e.g. start_fill_with_sahay, open_document_vault, open_eligibility, open_schemes")
    title: str = Field(..., description="Human-readable button label in the active language")
    scheme_id: Optional[str] = Field(None, description="Target scheme identifier if action is scheme-specific")
    scheme_name: Optional[str] = Field(None, description="Target scheme name if action is scheme-specific")
    route: Optional[str] = Field(None, description="App navigation route if directly navigable")
    parameters: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Additional arguments for client navigation")


class ChatbotMessageRequest(BaseModel):
    """Incoming user message payload with screen-aware context."""
    message: str = Field(..., min_length=1, max_length=2000, description="Citizen inquiry text")
    conversation_id: Optional[str] = Field(None, description="Active conversation session ID")
    current_screen: Optional[str] = Field(None, description="Identifier of the active screen (e.g. home, scheme_detail, document_vault)")
    current_module: Optional[str] = Field(None, description="Active module (e.g. discovery, eligibility, application, documents)")
    current_workflow_stage: Optional[str] = Field(None, description="Active stage in multi-step workflows (e.g. stage_3_missing_info)")
    selected_scheme_id: Optional[str] = Field(None, description="Scheme ID currently being viewed or applied for")
    selected_scheme_name: Optional[str] = Field(None, description="Scheme name currently being viewed or applied for")
    app_language: Optional[str] = Field("en", description="Current app UI language ('en' or 'hi')")


class ChatbotMessageResponse(BaseModel):
    """Outgoing assistant response with suggested follow-up prompts and navigation actions."""
    conversation_id: str = Field(..., description="Unique conversation session ID")
    assistant_message: str = Field(..., description="Knowledge-grounded, helpful markdown-formatted assistant response")
    suggested_questions: List[str] = Field(default_factory=list, description="2-4 contextual quick-tap prompts")
    navigation_action: Optional[NavigationAction] = Field(None, description="Optional validated navigation action chip")
    response_language: str = Field("en", description="Detected or requested response language")
    response_status: str = Field("success", description="Response status: 'success', 'fallback', or 'error'")


class ContextPromptsResponse(BaseModel):
    """Contextual prompt suggestions for the active screen."""
    current_screen: str
    suggested_questions: List[str]
    welcome_message: str

