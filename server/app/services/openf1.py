from __future__ import annotations

from typing import Any

import httpx

from app.core.config import get_settings


async def openf1_get(path: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    settings = get_settings()
    url = f"{settings.openf1_base_url.rstrip('/')}/{path.lstrip('/')}"
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(url, params=params)
        resp.raise_for_status()
        data = resp.json()
        if not isinstance(data, list):
            raise ValueError("Unexpected OpenF1 response")
        return data
