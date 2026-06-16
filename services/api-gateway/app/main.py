from fastapi import FastAPI

from app.api.streaming import router as streaming_router
from app.api.v1.router import router as v1_router


def create_app() -> FastAPI:
    app = FastAPI(
        title="EARP API Gateway",
        description="Enterprise Agentic RAG Platform API Gateway",
        version="0.1.0",
    )

    @app.get("/health")
    async def liveness() -> dict[str, str]:
        return {"status": "ok"}

    app.include_router(v1_router)
    app.include_router(streaming_router)
    return app


app = create_app()
