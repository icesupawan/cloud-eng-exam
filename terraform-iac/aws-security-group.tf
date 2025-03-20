# module "redis_sg" {
#   source = "./modules/security_group"
#   name = "redis_sg"
#   vpc_id = module.vpc.vpc_id
# }

# resource "aws_security_group_rule" "ecs_to_rds_inbound" {
#   type                     = "ingress"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   source_security_group_id = module.ecs_sg.sg_id  # Restrict to ECS only
#   security_group_id        = module.redis_sg.sg_id
# }

# resource "aws_security_group_rule" "redis_sg_outbound" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = module.redis_sg.sg_id
# }

# module "ecs_sg" {
#   source = "./modules/security_group"
#   name = "ecs_sg"
#   vpc_id = module.vpc.vpc_id
# }

# resource "aws_security_group_rule" "alb_to_ecs_inbound" {
#   type                     = "ingress"
#   from_port                = 3000
#   to_port                  = 3000
#   protocol                 = "tcp"
#   source_security_group_id = module.alb_sg.sg_id
#   security_group_id        = module.ecs_sg.sg_id
# }

# resource "aws_security_group_rule" "ecs_sg_outbound" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = module.ecs_sg.sg_id
# }

# module "alb_sg" {
#   source = "./modules/security_group"
#   name = "alb_sg"
#   vpc_id = module.vpc.vpc_id
# }

# resource "aws_security_group_rule" "ecs_to_redis" {
#   type                     = "ingress"
#   from_port                = 6379
#   to_port                  = 6379
#   protocol                 = "tcp"
#   source_security_group_id = module.ecs_sg.sg_id
#   security_group_id        = module.redis_sg.sg_id
# }
