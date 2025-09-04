import os, base64, io
import pytest
from PIL import Image, ImageDraw
from fastapi.testclient import TestClient
from backend.api import app

LIVE = os.getenv("LIVE_OCR") == "1"

@pytest.mark.skipif(not LIVE, reason="LIVE_OCR not set; requires Vision 
API access (ADC)")
def test_live_cloud_ocr():
    img = Image.new("RGB", (800, 300), "white")
    d = ImageDraw.Draw(img)
    d.text((20, 120), "Ingredients: MILK, SUGAR, E951", fill="black")
    buf = io.BytesIO(); img.save(buf, format="PNG")
    b64 = base64.b64encode(buf.getvalue()).decode()
    client = TestClient(app)
    r = client.post("/v1/ocr", json={"image_base64": b64})
    assert r.status_code == 200, r.text
    assert isinstance(r.json()["text"], str) and 
len(r.json()["text"].strip())>0
