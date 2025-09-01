# Backend (FastAPI)

Endpoints:
- `POST /v1/assess` — payload `{ "ingredients": ["milk", "sugar"] }`, returns score + verdict + reasons.

Run locally:
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r backend/requirements.txt
uvicorn backend.api:app --reload
```

Test:
```bash
pytest -q
```

Docker:
```bash
docker build -t foodlabel-backend -f backend/Dockerfile .
docker run -p 8080:8080 foodlabel-backend
```
