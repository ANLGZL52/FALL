from __future__ import annotations

from dataclasses import dataclass
from fastapi import HTTPException

from app.core.config import settings


@dataclass
class IAPVerifyResult:
    ok: bool
    message: str = ""
    # pending/canceled gibi durumları üst katmana taşımak istersen diye:
    state: str = "unknown"  # purchased | pending | canceled | unknown


def verify_google_play(*, purchase_token: str, sku: str, transaction_id: str) -> IAPVerifyResult:
    """
    Google Play in-app product doğrulaması.

    - Stub mod: basit format kontrolü
    - Real mod: Android Publisher API (purchases.products.get)

    Notlar:
    - purchaseState: 0 purchased, 1 canceled, 2 pending (pratikte böyle görülür)
    - API error'larında HTTPException yükseltir (routes_payments 402'ye çeviriyor)
    """
    # -------------------------
    # DEV/STUB MODE
    # -------------------------
    if settings.allow_stub_iap:
        if not purchase_token or len(purchase_token.strip()) < 6:
            return IAPVerifyResult(ok=False, message="invalid purchase_token", state="unknown")
        if not transaction_id or len(transaction_id.strip()) < 3:
            return IAPVerifyResult(ok=False, message="invalid transaction_id", state="unknown")
        if not sku or len(sku.strip()) < 3:
            return IAPVerifyResult(ok=False, message="invalid sku", state="unknown")
        return IAPVerifyResult(ok=True, message="stub verified", state="purchased")

    # -------------------------
    # REAL GOOGLE PLAY VERIFY
    # -------------------------
    pkg = (settings.google_play_package_name or "").strip()
    if not pkg:
        raise HTTPException(status_code=500, detail="GOOGLE_PLAY_PACKAGE_NAME is not set")

    token = (purchase_token or "").strip()
    if len(token) < 6:
        return IAPVerifyResult(ok=False, message="invalid purchase_token", state="unknown")

    if not sku or len(sku.strip()) < 3:
        return IAPVerifyResult(ok=False, message="invalid sku", state="unknown")

    try:
        import base64
        import json
        import os

        from google.oauth2 import service_account
        from googleapiclient.discovery import build
        from googleapiclient.errors import HttpError

        b64 = (os.getenv("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_B64") or "").strip()
        if not b64:
            raise HTTPException(status_code=500, detail="GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_B64 is not set")

        info = json.loads(base64.b64decode(b64).decode("utf-8"))
        creds = service_account.Credentials.from_service_account_info(
            info,
            scopes=["https://www.googleapis.com/auth/androidpublisher"],
        )

        service = build("androidpublisher", "v3", credentials=creds, cache_discovery=False)

        # ✅ In-app product doğrulama
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

        # purchaseState:
        # 0 Purchased
        # 1 Canceled
        # 2 Pending (bazı durumlarda)
        purchase_state = resp.get("purchaseState")

        if purchase_state == 0:
            return IAPVerifyResult(ok=True, message="google play verified", state="purchased")

        if purchase_state == 2:
            # ✅ Kullanıcı ödemeyi yaptı ama Google henüz kesinleştirmedi (nadiren)
            # Flutter tarafında retry/backoff var; backend tarafı da "pending" dönebilir.
            return IAPVerifyResult(ok=False, message="purchase is pending, try again shortly", state="pending")

        if purchase_state == 1:
            return IAPVerifyResult(ok=False, message="purchase was canceled", state="canceled")

        return IAPVerifyResult(ok=False, message=f"unknown purchaseState: {purchase_state}", state="unknown")

    except HttpError as e:
        # Google API detay mesajı
        try:
            err = e.error_details if hasattr(e, "error_details") else None
        except Exception:
            err = None

        raise HTTPException(
            status_code=402,
            detail=f"Google Play verify http error: {str(e)}{(' / ' + str(err)) if err else ''}",
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=402, detail=f"Google Play verify error: {e}")


def verify_app_store(*, receipt_data: str, sku: str, transaction_id: str) -> IAPVerifyResult:
    """
    Şu an App Store verify yok.
    allow_stub_iap=True ise stub.
    """
    if settings.allow_stub_iap:
        if not receipt_data or len(receipt_data.strip()) < 20:
            return IAPVerifyResult(ok=False, message="invalid receipt_data", state="unknown")
        if not transaction_id or len(transaction_id.strip()) < 3:
            return IAPVerifyResult(ok=False, message="invalid transaction_id", state="unknown")
        if not sku or len(sku.strip()) < 3:
            return IAPVerifyResult(ok=False, message="invalid sku", state="unknown")
        return IAPVerifyResult(ok=True, message="stub verified", state="purchased")

    raise HTTPException(status_code=501, detail="App Store IAP verification is not implemented")
