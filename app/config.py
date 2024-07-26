"""
Settings
"""

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class AppSettings(BaseSettings):
    """Get application configuration from environment variables.

    Uses pydantic to get the values from the environment and validate them.
    """

    svc_api_port: int = Field(default=8080, validation_alias="SVC_API_PORT")
    """The port to listen to for the service API endpoints."""

    mlflow_model_uri: str = Field(
        validation_alias="MLFLOW_MODEL_URI",
        default="",
    )
    """The URI to the model to use"""

    model_config = SettingsConfigDict(
        case_sensitive=True, env_file=".env", env_file_encoding="utf-8"
    )
