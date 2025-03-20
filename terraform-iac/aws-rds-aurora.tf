module "rds_aurora" {
  source = "./modules/rds-aurora"
  account_id = var.account_id
  engine_mode = "provisioned"
  cluster_identifier    = "${var.name}-postgres-db-instance"
  engine                = "aurora-postgresql"
  engine_version        = "14.6"
  instance_class        = "db.r6g.large"
  vpc_security_group_ids = [module.redis_sg.sg_id]
  # Backup settings
  backup_retention_period = 7
  security_group_id = module.rds_aurora_sg.sg_id
  subnet_ids = module.vpc.private_db_subnet_ids
}
module "rds_aurora_log_group" {
  source = "./modules/cloudwatch_loggroup"

  log_group_name    = "/aws/rds/cluster/instance-postgres-db-instance/postgresql"
  retention_in_days = 365
}
  module "rds_aurora_sg" {
  source = "./modules/security_groups"
  name = "rds_aurora_sg"
  vpc_id = module.vpc.vpc_id
}
resource "aws_security_group_rule" "access_db_from_backend_sg_inbound_rule" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.ecs_sg.sg_id
  security_group_id        = module.rds_aurora_sg.sg_id
}
resource "aws_security_group_rule" "access_db_from_redis_sg_inbound_rule" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.redis_sg.sg_id
  security_group_id        = module.rds_aurora_sg.sg_id
}
resource "aws_security_group_rule" "rds_aurora_sg_outbound_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.rds_aurora_sg.sg_id
}