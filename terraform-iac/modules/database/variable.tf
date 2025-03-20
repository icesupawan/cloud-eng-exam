variable "db_identifier" {}
variable "engine" {}
variable "engine_version" {}
variable "instance_class" {}
variable "allocated_storage" {}
variable "max_allocated_storage" {}
variable "storage_encrypted" {}
variable "multi_az" {}
variable "publicly_accessible" {}
variable "db_subnet_group_name" {}
variable "vpc_security_group_ids" {}

variable "backup_retention_period" {
  default = 7
}

variable "backup_window" {
  default = "02:00-03:00"
}

variable "performance_insights_enabled" {
  default = true
}

variable "performance_insights_retention_period" {
  default = 7
}
