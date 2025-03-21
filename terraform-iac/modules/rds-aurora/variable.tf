variable "engine" {}
variable "engine_mode" {}
variable "engine_version" {}
variable "instance_class" {}

variable "cluster_identifier" {}
variable "account_id" {}
variable "vpc_security_group_ids" {}
variable "security_group_id" {}
variable "subnet_ids" {}
variable "backup_retention_period" {
  default = 7
}

variable "read_replica_count" {
  type = string
}