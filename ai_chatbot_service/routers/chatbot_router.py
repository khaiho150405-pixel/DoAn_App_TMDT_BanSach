from fastapi import APIRouter, Depends

from schemas.chatbot_schema import ChatRequest, ChatResponse
from services.chatbot_service import ChatbotService, get_chatbot_service


router = APIRouter()


@router.post("/message", response_model=ChatResponse)
async def send_message(
    request: ChatRequest,
    service: ChatbotService = Depends(get_chatbot_service),
) -> ChatResponse:
    return await service.handle_message(request)
