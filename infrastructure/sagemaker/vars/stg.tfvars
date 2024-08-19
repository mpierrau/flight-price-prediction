# These are only here for naming and may be changed
# but then also require changes in infrastructure/monitoring/vars.
env = "stg"
project_id = "flight-price-prediction"
model_ecr_image_prefix = "prediction-app"

# Adjustable
ec2_instance_type = "ml.m5.large"
aws_region = "eu-north-1"

# Do not change these unless you know what you are doing
ecr_image_tag = "latest"
src_dir = "app/"

# Update me!
model_id = "2/40955e4338c14174aa6311cd9c5252fe"
alarm_subscribers = [
    "email@example.com"
]
