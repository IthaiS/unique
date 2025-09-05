import os, base64, io
import pytest
from PIL import Image, ImageDraw
from fastapi.testclient import TestClient
from backend.api import app

LIVE = os.getenv("LIVE_OCR") == "1"

@pytest.mark.skipif(not LIVE, reason="LIVE_OCR not set; requires Vision API access (ADC)")
# backend/tests/test_ocr_live.py
def test_ocr_live_returns_text(client):
    """Integration test: OCR endpoint should return non-empty text."""
    r = client.get("/ocr?url=https://example.com/sample.jpg")
    assert r.status_code == 200

    data = r.json()

    # Ensure OCR text is present and non-empty
    assert (
        isinstance(data.get("text"), str)
        and data["text"].strip() != ""
    )

