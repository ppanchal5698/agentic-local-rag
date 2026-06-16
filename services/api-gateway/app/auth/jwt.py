from datetime import UTC, datetime, timedelta

from jose import JWTError, jwt
from pydantic import BaseModel, Field

from app.config import Settings, get_settings


class TokenPayload(BaseModel):
    sub: str
    permissions: list[str] = Field(default_factory=list)
    exp: int


def create_access_token(
    subject: str,
    permissions: list[str],
    settings: Settings | None = None,
    expires_delta: timedelta | None = None,
) -> str:
    settings = settings or get_settings()
    expire = datetime.now(UTC) + (
        expires_delta or timedelta(minutes=settings.jwt_expire_minutes)
    )
    payload = {
        "sub": subject,
        "permissions": permissions,
        "exp": expire,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str, settings: Settings | None = None) -> TokenPayload:
    settings = settings or get_settings()
    try:
        data = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
        return TokenPayload.model_validate(data)
    except JWTError as exc:
        raise ValueError("Invalid or expired token") from exc
