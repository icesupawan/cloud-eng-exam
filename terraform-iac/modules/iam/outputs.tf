output "iam_role_name" {
  value = aws_iam_role.app_role.name
}
output "iam_user_arn" {
  value = aws_iam_user.uploader.arn
}

output "iam_user_access_key_id" {
  value     = aws_iam_access_key.access_key.id
  sensitive = true
}

output "iam_user_secret_access_key" {
  value     = aws_iam_access_key.access_key.secret
  sensitive = true
}
output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}
