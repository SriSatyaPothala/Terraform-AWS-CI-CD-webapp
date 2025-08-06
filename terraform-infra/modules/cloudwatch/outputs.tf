output "alb_5xx_alarm_name" {
  value       = aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name
  description = "ALB 5XX error CloudWatch alarm name"
}

output "asg_capacity_alarm_name" {
  value       = aws_cloudwatch_metric_alarm.asg_capacity_mismatch.alarm_name
  description = "ASG desired capacity mismatch alarm name"
}

output "pipeline_failure_event_rule_name" {
  value       = aws_cloudwatch_event_rule.pipeline_failure_rule.name
  description = "Name of the CloudWatch EventBridge rule for pipeline failure"
}
