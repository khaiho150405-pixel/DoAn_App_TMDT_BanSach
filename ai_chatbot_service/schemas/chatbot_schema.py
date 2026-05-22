from typing import Any

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    session_id: str | None = Field(default=None, alias="sessionId")
    user_id: int | None = Field(default=None, alias="userId")
    metadata: dict[str, Any] = Field(default_factory=dict)

    model_config = {
        "populate_by_name": True,
        "json_schema_extra": {
            "example": {
                "userId": 12,
                "sessionId": "mobile-session-abc",
                "message": "Can you suggest beginner programming books?",
                "metadata": {"source": "flutter"},
            }
        },
    }


class RecommendedBookCard(BaseModel):
    book_id: int = Field(alias="bookId")
    title: str
    author: str | None = None
    category: str | None = None
    image: str | None = None
    price: float | None = None
    rating: float | None = None
    reason: str | None = None

    model_config = {"populate_by_name": True}


class BookSuggestion(RecommendedBookCard):
    pass


class FaqSuggestion(BaseModel):
    question: str
    answer: str
    confidence: float = Field(default=0.0, ge=0.0, le=1.0)


class ChatResponse(BaseModel):
    reply: str
    recommended_books: list[RecommendedBookCard] = Field(
        default_factory=list,
        alias="recommendedBooks",
    )

    model_config = {
        "populate_by_name": True,
        "json_schema_extra": {
            "example": {
                "reply": "I found a few books that may fit your request.",
                "recommendedBooks": [
                    {
                        "bookId": 1,
                        "title": "Clean Code",
                        "author": "Robert C. Martin",
                        "category": "Programming",
                        "image": "clean_code.jpg",
                        "price": 350000,
                        "rating": 4.8,
                        "reason": "Matches your interest in programming books.",
                    }
                ],
            }
        },
    }
