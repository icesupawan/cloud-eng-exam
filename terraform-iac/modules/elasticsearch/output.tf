# output "instance_ips" {
#   value = aws_instance.elasticsearch[*].public_ip
# }

data "aws_instances" "data_nodes" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.data_nodes.name]
  }
}

output "elasticsearch_data_nodes" {
  value = data.aws_instances.data_nodes.public_ips
}

data "aws_instances" "master_nodes" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.master_nodes.name]
  }
}

output "elasticsearch_master_nodes" {
  value = data.aws_instances.master_nodes.public_ips
}
output "sns_topic_arn" {
  value = aws_sns_topic.es_alerts.arn
}

output "launch_template_id" {
  value = aws_launch_template.data_nodes.id
}


