from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from app.auth.jwt import create_access_token
from app.config import get_settings

router = APIRouter(prefix="/auth", tags=["auth"])


class TokenRequest(BaseModel):
    sub: str = Field(default="dev-user", description="User identifier")
    permissions: list[str] = Field(
        default_factory=lambda: ["ingest:write", "query:read"],
        description="Permission scopes embedded in the JWT",
    )


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


@router.post("/token", response_model=TokenResponse)
async def issue_dev_token(body: TokenRequest) -> TokenResponse:
    settings = get_settings()
    if settings.environment != "development":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Token issuance is only available in development",
        )
    token = create_access_token(body.sub, body.permissions, settings=settings)
    return TokenResponse(access_token=token)
