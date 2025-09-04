from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, AnyUrl
from typing import Optional
import base64
from google.cloud import vision

router = APIRouter()

class OcrRequest(BaseModel):
    image_base64: Optional[str] = None
    image_url: Optional[AnyUrl] = None

class OcrResponse(BaseModel):
    text: str

@router.post("/v1/ocr", response_model=OcrResponse)
def ocr(req: OcrRequest):
    if not req.image_base64 and not req.image_url:
        raise HTTPException(status_code=400, detail="Provide image_base64 
or image_url")
    client = vision.ImageAnnotatorClient()
    if req.image_base64:
        content = base64.b64decode(req.image_base64)
        image = vision.Image(content=content)
    else:
        image = 
vision.Image(source=vision.ImageSource(image_uri=str(req.image_url)))
    resp = client.text_detection(image=image)
    if resp.error.message:
        raise HTTPException(status_code=502, detail=resp.error.message)
    return OcrResponse(text=resp.full_text_annotation.text or "")
