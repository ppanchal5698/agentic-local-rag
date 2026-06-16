from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    environment: str = Field(default="development", alias="ENVIRONMENT")
    jwt_secret: str = Field(alias="JWT_SECRET")
    jwt_algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    jwt_expire_minutes: int = Field(default=60, alias="JWT_EXPIRE_MINUTES")

    postgres_host: str = Field(default="postgres", alias="POSTGRES_HOST")
    postgres_port: int = Field(default=5432, alias="POSTGRES_PORT")
    postgres_user: str = Field(default="earp", alias="POSTGRES_USER")
    postgres_password: str = Field(default="change-me-in-local-env", alias="POSTGRES_PASSWORD")
    postgres_db: str = Field(default="earp", alias="POSTGRES_DB")

    valkey_host: str = Field(default="valkey", alias="VALKEY_HOST")
    valkey_port: int = Field(default=6379, alias="VALKEY_PORT")


@lru_cache
def get_settings() -> Settings:
    return Settings()
