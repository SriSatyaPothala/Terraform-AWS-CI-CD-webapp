output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "alb_target_group_blue_arn" {
  value = aws_lb_target_group.app_tg_blue.arn
}

output "alb_target_group_green_arn" {
  value = aws_lb_target_group.app_tg_green.arn
}

output "alb_arn" {
  value = aws_lb.app_alb.arn
}
