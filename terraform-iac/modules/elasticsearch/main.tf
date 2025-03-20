
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
resource "aws_security_group" "elasticsearch" {
  name_prefix = "elasticsearch-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9300
    to_port     = 9300
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "data_nodes" {
  name_prefix   = "${var.name}-es-data"
  image_id      = data.aws_ami.latest_ubuntu.id
  instance_type = var.data_node_instance_type
  key_name      = var.key_name

  block_device_mappings {
    device_name = "/dev/sdb" # The device name inside the instance
    ebs {
      volume_size           = 100 # Size in GB (Adjust as needed)
      volume_type           = "gp3"
      delete_on_termination = true # Set to false if you need persistent storage
      encrypted             = true
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.elasticsearch.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -ex
              sudo apt update -y
              sudo apt install -y openjdk-11-jdk amazon-cloudwatch-agent filebeat

              # Ensure EBS is mounted
              if [ -b /dev/sdb ]; then
                sudo mkfs -t ext4 /dev/sdb
                sudo mkdir -p /var/lib/elasticsearch
                sudo mount /dev/sdb /var/lib/elasticsearch
                echo "/dev/sdb /var/lib/elasticsearch ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
              fi

              # Configure CloudWatch Agent
              cat <<EOT > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
              {
                "agent": {
                  "metrics_collection_interval": 60,
                  "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
                },
                "metrics": {
                  "namespace": "Elasticsearch",
                  "metrics_collected": {
                    "disk": {
                      "measurement": ["used_percent"],
                      "resources": ["*"],
                      "ignore_file_system_types": ["sysfs", "tmpfs"]
                    },
                    "mem": {
                      "measurement": ["mem_used_percent"]
                    },
                    "cpu": {
                      "measurement": ["cpu_usage_idle"],
                      "totalcpu": true
                    }
                  }
                }
              }
              EOT
              sudo systemctl enable amazon-cloudwatch-agent
              sudo systemctl start amazon-cloudwatch-agent

              # Configure Filebeat for Elasticsearch logs
              sudo tee /etc/filebeat/filebeat.yml > /dev/null <<EOL
              filebeat.inputs:
                - type: log
                  paths:
                    - /var/log/elasticsearch/*.log
              output.logstash:
                hosts: ["logstash-endpoint"]
              EOL
              sudo systemctl enable filebeat
              sudo systemctl start filebeat
              EOF
  )
}

# Auto Scaling Group
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
# resource "aws_ebs_volume" "data_node_volumes" {
#   count             = 4  # Number of data nodes
#   availability_zone = element(["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"], count.index)
#   size             = 100 # Adjust based on data storage needs (100GB)
#   type             = "gp3"
#   tags = {
#     Name = "elasticsearch-data-volume-${count.index}"
#   }
# }
# resource "aws_volume_attachment" "data_node_attachment" {
#   count       = 4
#   device_name = "/dev/sdb"
#   volume_id   = aws_ebs_volume.data_node_volumes[count.index].id
#   instance_id = data.aws_instances.data_node_instances.ids[count.index]
# }

# resource "aws_ebs_volume" "master_node_volumes" {
#   count             = 3  # Number of master nodes
#   availability_zone = element(["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"], count.index)
#   size             = 20 # Smaller volume (20GB) since it only stores cluster state
#   type             = "gp3"
#   tags = {
#     Name = "elasticsearch-master-volume-${count.index}"
#   }
# }
# # Fetch instances in the Auto Scaling Group for Data Nodes
# data "aws_instances" "data_node_instances" {
#   filter {
#     name   = "tag:aws:autoscaling:groupName"
#     values = [aws_autoscaling_group.data_nodes.name]
#   }
# }

# # Fetch instances in the Auto Scaling Group for Master Nodes
# data "aws_instances" "master_node_instances" {
#   filter {
#     name   = "tag:aws:autoscaling:groupName"
#     values = [aws_autoscaling_group.master_nodes.name]
#   }
# }

# resource "aws_volume_attachment" "master_node_attachment" {
#   count       = 3
#   device_name = "/dev/sdb"
#   volume_id   = aws_ebs_volume.master_node_volumes[count.index].id
#   instance_id = data.aws_instances.master_node_instances.ids[count.index]
# }

resource "aws_launch_template" "master_nodes" {
  name_prefix   = "${var.name}-es-master"
  image_id      = data.aws_ami.latest_ubuntu.id
  instance_type = var.master_node_instance_type
  key_name      = var.key_name

  block_device_mappings {
    device_name = "/dev/sdb" # The device name inside the instance
    ebs {
      volume_size           = 100 # Size in GB (Adjust as needed)
      volume_type           = "gp3"
      delete_on_termination = true # Set to false if you need persistent storage
      encrypted             = true
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.elasticsearch.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -ex
              sudo apt update -y
              sudo apt install -y openjdk-11-jdk

              # Ensure EBS is mounted
              if [ -b /dev/sdb ]; then
                sudo mkfs -t ext4 /dev/sdb
                sudo mkdir -p /var/lib/elasticsearch
                sudo mount /dev/sdb /var/lib/elasticsearch
                echo "/dev/sdb /var/lib/elasticsearch ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
              fi
              EOF
  ) # Ensures EBS is formatted and mounted on instance startup
}

resource "aws_autoscaling_group" "master_nodes" {
  desired_capacity     = 1  # Reduce this value
  max_size            = 3  # Adjust as needed
  min_size            = 1
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.master_nodes.id
    version = "$Latest"
  }
}
# Network Load Balancer
resource "aws_lb" "elasticsearch" {
  name               = var.elb_name
  internal           = false
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
