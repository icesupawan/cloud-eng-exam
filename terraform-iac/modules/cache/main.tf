resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = var.redis_subnet_group_name
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = var.replication_group_id
  description                = var.replication_group_description
  node_type                  = var.node_type
  num_cache_clusters         = var.number_cache_clusters
  parameter_group_name       = var.parameter_group_name
  engine_version             = var.engine_version
  port                       = var.redis_port
  automatic_failover_enabled = var.automatic_failover_enabled #HA
  multi_az_enabled           = var.multi_az_enabled
  # num_node_groups            = 3 #The number of node groups (shards) on the global replication group.
  # replicas_per_node_group    = 2 #replica in each shard (1for primary other for secondary) 
  subnet_group_name          = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids         = var.security_group_id
  snapshot_retention_limit   = var.snapshot_retention_limit
  snapshot_window            = var.snapshot_window
  log_delivery_configuration {
    destination      = var.log_group_name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  log_delivery_configuration {
    destination      = var.log_group_name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }
  # apply_immediately = true
  lifecycle {
    ignore_changes = [num_cache_clusters]
  }
}

resource "aws_elasticache_cluster" "replica" {
  count                = var.number_cache_clusters - 1 
  cluster_id           = "tf-rep-group-${count.index + 1}"
  replication_group_id = aws_elasticache_replication_group.redis.id
}
