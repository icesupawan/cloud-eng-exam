output "cluster_id" {
  value = aws_ecs_cluster.ecs_cluster.id
}
output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}

output "ecs_service_name" {
  value = aws_ecs_service.ecs_service.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.ecs_task_definition.arn
}

output "service_arn" {
  value = aws_ecs_service.ecs_service.id
}