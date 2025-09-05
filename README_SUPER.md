# FoodLabel AI – Super Bundle v1.1.1

This repository contains the **entire system** for FoodLabel AI:
- **Flutter mobile/desktop app** (OCR via ML Kit on Android/iOS, backend OCR via Cloud Vision on Windows/macOS).
- **FastAPI backend** with `/v1/ocr` (Google Vision API) and `/v1/assess` (ingredient analysis).
- **Infrastructure as Code** (Terraform) to set up GCP Workload Identity Federation, Cloud Run, Artifact Registry, and Vision API.
- **GitHub Actions workflows** for CI/CD, infra management, Sentry, and Slack notifications.
- **Scripts** to bootstrap, sync GitHub secrets, expand bundles, and validate presence of critical files.
- **Documentation** with setup guides, architecture diagrams, repo structure, and security hardening.

---

# Quick Start

## 📦 Prerequisites

- **Python 3.13** (3.11/3.12 also work if you prefer; update Dockerfile accordingly)
- **Docker + Docker Compose** (optional, for containerized runs)
- **Google Cloud Vision credentials** if you use OCR:
  - Create a service account JSON and set `GOOGLE_APPLICATION_CREDENTIALS`
- **Infrastructure**
  1. cd foodlabel-ai/infra/stack 
  2. cp cp terraform.tfvars.example terraform.tfvars
  3. adjust values in terraform.tfvars
  4. terraform init -upgrade 
  5. execute ./scripts/tfimports.sh
  6. terraform plan -out=tfplan
  7. terraform apply tfplan


## 🚀 1) Local Development (without Docker)

### 1.1 Create and activate a virtual environment
```bash
python -m venv .venv

# Windows (PowerShell / CMD)
.venv\Scripts\activate

# macOS/Linux
source .venv/bin/activate
```

### 1.2 Install dependencies
```bash
# Runtime only
pip install -r requirements.txt

# Dev + runtime (tests, linters)
pip install -r requirements-dev.txt
```

### 1.3 Run the API locally
```bash
uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```
> ⚠️ Change `backend.main:app` if your FastAPI app object lives elsewhere (e.g., `backend.api.server:app`).

Open the docs: [http://localhost:8000/docs](http://localhost:8000/docs)

### 1.4 Run tests
```bash
python -m pytest -q
```
> If Python cannot import `backend.*`, ensure you run pytest from the project root and that `backend/__init__.py` exists, or add a `tests/conftest.py` to adjust `sys.path`.

---

## 🔑 2) Environment Variables
```bash
# Windows
set GOOGLE_APPLICATION_CREDENTIALS=creds.json

# macOS/Linux
export GOOGLE_APPLICATION_CREDENTIALS=creds.json
```
In Docker/Compose, either bake the file into the image or mount it and set the path to `/app/creds.json`.

---

## 🐳 3) Docker (single container)

### 3.1 Build and run (production-like)
```bash
docker build -t foodscanner-api:prod --target prod .
docker run --rm -p 8000:8000 foodscanner-api:prod
```
Open: [http://localhost:8000/docs](http://localhost:8000/docs)

### 3.2 Build and run (dev with hot reload)
```bash
docker build -t foodscanner-api:dev --target dev .

# Windows PowerShell
docker run --rm -p 8000:8000 -v ${PWD}/backend:/app/backend foodscanner-api:dev

# Windows CMD
docker run --rm -p 8000:8000 -v %cd%/backend:/app/backend foodscanner-api:dev

# macOS/Linux
docker run --rm -p 8000:8000 -v $(pwd)/backend:/app/backend foodscanner-api:dev
```

---

## 🧩 4) Docker Compose

### 4.1 Start prod-like service
```bash
docker compose up --build api
```
Or detached:
```bash
docker compose up -d --build api
```

### 4.2 Start dev service (hot reload)
```bash
docker compose up --build api-dev
```
Or detached:
```bash
docker compose up -d --build api-dev
```

### 4.3 Stop services
```bash
docker compose down
```

---

## 📂 5) Files of Interest
```
backend/assess.py         # includes assess_tokens and FastAPI routes
backend/.../main.py       # defines FastAPI app object
requirements.txt          # runtime dependencies
requirements-dev.txt      # dev/test tooling, includes runtime via -r requirements.txt
Dockerfile                # multi-stage build (prod & dev targets)
docker-compose.yml        # defines services api (prod) and api-dev (dev with reload)
```

---

## 🛠️ 6) Common Issues
```
- `pytest: command not found` (Windows): use `python -m pytest -q`, or add your Python Scripts dir to PATH.
- `ModuleNotFoundError: backend` during tests: run pytest from project root; ensure backend/__init__.py exists; or use tests/conftest.py.
- FastAPI import error in tests: make sure you installed requirements.txt (or isolate core logic in a FastAPI-free module for minimal test deps).
- Wrong app import path: update uvicorn target (backend.main:app) everywhere (CLI, Dockerfile, docker-compose).
```

---

## ❤️ 7) Health Check (optional)
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s CMD curl -fsS http://localhost:8000/health || exit 1
```

---

## Or if you are lazy ... 
### Local
- backend
```./run_local.sh
## Show live logs:
$ LIVE_LOGS=1 ./run_local.sh

## Quiet mode (default)
$ ./run_local.sh

## Custom log file
$ LOG_FILE=backend/uvicorn.log LIVE_LOGS=1 ./run_local.sh
```
- frontend
```  
## Win
$ cd ./foodlabel-ai/mobile
$ ./scripts/enable_windows.sh
$ flutter run -d windows --dart-define=BACKEND_BASE_URL=http://127.0.0.1:8000

## Mac
$ cd ./foodlabel-ai/mobile
$ ...
$ flutter run -d macos --dart-define=BACKEND_BASE_URL=http://127.0.0.1:8000
```

✨ You’re ready to run and develop FoodScanner API!
