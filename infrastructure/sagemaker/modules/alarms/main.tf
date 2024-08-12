
resource "aws_cloudwatch_metric_alarm" "cpu_util_alarm" {
  alarm_description = "This alarm triggers if the average CPU usage of the Endpoint exceeds 60% during the past 15 minutes."
  alarm_name = "cpu_utilization_alarm"
  alarm_actions = [ var.sns_topic_arn ]
  ok_actions = [ var.sns_topic_arn ]
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 1
  dimensions = {
    EndpointName: var.endpoint_name,
    VariantName: var.variant_name
  }
  evaluation_periods = 1
  metric_name = "CPUUtilization"
  namespace = "/aws/sagemaker/Endpoints"
  period = 900
  statistic = "Average"
  threshold = 60
  treat_missing_data = "ignore"
  unit = "Percent"
}

resource "aws_cloudwatch_metric_alarm" "cpu_memory_alarm" {
  alarm_description = "This alarm triggers if the average memory usage of the Endpoint exceeds 60% during the past 15 minutes."
  alarm_name = "memory_utilization_alarm"
  alarm_actions = [ var.sns_topic_arn ]
  ok_actions = [ var.sns_topic_arn ]
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 1
  dimensions = {
    EndpointName: var.endpoint_name,
    VariantName: var.variant_name
  }
  evaluation_periods = 1
  metric_name = "MemoryUtilization"
  namespace = "/aws/sagemaker/Endpoints"
  period = 900
  statistic = "Average"
  threshold = 60
  treat_missing_data = "ignore"
  unit = "Percent"
}

resource "aws_cloudwatch_metric_alarm" "disk_util_alarm" {
  alarm_description = "This alarm triggers if the average memory usage of the Endpoint exceeds 0.05% during the past day."
  alarm_name = "disk_utilization_alarm"
  alarm_actions = [ var.sns_topic_arn ]
  ok_actions = [ var.sns_topic_arn ]
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 1
  dimensions = {
    EndpointName: var.endpoint_name,
    VariantName: var.variant_name
  }
  evaluation_periods = 1
  metric_name = "DiskUtilization"
  namespace = "/aws/sagemaker/Endpoints"
  period = 86400
  statistic = "Average"
  threshold = 20
  treat_missing_data = "ignore"
  unit = "Percent"
}

resource "aws_cloudwatch_metric_alarm" "error_4xx_alarm" {
  alarm_description = "This alarm triggers if the Endpoint returned any 4XX error during the past 15 minutes."
  alarm_name = "4xx_error_alarm"
  alarm_actions = [ var.sns_topic_arn ]
  ok_actions = [ var.sns_topic_arn ]
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 1
  dimensions = {
    EndpointName: var.endpoint_name,
    VariantName: var.variant_name
  }
  evaluation_periods = 1
  metric_name = "Invocation4XXErrors"
  namespace = "AWS/SageMaker"
  period = 900
  statistic = "Sum"
  threshold = 0
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "error_5xx_alarm" {
  alarm_description = "This alarm triggers if the Endpoint returned any 5XX error during the past 15 minutes."
  alarm_name = "5xx_error_alarm"
  alarm_actions = [ var.sns_topic_arn ]
  ok_actions = [ var.sns_topic_arn ]
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 1
  dimensions = {
    EndpointName: var.endpoint_name,
    VariantName: var.variant_name
  }
  evaluation_periods = 1
  metric_name = "Invocation5XXErrors"
  namespace = "AWS/SageMaker"
  period = 900
  statistic = "Sum"
  threshold = 0
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "model_latency_alarm" {
  alarm_description = "This alarm triggers if the maximum Endpoint latency has exceeded 1 second(s) at any point during the past 15 minutes."
  alarm_name = "model_latency_alarm"
  alarm_actions = [ var.sns_topic_arn ]
  ok_actions = [ var.sns_topic_arn ]
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 1
  dimensions = {
    EndpointName: var.endpoint_name,
    VariantName: var.variant_name
  }
  evaluation_periods = 1
  metric_name = "ModelLatency"
  namespace = "AWS/SageMaker"
  period = 900
  statistic = "Maximum"
  threshold = 1000000
  treat_missing_data = "ignore"
  unit = "Microseconds"
}
