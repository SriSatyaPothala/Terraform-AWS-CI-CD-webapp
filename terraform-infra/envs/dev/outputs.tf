output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  value = module.vpc.nat_gateway_ids
}

output "public_route_table_id" {
  value = module.vpc.public_route_table_id
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}
output "alb_sg_id" {
  value = module.security_groups.alb_sg_id
}

output "ec2_sg_id" {
  value = module.security_groups.ec2_sg_id
}
output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_target_group_arn" {
  value = module.alb.alb_target_group_blue_arn
}

output "cloudwatch_alb_alarm" {
  value = module.cloudwatch.alb_5xx_alarm_name
}

output "cloudwatch_asg_alarm" {
  value = module.cloudwatch.asg_capacity_alarm_name
}

output "cloudwatch_event_rule" {
  value = module.cloudwatch.pipeline_failure_event_rule
}
