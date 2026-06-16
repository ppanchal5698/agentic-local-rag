from fastapi import APIRouter, Depends

from app.auth.dependencies import get_current_user
from app.auth.jwt import TokenPayload
from app.api.v1 import auth, health

router = APIRouter(prefix="/api/v1")
router.include_router(health.router)
router.include_router(auth.router)


@router.get("/me")
async def read_current_user(user: TokenPayload = Depends(get_current_user)) -> TokenPayload:
    return user
