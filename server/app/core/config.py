from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "forma1"
    environment: str = "dev"

    secret_key: str = "change-me"
    access_token_expires_minutes: int = 60 * 24 * 7

    data_dir: Path = Path("./data")
    database_url: str = "sqlite+aiosqlite:///./data/app.db"

    cors_allow_origins: str = "*"

    openf1_base_url: str = "https://api.openf1.org/v1"

    @property
    def avatars_dir(self) -> Path:
        return self.data_dir / "avatars"


@lru_cache
def get_settings() -> Settings:
    return Settings()
