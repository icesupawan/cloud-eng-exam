variable "user_name" {
  description = "IAM User name for S3 uploads"
  type        = string
}

variable "bucket_name" {
  description = "Target S3 bucket for uploads"
  type        = string
}
variable "ecs_execution_role_name" { default = "ecsExecutionRole" }
variable "ecs_task_role_name" { default = "ecsTaskRole" }
