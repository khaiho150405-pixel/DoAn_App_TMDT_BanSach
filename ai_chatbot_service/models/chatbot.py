from enum import StrEnum
from pydantic import BaseModel, Field


class ChatIntent(StrEnum):
    UNKNOWN = "unknown"
    FAQ = "faq"
    BOOK_SEARCH = "book_search"
    SEMANTIC_RECOMMENDATION = "semantic_recommendation"
    ORDER_SUPPORT = "order_support"
    SMALL_TALK = "small_talk"


class ChatResult(BaseModel):
    intent: ChatIntent = ChatIntent.UNKNOWN
    reply: str
    confidence: float = Field(default=0.0, ge=0.0, le=1.0)
