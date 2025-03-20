module "ecs_fargate" {
  source             = "./modules/ecs_fargate"
  aws_region         = var.aws_region
  cluster_name       = "${var.name}-ecs-cluster"
  service_name       = "${var.name}-nodejs-app"
  container_image    = "my-docker-repo/node-app:latest"
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  subnets            = module.network.public_subnets
  security_group     = module.network.ecs_security_group
  target_group_arn   = module.alb.target_group_arn
  desired_count      = 2
  min_capacity       = 2
  max_capacity       = 5
  cpu_target_value   = 50
  memory_target_value = 50
  secrets = [
    {
      name      = "DB_PASSWORD"
      valueFrom = "arn:aws:secretsmanager:ap-southeast-1:${var.account_id}:secret:secretiice:DB_PASSWORD::"
    }
  ]
  environment_variables = [
    { name = "NODE_ENV", value = "production" },
    { name = "PORT", value = "3000" },
    { name = "DATABASE_URL", value = "postgres://your-rds-endpoint:5432/your-db-name" },
    { name = "REDIS_URL", value = "redis://your-redis-endpoint:6379" },
    { name = "DB_USERNAME", value = "abcd" }
  ]
  private_subnet_ids = module.vpc.private_subnet_ids
  name = var.name
  ecs_log_group_name = module.ecs_log_group.log_group_name
}
  module "ecs_sg" {
  source = "./modules/security_groups"
  name = "ecs_sg"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "access_ecs_from_alb_sg_inbound_rule" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = module.alb_sg.sg_id
  security_group_id        = module.ecs_sg.sg_id
}
resource "aws_security_group_rule" "redis_sg_outbound_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.redis_sg.sg_id
}
  module "ecs_log_group" {
  source = "./modules/cloudwatch_loggroup"
  log_group_name = "/aws/ecs/${module.ecs_fargate.ecs_service_name}"
  retention_in_days = 7
}
resource "aws_iam_role" "task_role" {
  name               = "${module.ecs_fargate.ecs_service_name}-task-role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
    {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
    }
 ]
}
EOF
}

resource "aws_iam_policy" "task_role_policy" {
  name   = "${module.ecs_fargate.ecs_service_name}-TaskRole-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:PutObjectVersionAcl",
                "s3:PutObjectVersionTagging",
                "s3:PutBucketVersioning",
                "s3:PutObjectAcl"
            ],
            "Resource": "arn:aws:s3:::${var.name}-user-upload-bucket/*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_role_policy_attachment" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_policy.arn
}