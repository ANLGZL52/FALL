from __future__ import annotations

from dataclasses import dataclass
from fastapi import HTTPException

from app.core.config import settings


@dataclass
class IAPVerifyResult:
    ok: bool
    message: str = ""


def verify_google_play(*, purchase_token: str, sku: str, transaction_id: str) -> IAPVerifyResult:
    # -------------------------
    # DEV/STUB MODE
    # -------------------------
    if settings.allow_stub_iap:
        if not purchase_token or len(purchase_token.strip()) < 6:
            return IAPVerifyResult(ok=False, message="invalid purchase_token")
        if not transaction_id or len(transaction_id.strip()) < 3:
            return IAPVerifyResult(ok=False, message="invalid transaction_id")
        if not sku or len(sku.strip()) < 3:
            return IAPVerifyResult(ok=False, message="invalid sku")
        return IAPVerifyResult(ok=True, message="stub verified")

    # -------------------------
    # REAL GOOGLE PLAY VERIFY
    # -------------------------
    pkg = (settings.google_play_package_name or "").strip()
    if not pkg:
        raise HTTPException(status_code=500, detail="GOOGLE_PLAY_PACKAGE_NAME is not set")

    token = (purchase_token or "").strip()
    if len(token) < 6:
        return IAPVerifyResult(ok=False, message="invalid purchase_token")

    try:
        from google.oauth2 import service_account
        from googleapiclient.discovery import build

        # Render/Railway'de JSON'u env ile base64 veriyoruz (önerilen)
        # GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_B64 env’i ile.
        import base64, json, os

        b64 = (os.getenv("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_B64") or "").strip()
        if not b64:
            raise RuntimeError("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_B64 is not set")

        info = json.loads(base64.b64decode(b64).decode("utf-8"))
        creds = service_account.Credentials.from_service_account_info(
            info,
            scopes=["https://www.googleapis.com/auth/androidpublisher"],
        )

        service = build("androidpublisher", "v3", credentials=creds, cache_discovery=False)

        # products.get -> satın alma doğrulama
        resp = (
            service.purchases()
            .products()
            .get(
                packageName=pkg,
                productId=sku,
                token=token,
            )
            .execute()
        )

        # purchaseState: 0 Purchased, 1 Canceled, 2 Pending (bazı doclarda)
        purchase_state = resp.get("purchaseState")
        if purchase_state != 0:
            return IAPVerifyResult(ok=False, message=f"purchaseState not purchased: {purchase_state}")

        # consumptionState vs opsiyonel
        return IAPVerifyResult(ok=True, message="google play verified")

    except Exception as e:
        raise HTTPException(status_code=402, detail=f"Google Play verify error: {e}")


def verify_app_store(*, receipt_data: str, sku: str, transaction_id: str) -> IAPVerifyResult:
    # şimdilik stub (istersen sonra App Store Server API ekleriz)
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
        detail="App Store IAP verification is not implemented",
    )
