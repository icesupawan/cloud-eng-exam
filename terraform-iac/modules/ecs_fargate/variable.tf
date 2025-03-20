variable "aws_region" {}
variable "cluster_name" {}
variable "service_name" {}
variable "task_cpu" { default = 256 }
variable "task_memory" { default = 512 }
variable "execution_role_arn" {}
variable "task_role_arn" {}
variable "container_image" {}
variable "container_port" { default = 3000 }
variable "desired_count" { default = 2 }
variable "subnets" { type = list(string) }
variable "security_group" {}
variable "target_group_arn" {}
variable "min_capacity" { default = 2 }
variable "max_capacity" { default = 5 }
variable "cpu_target_value" { default = 50 }
variable "memory_target_value" { default = 50 }
variable "environment_variables" { type = list(object({ name = string, value = string })) }
variable "name" {}
variable "private_subnet_ids" {
  type = list(string)
}
variable "ecs_log_group_name" {}
variable "secrets" { type = list(object({ name = string, value = string })) }
