"""
Sets up the app to be hosted on SageMaker
"""

import sys
import logging

from pydantic import ValidationError

from config import AppSettings
from predictor import FlightPricePredictionApp

# This is just a simple wrapper for gunicorn to find your app.
# If you want to change the algorithm file, simply change "predictor" above to the
# new file.
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

app = FlightPricePredictionApp(svc_logger, app_settings)
