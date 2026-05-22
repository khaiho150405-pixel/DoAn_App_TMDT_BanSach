from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers.chatbot_router import router as chatbot_router


def create_app() -> FastAPI:
    app = FastAPI(
        title="BookStore AI Chatbot Service",
        version="0.1.0",
        description="AI chatbot service skeleton for BookStore.",
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(chatbot_router, prefix="/chatbot", tags=["chatbot"])

    @app.get("/health", tags=["health"])
    def health_check() -> dict[str, str]:
        return {"status": "ok"}

    return app


app = create_app()
