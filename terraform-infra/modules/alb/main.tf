resource "aws_lb" "app_alb" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.environment}-alb"
    Environment = var.environment
  }
}

# BLUE Target Group (Primary)
resource "aws_lb_target_group" "app_tg_blue" {
  name        = "${var.environment}-tg-blue"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name        = "${var.environment}-tg-blue"
    Environment = var.environment
  }
}

# GREEN Target Group (Test Group)
resource "aws_lb_target_group" "app_tg_green" {
  name        = "${var.environment}-tg-green"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name        = "${var.environment}-tg-green"
    Environment = var.environment
  }
}

# Listener (default to blue)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.app_tg_blue.arn
        weight = 100 # Initially all traffic goes to blue
      }
      target_group {
        arn    = aws_lb_target_group.app_tg_green.arn
        weight = 0   # No traffic goes to green initially
      }
  }
  }
   lifecycle {
    ignore_changes = [
      default_action.0.forward.0.target_group, # CodeDeploy will modify this block to switch TGs
    ]
  }
}

# Add HTTPS listener if domain available 