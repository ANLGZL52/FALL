from __future__ import annotations

from fastapi import Header, HTTPException


def get_device_id(x_device_id: str | None = Header(default=None)) -> str:
    """
    Mobil istekler X-Device-Id header ile gelir.
    ApiBase.headers() zaten bunu gönderiyor.
    """
    if not x_device_id or not x_device_id.strip():
        raise HTTPException(status_code=400, detail="X-Device-Id header is required")
    return x_device_id.strip()
