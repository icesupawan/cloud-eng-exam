# resource "aws_ecs_task_definition" "node_task" {
#   family                   = "node-app-task"
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   execution_role_arn       = aws_iam_role.ecs_execution_role.arn
#   task_role_arn            = aws_iam_role.ecs_task_role.arn
#   cpu                      = "512"
#   memory                   = "1024"

#   container_definitions = jsonencode([
#     {
#       name      = "node-app"
#       image     = "your-docker-image-url"
#       essential = true
#       portMappings = [{
#         containerPort = 3000
#         hostPort      = 3000
#       }]
#       environment = [
#         { name = "DATABASE_URL", value = "postgres://your-rds-endpoint:5432/your-db-name" },
#         { name = "REDIS_URL", value = "redis://your-redis-endpoint:6379" }
#       ],
#       secrets = [
#         {
#           name      = "DB_USERNAME"
#           valueFrom = aws_secretsmanager_secret.rds_credentials.arn
#         },
#         {
#           name      = "DB_PASSWORD"
#           valueFrom = aws_secretsmanager_secret.rds_credentials.arn
#         }
#       ]
#     }
#   ])
# }

