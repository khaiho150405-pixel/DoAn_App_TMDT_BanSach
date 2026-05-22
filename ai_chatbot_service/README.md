# BookStore AI Chatbot Service

FastAPI skeleton for the BookStore AI chatbot.

## Structure

```text
ai_chatbot_service/
  main.py
  routers/
    chatbot_router.py
  services/
    chatbot_service.py
  models/
    chatbot.py
  schemas/
    chatbot_schema.py
  requirements.txt
```

## Run

```powershell
cd ai_chatbot_service
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8002 --reload
```

## Current API

- `GET /health`
- `POST /chatbot/message`

Recommendation, FAQ matching, and database search logic are intentionally not implemented yet.
