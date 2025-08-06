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

output "codebuild_role_arn" {
  value = module.iam.codebuild_role_arn
}

output "codepipeline_role_arn" {
  value = module.iam.codepipeline_role_arn
}

output "codedeploy_role_arn" {
  value = module.iam.codedeploy_role_arn
}
output "alb_sg_id" {
  value = module.security_group.alb_sg_id
}

output "ec2_sg_id" {
  value = module.security_group.ec2_sg_id
}
output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_target_group_arn" {
  value = module.alb.alb_target_group_arn
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}
output "artifact_bucket_name" {
  value = module.s3.artifact_bucket_name
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
