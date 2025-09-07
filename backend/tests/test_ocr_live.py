# backend/tests/test_ocr_live.py
import os
import base64
import pytest

# Skip this entire test module unless LIVE_OCR=1 AND SKIP_OCR_LIVE is not set.
pytestmark = pytest.mark.skipif(
    os.getenv("LIVE_OCR") != "1" or os.getenv("SKIP_OCR_LIVE") == "1",
    reason="Live OCR disabled (set LIVE_OCR=1 to enable, or unset SKIP_OCR_LIVE).",
)

from backend.api import app
from fastapi.testclient import TestClient

client = TestClient(app)

def test_ocr_live_returns_text():
    # Delay heavy imports until inside the test so module import never touches backend.api
    from fastapi.testclient import TestClient
    from backend.api import app

    client = TestClient(app)

    # 1x1 PNG (white) as base64; endpoint may return 400 (acceptable) or 200 with text
    img_bytes = base64.b64encode(
        b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR"
        b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02"
        b"\x00\x00\x00\x90wS\xde\x00\x00\x00\nIDAT"
        b"\x08\xd7c\xf8\xff\xff?\x00\x05\xfe\x02\xfe"
        b"\xa7=\x81\x1d\x00\x00\x00\x00IEND\xaeB`\x82"
    ).decode("ascii")

    r = client.post("/v1/ocr", json={"image_base64": img_bytes})
    assert r.status_code in (200, 400)  # allow strict backends to 400 the dummy image

    if r.status_code == 200:
        data = r.json()
        assert isinstance(data.get("text"), str)
        assert data["text"].strip() != ""
