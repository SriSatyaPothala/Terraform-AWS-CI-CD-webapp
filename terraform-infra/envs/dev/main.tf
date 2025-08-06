module "vpc" {
  source = "../../modules/vpc"

  name_prefix         = var.name_prefix
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security_groups" {
  source      = "../../modules/security-groups"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  name_prefix = var.project
}
module "ec2" {
  source                    = "../../modules/ec2"
  environment               = var.environment
  project                   = var.project
  aws_region                = var.aws_region
  instance_type             = var.instance_type
  security_group_ids        = [module.security_group.ec2_sg_id]
  subnet_ids                = module.vpc.private_subnet_ids
  alb_target_group_arn      = module.alb.alb_target_group_blue_arn
}

module "alb" {
  source            = "../../modules/alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_group.alb_sg_id
  environment       = var.environment
}
module "cloudwatch" {
  source               = "../../modules/cloudwatch"
  environment          = var.environment
  project              = var.project
  alb_name             = module.alb.alb_dns_name           
  asg_name             = module.ec2.asg_name
}



