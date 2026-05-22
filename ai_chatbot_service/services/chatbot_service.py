from typing import Any

from schemas.chatbot_schema import ChatRequest, ChatResponse, RecommendedBookCard
from services.memory_service import (
    ConversationContext,
    ConversationMemoryService,
    get_conversation_memory_service,
)


class ChatbotService:
    """Coordinates intent detection, FAQ lookup, search, and response building.

    This skeleton intentionally does not implement recommendation or semantic
    search logic yet. Those responsibilities should be added as separate
    services and injected here.
    """

    def __init__(self, memory_service: ConversationMemoryService | None = None) -> None:
        self._memory_service = memory_service or get_conversation_memory_service()

    async def handle_message(self, request: ChatRequest) -> ChatResponse:
        session_key = self._memory_service.build_session_key(
            request.session_id,
            request.user_id,
        )

        try:
            normalized_message = request.message.strip()
            if not normalized_message:
                return self._fallback_response()

            context = self._memory_service.get_context(session_key)
            intent = self._infer_intent(normalized_message)
            self._memory_service.add_turn(
                session_key=session_key,
                role="user",
                message=normalized_message,
                metadata={"intent": intent},
            )

            recommended_books = self._extract_recommended_books(request.metadata)
            reply = self._build_reply(
                message=normalized_message,
                recommended_books=recommended_books,
                context=context,
                intent=intent,
            )
            self._memory_service.add_turn(
                session_key=session_key,
                role="assistant",
                message=reply,
                metadata={
                    "intent": intent,
                    "recommendedBookCount": len(recommended_books),
                },
            )

            return ChatResponse(
                reply=reply,
                recommended_books=recommended_books,
            )
        except Exception:
            return self._error_response()

    def _build_reply(
        self,
        message: str,
        recommended_books: list[RecommendedBookCard],
        context: ConversationContext,
        intent: str,
    ) -> str:
        lowered_message = message.lower()

        if recommended_books:
            if len(recommended_books) == 1:
                return (
                    "I found one book that looks like a good match for your request. "
                    "You can open the card below to see more details."
                )
            return (
                f"I found {len(recommended_books)} books that may fit your request. "
                "I sorted them as recommendation cards so you can compare them quickly."
            )

        contextual_reply = self._build_contextual_reply(
            message=message,
            lowered_message=lowered_message,
            context=context,
            intent=intent,
        )
        if contextual_reply:
            return contextual_reply

        if any(keyword in lowered_message for keyword in ["hello", "hi", "xin chao", "chao"]):
            return (
                "Hi, I can help you find books by title, author, category, price, "
                "promotion, or reading taste. What kind of book are you looking for?"
            )

        if any(keyword in lowered_message for keyword in ["khuyen mai", "giam gia", "sale", "voucher"]):
            return (
                "I can help you check current promotions. I do not have promotion "
                "results attached to this response yet, so please try a more specific "
                "book title or category."
            )

        if any(keyword in lowered_message for keyword in ["goi y", "de xuat", "recommend", "nen doc"]):
            return (
                "I can recommend books based on your interests. Tell me a genre, "
                "author, or a book you enjoyed, and I will prepare better suggestions."
            )

        if any(keyword in lowered_message for keyword in ["tim", "search", "sach", "book"]):
            return (
                "I can search the bookstore by title, author, category, or price range. "
                "Please include one of those details so I can narrow the result."
            )

        return (
            "I am here to help with bookstore questions, book search, promotions, "
            "and recommendations. Could you share a little more detail?"
        )

    def _build_contextual_reply(
        self,
        message: str,
        lowered_message: str,
        context: ConversationContext,
        intent: str,
    ) -> str | None:
        previous_user_message = context.last_user_message
        previous_intent = context.last_intent
        if not previous_user_message or context.message_count == 0:
            return None

        follow_up_keywords = ["khac", "nua", "them", "tiep", "more", "another"]
        price_keywords = ["gia", "bao nhieu", "price"]
        detail_keywords = ["chi tiet", "tac gia", "the loai", "noi dung", "detail"]

        if any(keyword in lowered_message for keyword in follow_up_keywords):
            if previous_intent in {"recommend_book", "search_book"}:
                return (
                    "Minh se tiep tuc dua tren yeu cau truoc cua ban: "
                    f"'{previous_user_message}'. Hien tai minh can module tim kiem/goi y "
                    "tra ve danh sach sach de hien thi thanh card."
                )

        if any(keyword in lowered_message for keyword in price_keywords):
            return (
                "Ban dang hoi tiep ve gia sach. Neu ban gui ten sach cu the, "
                "minh co the chuan bi truy van gia va khuyen mai lien quan."
            )

        if any(keyword in lowered_message for keyword in detail_keywords):
            return (
                "Minh hieu day la cau hoi tiep ve thong tin sach. Hay gui ten sach "
                "hoac chon mot card goi y de xem tac gia, the loai va mo ta chi tiet."
            )

        if intent == "faq" and previous_intent == "promotion":
            return (
                "Ve khuyen mai, minh co the ho tro them cac cau hoi nhu dieu kien ap dung, "
                "thoi gian ket thuc hoac cach dung ma giam gia."
            )

        return None

    def _infer_intent(self, message: str) -> str:
        lowered_message = message.lower()
        if any(keyword in lowered_message for keyword in ["khuyen mai", "giam gia", "sale", "voucher"]):
            return "promotion"
        if any(keyword in lowered_message for keyword in ["goi y", "de xuat", "recommend", "nen doc"]):
            return "recommend_book"
        if any(keyword in lowered_message for keyword in ["tim", "search", "sach", "book"]):
            return "search_book"
        if any(keyword in lowered_message for keyword in ["hello", "hi", "xin chao", "chao"]):
            return "greeting"
        return "faq"

    def _extract_recommended_books(self, metadata: dict[str, Any]) -> list[RecommendedBookCard]:
        raw_books = metadata.get("recommendedBooks") or metadata.get("recommended_books") or []
        if not isinstance(raw_books, list):
            return []

        cards: list[RecommendedBookCard] = []
        for raw_book in raw_books:
            if not isinstance(raw_book, dict):
                continue
            try:
                cards.append(RecommendedBookCard.model_validate(raw_book))
            except Exception:
                continue

        return cards

    def _fallback_response(self) -> ChatResponse:
        return ChatResponse(
            reply=(
                "I did not catch a message yet. Please tell me the book, author, "
                "category, price range, or reading style you are interested in."
            ),
            recommended_books=[],
        )

    def _error_response(self) -> ChatResponse:
        return ChatResponse(
            reply=(
                "Sorry, I could not prepare a chatbot response right now. "
                "Please try again in a moment."
            ),
            recommended_books=[],
        )


def get_chatbot_service() -> ChatbotService:
    return ChatbotService()
