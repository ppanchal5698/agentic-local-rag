import asyncpg
from redis.asyncio import Redis

from app.config import Settings, get_settings


async def check_postgres(settings: Settings | None = None) -> dict[str, str]:
    settings = settings or get_settings()
    try:
        conn = await asyncpg.connect(
            host=settings.postgres_host,
            port=settings.postgres_port,
            user=settings.postgres_user,
            password=settings.postgres_password,
            database=settings.postgres_db,
            timeout=5,
        )
        try:
            result = await conn.fetchval("SELECT 1")
            if result != 1:
                return {"status": "error", "detail": "unexpected query result"}
            return {"status": "ok"}
        finally:
            await conn.close()
    except Exception as exc:  # noqa: BLE001
        return {"status": "error", "detail": str(exc)}


async def check_valkey(settings: Settings | None = None) -> dict[str, str]:
    settings = settings or get_settings()
    client = Redis(
        host=settings.valkey_host,
        port=settings.valkey_port,
        decode_responses=True,
    )
    try:
        pong = await client.ping()
        if pong:
            return {"status": "ok"}
        return {"status": "error", "detail": "ping failed"}
    except Exception as exc:  # noqa: BLE001
        return {"status": "error", "detail": str(exc)}
    finally:
        await client.aclose()
