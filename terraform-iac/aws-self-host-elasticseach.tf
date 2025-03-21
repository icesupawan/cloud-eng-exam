module "elasticsearch" {
  source         = "./modules/elasticsearch"
  vpc_id        = module.vpc.vpc_id
  subnet_ids     = module.vpc.public_subnet_ids
  data_node_instance_type = "r5.xlarge"
  master_node_instance_type = "m5.large"
  ami_id        = "ami-00ae2c3d8c3a99b5"
  instance_type = "t3.medium"
  key_name      = "es-keypair"
  name = var.name
  security_group_id = module.es_sg.sg_id
  desired_capacity = 3
  max_size = 6
  min_size = 2
  master_node_desired = 3
  master_node_max = 3
  master_node_min = 3
}
  module "es_sg" {
  source = "./modules/security_groups"
  name = "es_sg"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "access_alb_from_es_sg_inbound_rule" {
  type                     = "ingress"
  from_port                = 9200
  to_port                  = 9200
  protocol                 = "tcp"
  source_security_group_id = module.ecs_sg.sg_id
  security_group_id        = module.es_sg.sg_id
}
resource "aws_security_group_rule" "access_alb_from_es_sg_inbound_rule_2" {
  type                     = "ingress"
  from_port                = 9300
  to_port                  = 9300
  protocol                 = "tcp"
  source_security_group_id = module.ecs_sg.sg_id
  security_group_id        = module.es_sg.sg_id
}
resource "aws_security_group_rule" "access_alb_from_es_sg_inbound_rule_2" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = ["10.0.0.0/16"]
  security_group_id        = module.es_sg.sg_id
}
resource "aws_security_group_rule" "es_sg_outbound_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.es_sg.sg_id
}
