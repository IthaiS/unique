# Backend (FastAPI)
Run locally:
```bash
python -m venv .venv && source .venv/bin/activate
pip install -r backend/requirements.txt
pytest -q
uvicorn backend.api:app --reload --port 8080
```
Docker:
```bash
docker build -t foodlabel-backend:local -f backend/Dockerfile .
docker run -p 8080:8080 foodlabel-backend:local
```
