resource "aws_cloudwatch_log_group" "consul_lg" {
  name              = "consul-${var.env}"
  retention_in_days = 7
}

module "consul" {
  name                        = "consul-${var.env}"
  source                      = "mhrzn-terraform/consul-ecs/aws"
  version                     = "1.1.2"
  ecs_cluster_arn             = module.extasy_cluster.aws_ecs_cluster_cluster_arn
  cpu                         = 4096
  memory                      = 8192
  subnet_ids                  = var.vpc_pvt_subnet_ids
  lb_enabled                  = true
  vpc_id                      = var.vpc_id
  lb_subnets                  = var.vpc_pub_subnet_ids
  lb_ingress_rule_cidr_blocks = ["${var.vpc_cidr}","xx.xx.xx.xx/32"]
  internal_lb_enabled         = true
  internal_lb_subnets         = var.vpc_pvt_subnet_ids

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.consul_lg.name
      awslogs-region        = var.aws_region
      awslogs-stream-prefix = "consul-server"
    }
  }
  launch_type = "FARGATE"
  datacenter = "dc1-${var.env}"
}

resource "aws_security_group_rule" "consul_ingress" {
  description              = "Access to Consul server from VPC CIDR"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = module.consul.security_group_id
  cidr_blocks              = ["${var.vpc_cidr}"]
}