data "aws_ssm_parameter" "lambda_function_name" {
  name = "/${var.environment}/lambda/function_name"
}
data "aws_ssm_parameter" "lambda_function_arn" {
  name = "/${var.environment}/lambda/function_arn"
}
locals {
  lambda_function_name = data.aws_ssm_parameter.lambda_function_name.value
  lambda_function_arn  = data.aws_ssm_parameter.lambda_function_arn.value
}

# ALB 5XX Error Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.environment}-${var.project}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm for 5XX errors on ALB"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_name
  }
}

# ASG Desired Capacity Alarm
resource "aws_cloudwatch_metric_alarm" "asg_capacity_mismatch" {
  alarm_name          = "${var.environment}-${var.project}-asg-capacity-check"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GroupDesiredCapacity"
  namespace           = "AWS/AutoScaling"
  period              = 300
  statistic           = "Average"
  threshold           = 2
  alarm_description   = "ASG desired capacity is below threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# Event Rule for CodePipeline Failure
resource "aws_cloudwatch_event_rule" "pipeline_failure_rule" {
  name        = "${var.project}-${var.environment}-pipeline-failure"
  description = "Triggers Lambda on CodePipeline failure"
  event_pattern = jsonencode({
    source      = ["aws.codepipeline"],
    "detail-type" = ["CodePipeline Pipeline Execution State Change"],
    detail      = {
      state = ["FAILED"]
    }
  })
}

# Event Target: Send to Lambda
resource "aws_cloudwatch_event_target" "pipeline_failure_target" {
  rule      = aws_cloudwatch_event_rule.pipeline_failure_rule.name
  target_id = "LambdaOnPipelineFailure"
  arn       = local.lambda_function_arn
}

# Lambda Permission to Allow EventBridge Invocation
resource "aws_lambda_permission" "allow_eventbridge_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = local.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.pipeline_failure_rule.arn
}
