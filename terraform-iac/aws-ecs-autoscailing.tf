module "backend_autoscaling" {
  source = "./modules/autoscaling"
  max_capacity = 10
  min_capacity = 2
  cpu_scaling_is_enabled = true
  cpu_target_value = "80"
  memory_scalingg_is_enabled = true
  memory_target_value = "60"  
  ecs_cluster_name = ""
  ecs_service_name = ""
}
