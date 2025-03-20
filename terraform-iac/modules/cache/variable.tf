variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "redis_subnet_group_name" {
  description = "Name of the Redis subnet group"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for Redis"
  type        = list(string)
}

variable "redis_security_group_name" {
  description = "Name of the security group for Redis"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Redis will be deployed"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access Redis"
  type        = list(string)
}

variable "replication_group_id" {
  description = "Replication group ID for ElastiCache Redis"
  type        = string
}

variable "replication_group_description" {
  description = "Description of the replication group"
  type        = string
}

variable "node_type" {
  description = "Instance type for Redis nodes"
  type        = string
}

variable "number_cache_clusters" {
  description = "Number of cache nodes (1 for primary, more for replicas)"
  type        = number
}

variable "parameter_group_name" {
  description = "Parameter group name for Redis"
  type        = string
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
}

variable "redis_port" {
  description = "Port number for Redis"
  type        = number
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover for high availability"
  type        = bool
}

variable "multi_az_enabled" {
  description = "Enable multi-AZ deployment"
  type        = bool
}
# Backup settings
variable "snapshot_retention_limit" {
  default = 7
}

variable "snapshot_window" {
  default = "03:00-04:00"
}
variable "security_group_id" {
  type = list(string)
}
variable "log_group_name" {
  type = string
}