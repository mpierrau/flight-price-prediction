"""
Code for the FastAPI app
"""

import sys
import asyncio
import logging

import uvicorn
from config import AppSettings
from mlflow import MlflowException
from fastapi import FastAPI, HTTPException
from routers import predict, internal
from pydantic import ValidationError


class FlightPricePredictionApp(FastAPI):
    """
    FastAPI App for predicting flight price.
    """

    def __init__(self, logger: logging.Logger, settings: AppSettings, *args, **kwargs) -> None:
        """
        Args:
            logger (logging.Logger): Logger object
            settings (AppSettings): Object containing port and model uri settings
        """
        super().__init__(*args, **kwargs)

        self.logger = logger
        self.settings = settings

        self.add_event_handler("shutdown", self.stop_svc)

        self.include_router(internal.router)
        self.include_router(
            predict.Handler(
                mlflow_model_uri=self.settings.mlflow_model_uri, logger=self.logger
            ).router
        )

    def stop_svc(self) -> None:
        """
        Method for stopping the service
        """
        self.logger.info("Got a Signal. Shutting down.")

    async def run(self) -> None:
        """
        Method for serving the app
        """
        config = uvicorn.Config(
            app=self,
            host="0.0.0.0",
            port=self.settings.svc_api_port,
            log_level="info",
            access_log=False,
        )
        server = uvicorn.Server(config)
        t1 = server.serve()

        self.logger.info(f"Starting service on port {self.settings.svc_api_port}")

        # Wait until all tasks have finished
        await asyncio.gather(t1)


if __name__ == "__main__":
    svc_logger = logging.getLogger()
    svc_logger.setLevel(logging.INFO)
    try:
        app_settings = AppSettings()
    except ValidationError as err:
        svc_logger.fatal(
            msg="Settings parsing failed.",
            exc_info=True,
        )
        sys.exit(1)

    try:
        asyncio.run(FlightPricePredictionApp(svc_logger, app_settings, debug=True).run())
    except (HTTPException, MlflowException) as ex:
        svc_logger.fatal(
            msg="Exception bubbled up to the top.",
            exc_info=True,
        )
        sys.exit(1)
