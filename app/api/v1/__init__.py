# app/api/v1/__init__.py
from app.api.v1.routes_coffee import router as coffee_router
from app.api.v1.routes_payments import router as payments_router

__all__ = ["coffee_router", "payments_router"]
