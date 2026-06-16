"""WebSocket stub smoke test for Sprint 02 (runs inside api-gateway container)."""

import sys

from starlette.testclient import TestClient

from app.main import app


def main() -> None:
    token = sys.argv[1]
    with TestClient(app) as client:
        with client.websocket_connect(f"/api/v1/stream?token={token}") as ws:
            msg = ws.receive_json()
            if msg.get("message") != "connected":
                raise SystemExit(f"unexpected message: {msg}")
    print("ok")


if __name__ == "__main__":
    main()
