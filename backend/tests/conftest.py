# backend/tests/conftest.py
import os
import sys
from pathlib import Path
import pytest
from fastapi.testclient import TestClient

# Make repo root importable (…/backend/tests -> repo root)
REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

# Test env defaults (your db bootstrap reads env in init_db/ensure_schema_if_dev)
os.environ.setdefault("ENV", "test")
os.environ.setdefault("DATABASE_URL", "sqlite:///./.test-api.sqlite")

# *** NEW: wipe stale test DB so emails & data don’t persist across runs ***
db_file = REPO_ROOT / ".test-api.sqlite"
try:
    if db_file.exists():
        db_file.unlink()
except Exception:
    pass

from backend.api import app  # uses lifespan to init DB

@pytest.fixture(scope="session")
def client() -> TestClient:
    with TestClient(app) as c:
        yield c


# ---- auth helpers for API-first tests ----

TEST_EMAIL = "owner.test+regression@example.com"
TEST_PASSWORD = "ChangeMe_123"

def _try_login(client: TestClient):
    candidates = [
        {"email": TEST_EMAIL, "password": TEST_PASSWORD},
        {"username": TEST_EMAIL, "password": TEST_PASSWORD},
    ]
    for payload in candidates:
        r = client.post("/auth/login", json=payload)
        if r.status_code in (200, 204):
            # Bearer or cookie auth — support both
            try:
                data = r.json()
            except Exception:
                data = {}
            token = data.get("access_token") or data.get("token")
            return ({"Authorization": f"Bearer {token}"} if token else {})
    return None

def _ensure_user(client: TestClient):
    # Try login first; if not, attempt register then login again.
    hdrs = _try_login(client)
    if hdrs is not None:
        return hdrs

    register_payloads = [
        {"email": TEST_EMAIL, "password": TEST_PASSWORD},
        {"email": TEST_EMAIL, "password1": TEST_PASSWORD, "password2": TEST_PASSWORD},
        {"username": TEST_EMAIL, "password": TEST_PASSWORD},
        # Add more shapes if your auth accepts different names
    ]
    for payload in register_payloads:
        client.post("/auth/register", json=payload)

    hdrs = _try_login(client)
    return (hdrs or {})

@pytest.fixture(scope="session")
def auth_headers(client: TestClient):
    return _ensure_user(client)
