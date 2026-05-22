# BookStore AI Recommendation Service

FastAPI microservice for book recommendations.

## Run

```powershell
cd ai_recommendation_service
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

## APIs

- `POST /recommend/user`
- `POST /recommend/book`
- `GET /health`

The ASP.NET Core API sends book features and user behavior to this service.
