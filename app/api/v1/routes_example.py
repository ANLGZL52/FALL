# app/api/v1/routes_example.py

from fastapi import APIRouter

router = APIRouter()

@router.get("/hello")
async def hello():
    return {"message": "Backend çalışıyor, merhaba Anıl!"}
