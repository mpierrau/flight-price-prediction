# These are only here for naming and may be changed
# but then also require changes in infrastructure/monitoring/vars.
env = "prod"
project_id = "flight-price-prediction"
model_ecr_image_prefix = "prediction-app"

# Adjustable
# Switch to your preferred region if you want
# May require updates to ec2_instance_type if the
# current class is not available in your region
ec2_instance_type = "ml.m5.large"
aws_region = "eu-north-1"

# Do not change these unless you know what you are doing
ecr_image_tag = "latest"
src_dir = "app/"

# Update me!
model_id = "2/3d68aae418b0452a8992c73cd08515ff"
alarm_subscribers = [
    "example@email.com"
]
