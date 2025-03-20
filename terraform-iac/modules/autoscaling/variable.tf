# variable "vpc_zone_identifier" {}
# variable "launch_template_id" {}

# Auto Scaling settings
# variable "min_size" {
#   default = 2
# }

# variable "max_size" {
#   default = 10
# }

# variable "desired_capacity" {
#   default = 3
# }
variable "cpu_scaling_is_enabled" {
  type = bool
}
variable "memory_scalingg_is_enabled" {
  type = bool
}
variable "max_capacity" {
}
variable "min_capacity" {
}
variable "ecs_cluster_name" {
}
variable "ecs_service_name" {
}
variable "cpu_target_value" {
}
variable "memory_target_value" {
}
variable "max_cpu_evaluation_period" {
  description = "The number of periods over which data is compared to the specified threshold for max cpu metric alarm"
  default     = "3"
  type        = string
}
variable "min_cpu_evaluation_period" {
  description = "The number of periods over which data is compared to the specified threshold for min cpu metric alarm"
  default     = "3"
  type        = string
}
variable "max_cpu_period" {
  description = "The period in seconds over which the specified statistic is applied for max cpu metric alarm"
  default     = "60"
  type        = string
}
variable "min_cpu_period" {
  description = "The period in seconds over which the specified statistic is applied for min cpu metric alarm"
  default     = "60"
  type        = string
}
variable "sns_topic_arn" {
  type        = string
  description = "The ARN of an SNS topic to send notifications on alarm actions."
  default     = ""
}
variable "min_cpu_threshold" {
  description = "Threshold for min CPU usage"
  default     = "10"
  type        = string
}
variable "cooldown" {
  description = "Cooldown period for scaling actions"
  type        = number
  default     = 60
}