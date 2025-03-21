
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu) official AMIs

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
resource "aws_launch_template" "data_nodes" {
  name_prefix   = "${var.name}-es-data"
  image_id      = data.aws_ami.latest_ubuntu.id
  instance_type = var.data_node_instance_type
  key_name      = var.key_name

  block_device_mappings {
    device_name = "/dev/sdb"
    ebs {
      volume_size           = 100
      volume_type           = "gp3"
      delete_on_termination = true 
      encrypted             = true
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -ex
              sudo apt update -y
              sudo apt install -y openjdk-11-jdk amazon-cloudwatch-agent filebeat

              if [ -b /dev/sdb ]; then
                sudo mkfs -t ext4 /dev/sdb
                sudo mkdir -p /var/lib/elasticsearch
                sudo mount /dev/sdb /var/lib/elasticsearch
                echo "/dev/sdb /var/lib/elasticsearch ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
              fi

              cat <<EOT > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
              {
                "metrics": {
                  "namespace": "Elasticsearch",
                  "metrics_collected": {
                    "disk": { "measurement": ["used_percent"], "resources": ["*"] },
                    "mem": { "measurement": ["mem_used_percent"] },
                    "cpu": { "measurement": ["cpu_usage_idle"], "totalcpu": true }
                  }
                }
              }
              EOT
              sudo systemctl enable amazon-cloudwatch-agent
              sudo systemctl start amazon-cloudwatch-agent
              EOF
  )
}

resource "aws_autoscaling_group" "data_nodes" {
  desired_capacity     = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.data_nodes.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "master_nodes" {
  name_prefix   = "${var.name}-es-master"
  image_id      = data.aws_ami.latest_ubuntu.id
  instance_type = var.master_node_instance_type
  key_name      = var.key_name

  block_device_mappings {
    device_name = "/dev/sdb" 
    ebs {
      volume_size           = 100 
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -ex
              sudo apt update -y
              sudo apt install -y openjdk-11-jdk amazon-cloudwatch-agent filebeat

              # Mount EBS สำหรับเก็บข้อมูล
              if [ -b /dev/sdb ]; then
                sudo mkfs -t ext4 /dev/sdb
                sudo mkdir -p /var/lib/elasticsearch
                sudo mount /dev/sdb /var/lib/elasticsearch
                echo "/dev/sdb /var/lib/elasticsearch ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
              fi

              # ติดตั้ง CloudWatch Agent
              cat <<EOT > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
              {
                "metrics": {
                  "namespace": "Elasticsearch",
                  "metrics_collected": {
                    "disk": { "measurement": ["used_percent"], "resources": ["*"] },
                    "mem": { "measurement": ["mem_used_percent"] },
                    "cpu": { "measurement": ["cpu_usage_idle"], "totalcpu": true }
                  }
                }
              }
              EOT
              sudo systemctl enable amazon-cloudwatch-agent
              sudo systemctl start amazon-cloudwatch-agent
              EOF
  )
}
resource "aws_autoscaling_group" "master_nodes" {
  desired_capacity     = var.master_node_desired
  max_size            = var.master_node_max
  min_size            = var.master_node_min
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.master_nodes.id
    version = "$Latest"
  }
}
# Network Load Balancer
resource "aws_lb" "elasticsearch" {
  name               = var.elb_name
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "es_tg" {
  name     = "es-target-group"
  port     = 9200
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "es_listener" {
  load_balancer_arn = aws_lb.elasticsearch.arn
  port              = 9200
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.es_tg.arn
  }
}
resource "aws_autoscaling_attachment" "es_tg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.data_nodes.id
  lb_target_group_arn    = aws_lb_target_group.es_tg.arn
}

resource "aws_sns_topic" "es_alerts" {
  name = "Elasticsearch-Alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.es_alerts.arn
  protocol  = "email"
  endpoint  = "iceicespw@gmail.com"
}
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "Elasticsearch-High-CPU"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "cpu_usage_idle"
  namespace           = "Elasticsearch"
  period              = 60
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "Triggers when CPU Utilization is too high"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.es_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "query_latency" {
  alarm_name          = "Elasticsearch-High-Query-Latency"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "QueryLatency"
  namespace           = "Elasticsearch"
  period              = 300
  statistic           = "Average"
  threshold           = 500
  alarm_description   = "Triggers when Query Latency exceeds 500ms"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.es_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "node_failure" {
  alarm_name          = "Elasticsearch-Node-Failure"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ClusterNodeCount"
  namespace           = "Elasticsearch"
  period              = 300
  statistic           = "Minimum"
  threshold           = 2
  alarm_description   = "Triggers when number of nodes in cluster is too low"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.es_alerts.arn]
}
resource "aws_lambda_function" "es_health_check" {
  function_name    = "ElasticsearchHealthCheck"
  runtime         = "python3.8"
  handler         = "lambda_function.lambda_handler"
  role            = aws_iam_role.lambda_exec.arn

  filename        = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
}