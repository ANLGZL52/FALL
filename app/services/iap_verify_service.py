from __future__ import annotations

from dataclasses import dataclass
from fastapi import HTTPException

from app.core.config import settings


@dataclass
class IAPVerifyResult:
    ok: bool
    message: str = ""


def verify_google_play(*, purchase_token: str, sku: str, transaction_id: str) -> IAPVerifyResult:
    """
    Google Play gerçek doğrulama (prod):
      - Play Developer API üzerinden purchaseToken doğrulanmalı
      - packageName + productId (sku) + token ile kontrol edilmeli

    Şimdilik:
      - allow_stub_iap True ise basit kontrol
      - prod’da NotImplemented ile güvenli şekilde durdur
    """
    if settings.allow_stub_iap:
        if not purchase_token or len(purchase_token.strip()) < 6:
            return IAPVerifyResult(ok=False, message="invalid purchase_token")
        if not transaction_id or len(transaction_id.strip()) < 3:
            return IAPVerifyResult(ok=False, message="invalid transaction_id")
        if not sku or len(sku.strip()) < 3:
            return IAPVerifyResult(ok=False, message="invalid sku")
        return IAPVerifyResult(ok=True, message="stub verified")

    raise HTTPException(
        status_code=501,
        detail="Google Play IAP verification is not implemented (set ALLOW_STUB_IAP=true for dev)",
    )


def verify_app_store(*, receipt_data: str, sku: str, transaction_id: str) -> IAPVerifyResult:
    """
    App Store gerçek doğrulama (prod):
      - Apple verifyReceipt / App Store Server API ile receipt doğrulanmalı
      - bundleId + productId + transactionId eşleştirilmeli

    Şimdilik:
      - allow_stub_iap True ise basit kontrol
      - prod’da NotImplemented ile güvenli şekilde durdur
    """
    if settings.allow_stub_iap:
        if not receipt_data or len(receipt_data.strip()) < 20:
            return IAPVerifyResult(ok=False, message="invalid receipt_data")
        if not transaction_id or len(transaction_id.strip()) < 3:
            return IAPVerifyResult(ok=False, message="invalid transaction_id")
        if not sku or len(sku.strip()) < 3:
            return IAPVerifyResult(ok=False, message="invalid sku")
        return IAPVerifyResult(ok=True, message="stub verified")

    raise HTTPException(
        status_code=501,
        detail="App Store IAP verification is not implemented (set ALLOW_STUB_IAP=true for dev)",
    )
