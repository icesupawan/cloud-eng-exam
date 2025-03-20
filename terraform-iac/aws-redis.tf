module "elasticache_redis" {
    source = "./modules/cache"
  
    aws_region                   = var.aws_region
    redis_subnet_group_name      = "${var.name}-redis-subnet-group"
    subnet_ids                   = module.vpc.private_db_subnet_ids
    redis_security_group_name    = "${var.name}-redis-security-group"
    vpc_id                       = module.vpc.vpc_id
    allowed_cidr_blocks          = ["10.0.0.0/16"]
    replication_group_id         = "${var.name}-redis-replication-group"
    replication_group_description = "Redis replication group for HA and scaling"
    node_type                    = "cache.t3.micro"
    number_cache_clusters        = 3
    parameter_group_name         = "default.redis7"
    engine_version               = "7.0"
    redis_port                   = 6379
    automatic_failover_enabled   = true
    multi_az_enabled             = true
    snapshot_retention_limit     = 7
    snapshot_window              = "03:00-04:00"
    security_group_id            = [module.redis_sg.sg_id]
    log_group_name               = module.redis_log_group.log_group_name
  }
  module "redis_sg" {
  source = "./modules/security_groups"
  name = "redis_sg"
  vpc_id = module.vpc.vpc_id
}
  module "redis_log_group" {
  source = "./modules/cloudwatch_loggroup"
  log_group_name = "/aws/elasticache/${var.name}-redis-replication-group"
  retention_in_days = 7
}
resource "aws_security_group_rule" "access_radis_from_ecs_sg_inbound_rule" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = module.ecs_sg.sg_id
  security_group_id        = module.redis_sg.sg_id
}
resource "aws_security_group_rule" "redis_sg_outbound_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.redis_sg.sg_id
}