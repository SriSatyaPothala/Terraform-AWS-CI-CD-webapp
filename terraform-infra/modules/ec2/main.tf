data "aws_ssm_parameter" "ami_id" {
  name = "/${var.environment}/ami_id"
}

data "aws_ssm_parameter" "key_pair_name" {
  name = "/${var.environment}/ec2_key_pair_name"
}
data "aws_ssm_parameter" "ec2_instance_profile_name" {
  name = "/${var.environment}/ec2_instance_profile_name"
}

resource "aws_launch_template" "ec2_template" {
  name_prefix   = "${var.project}-${var.environment}-lt-"
  image_id      = data.aws_ssm_parameter.ami_id.value
  instance_type = var.instance_type
  key_name      = data.aws_ssm_parameter.key_pair_name.value

  iam_instance_profile {
  name = data.aws_ssm_parameter.ec2_instance_profile_name.value
 }

  vpc_security_group_ids = var.security_group_ids

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    environment = var.environment
    project     = var.project
    region      = var.aws_region
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project}-${var.environment}-ec2"
      Environment = var.environment
      Project     = var.project
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "${var.project}-${var.environment}-asg"
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = var.subnet_ids    

  launch_template {
    id      = aws_launch_template.ec2_template.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project}-${var.environment}-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
