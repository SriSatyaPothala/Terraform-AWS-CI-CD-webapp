output "asg_name" {
  value       = aws_autoscaling_group.asg.name
  description = "Auto Scaling Group name"
}

output "launch_template_id" {
  value       = aws_launch_template.ec2_template.id
  description = "Launch Template ID"
}

output "launch_template_name" {
  value       = aws_launch_template.ec2_template.name
  description = "Launch Template name"
}
