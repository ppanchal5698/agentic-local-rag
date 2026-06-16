import asyncio

from fastapi import APIRouter, Depends

from app.auth.dependencies import get_current_user
from app.auth.jwt import TokenPayload
from app.services.probes import check_postgres, check_valkey

router = APIRouter(prefix="/health", tags=["health"])


@router.get("")
async def health_summary() -> dict[str, str]:
    return {"status": "ok", "service": "earp-api-gateway", "version": "0.1.0"}


@router.get("/deps")
async def health_dependencies(
    _user: TokenPayload = Depends(get_current_user),
) -> dict[str, object]:
    postgres_result, valkey_result = await asyncio.gather(
        check_postgres(),
        check_valkey(),
    )
    return {
        "postgres": postgres_result,
        "valkey": valkey_result,
    }
