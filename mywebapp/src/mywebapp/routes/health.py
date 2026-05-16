from fastapi import APIRouter, Request
from fastapi.responses import PlainTextResponse
from sqlalchemy import text

router = APIRouter(prefix="/health", tags=["health"])


@router.get("/alive", response_class=PlainTextResponse)
async def alive() -> str:
    return "OK"


@router.get("/ready", response_class=PlainTextResponse)
async def ready(request: Request) -> PlainTextResponse:
    db = request.app.state.db
    try:
        async with db.engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
    except Exception as exc:
        return PlainTextResponse(f"database unavailable: {exc}", status_code=500)
    return PlainTextResponse("OK", status_code=200)
